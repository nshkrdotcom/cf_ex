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

  defmodule Error do
    @moduledoc "Structured errors for API operations"
    defexception [:type, :message, :context]

    @type t :: %__MODULE__{
      type: :rate_limit | :http | :json | :network,
      message: String.t(),
      context: map()
    }

    def message(%{message: message, context: context}) do
      "#{message} (#{inspect(context)})"
    end
  end

  @spec request(String.t(), String.t(), map(), map(), keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def request(method, url, headers, body \\ %{}, opts \\ []) do
    start_time = System.monotonic_time()

    metadata = %{
      method: method,
      url: url,
      start_time: start_time
    }

    :telemetry.span(
      @telemetry_prefix ++ [:request],
      metadata,
      fn ->
        do_request(method, url, headers, body, opts, 0)
      end
    )
  end

  defp do_request(method, url, headers, body, opts, retry_count) when retry_count < @max_retries do
    encoded_body = Jason.encode!(body)

    with {:ok, response} <-
           HttpPoison.request(
             method,
             url,
             headers,
             encoded_body,
             [recv_timeout: 30_000, pool: :cf_api_pool] ++ opts
           ),
         {:ok, status, resp_body} <- handle_response(response) do
      {:ok, resp_body}
    else
      {:error, :rate_limit} ->
        backoff = calculate_backoff(retry_count)
        Process.sleep(backoff)
        do_request(method, url, headers, body, opts, retry_count + 1)

      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, %Error{
          type: :network,
          message: "Request failed",
          context: %{reason: reason}
        }}
    end
  end

  defp do_request(_method, _url, _headers, _body, _opts, retry_count) do
    {:error, %Error{
      type: :rate_limit,
      message: "Max retries exceeded",
      context: %{retries: retry_count}
    }}
  end

  defp handle_response(%{status_code: status, body: body} = response) do
    case status do
      200..299 ->
        case Jason.decode(body) do
          {:ok, json} -> {:ok, status, json}
          {:error, reason} ->
            Logger.error("JSON Decoding error", error: inspect(reason), body: body)
            {:error, %Error{
              type: :json,
              message: "JSON decoding failed",
              context: %{reason: reason}
            }}
        end

      429 ->
        Logger.warn("Rate limit hit", url: response.request_url)
        {:error, :rate_limit}

      _ ->
        Logger.error("HTTP error",
          status: status,
          body: body,
          url: response.request_url
        )

        {:error, %Error{
          type: :http,
          message: "HTTP request failed",
          context: %{
            status: status,
            body: body
          }
        }}
    end
  end

  defp calculate_backoff(retry_count) do
    @initial_backoff * :math.pow(2, retry_count)
    |> round()
    |> :rand.uniform()
  end
end
