defmodule CfCore.API do
  @moduledoc """
  Handles all HTTP requests to Cloudflare API with rate limiting, telemetry, and robust error handling.

  ## Features
  - Automatic rate limiting with exponential backoff
  - Telemetry events for monitoring and metrics
  - Detailed error context for debugging
  - Connection pooling via :hackney
  """

  require Logger
  alias Jason

  # Telemetry event prefix
  @telemetry_prefix [:cf_core, :api]

  # Rate limiting configuration
  @initial_backoff 100
  @max_retries 3
  @allowed_methods %{
    "DELETE" => :delete,
    "GET" => :get,
    "PATCH" => :patch,
    "POST" => :post,
    "PUT" => :put,
    :delete => :delete,
    :get => :get,
    :patch => :patch,
    :post => :post,
    :put => :put
  }

  defmodule Error do
    @moduledoc "Structured errors for API operations"
    defexception [:type, :message, :context]

    @type t :: %__MODULE__{
            type: :rate_limit | :http | :json | :method | :network,
            message: String.t(),
            context: map()
          }

    def message(%{message: message, context: context}) do
      "#{message} (#{inspect(context)})"
    end
  end

  @spec request(String.t() | atom(), String.t(), [{String.t(), String.t()}], map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def request(method, url, headers, body \\ %{}, opts \\ []) do
    with {:ok, method} <- normalize_method(method) do
      start_time = System.monotonic_time()
      {redaction_values, request_opts} = Keyword.pop(opts, :redaction_values, [])

      metadata = %{
        method: method,
        url: url,
        start_time: start_time
      }

      :telemetry.span(
        @telemetry_prefix ++ [:request],
        metadata,
        fn ->
          do_request(method, url, headers, body, request_opts, redaction_values, 0)
        end
      )
    end
  end

  defp normalize_method(method) when is_binary(method) do
    method
    |> String.upcase()
    |> fetch_method()
  end

  defp normalize_method(method) do
    fetch_method(method)
  end

  defp fetch_method(method) do
    case Map.fetch(@allowed_methods, method) do
      {:ok, method} ->
        {:ok, method}

      :error ->
        {:error,
         %Error{
           type: :method,
           message: "Unsupported HTTP method",
           context: %{method: method}
         }}
    end
  end

  defp do_request(method, url, headers, body, opts, redaction_values, retry_count)
       when retry_count < @max_retries do
    encoded_body = Jason.encode!(body)

    with {:ok, response} <-
           HTTPoison.request(
             method,
             url,
             headers,
             encoded_body,
             [recv_timeout: 30_000, pool: :cf_api_pool] ++ opts
           ),
         {:ok, _status, resp_body} <- handle_response(response, redaction_values) do
      {:ok, resp_body}
    else
      {:error, :rate_limit} ->
        backoff = calculate_backoff(retry_count)
        Process.sleep(backoff)
        do_request(method, url, headers, body, opts, redaction_values, retry_count + 1)

      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         %Error{
           type: :network,
           message: "Request failed",
           context: %{reason: CfCore.Redaction.redact(reason, redaction_values)}
         }}
    end
  end

  defp do_request(_method, _url, _headers, _body, _opts, _redaction_values, retry_count) do
    {:error,
     %Error{
       type: :rate_limit,
       message: "Max retries exceeded",
       context: %{retries: retry_count}
     }}
  end

  defp handle_response(%{status_code: status, body: body} = response, redaction_values) do
    case status do
      200..299 ->
        case Jason.decode(body) do
          {:ok, json} ->
            {:ok, status, json}

          {:error, reason} ->
            Logger.error("JSON Decoding error",
              error: inspect(CfCore.Redaction.redact(reason, redaction_values)),
              body: CfCore.Redaction.redact(body, redaction_values)
            )

            {:error,
             %Error{
               type: :json,
               message: "JSON decoding failed",
               context: %{reason: CfCore.Redaction.redact(reason, redaction_values)}
             }}
        end

      429 ->
        Logger.warning("Rate limit hit", url: response.request_url)
        {:error, :rate_limit}

      _ ->
        Logger.error("HTTP error",
          status: status,
          body: CfCore.Redaction.redact(body, redaction_values),
          url: response.request_url
        )

        {:error,
         %Error{
           type: :http,
           message: "HTTP request failed",
           context: %{
             status: status,
             body: CfCore.Redaction.redact(body, redaction_values)
           }
         }}
    end
  end

  defp calculate_backoff(retry_count) do
    (@initial_backoff * :math.pow(2, retry_count))
    |> round()
    |> :rand.uniform()
  end
end
