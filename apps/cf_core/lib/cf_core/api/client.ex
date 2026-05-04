defmodule CfCore.API.Client do
  @moduledoc """
  HTTP client for making requests to Cloudflare APIs.
  """

  alias CfCore.Config

  @type response :: {:ok, map()} | {:error, term()}

  @doc """
  Makes a POST request to the Cloudflare API.
  """
  @spec post(String.t(), map() | String.t()) :: response()
  def post(endpoint, body) do
    post(Config.standalone(), endpoint, body)
  end

  @spec post(Config.t(), String.t(), map() | String.t()) :: response()
  def post(config, endpoint, body) do
    with :ok <- Config.validate_governed(config) do
      url = Path.join(config.base_url || Config.calls_base_url(), endpoint)
      headers = Config.headers(config) ++ [{"Content-Type", "application/json"}]

      body = if is_map(body), do: Jason.encode!(body), else: body

      case HTTPoison.post(url, body, headers) do
        {:ok, %{status_code: status, body: resp_body}} when status in 200..299 ->
          {:ok, Jason.decode!(resp_body)}

        {:ok, %{status_code: status, body: resp_body}} ->
          {:error, {status, CfCore.Redaction.redact(resp_body, config.redaction_values)}}

        {:error, reason} ->
          {:error, CfCore.Redaction.redact(reason, config.redaction_values)}
      end
    end
  end

  @doc """
  Makes a PUT request to the Cloudflare API.
  """
  @spec put(String.t(), map()) :: response()
  def put(endpoint, body) do
    put(Config.standalone(), endpoint, body)
  end

  @spec put(Config.t(), String.t(), map()) :: response()
  def put(config, endpoint, body) do
    with :ok <- Config.validate_governed(config) do
      url = Path.join(config.base_url || Config.calls_base_url(), endpoint)
      headers = Config.headers(config) ++ [{"Content-Type", "application/json"}]

      case HTTPoison.put(url, Jason.encode!(body), headers) do
        {:ok, %{status_code: status, body: resp_body}} when status in 200..299 ->
          {:ok, Jason.decode!(resp_body)}

        {:ok, %{status_code: status, body: resp_body}} ->
          {:error, {status, CfCore.Redaction.redact(resp_body, config.redaction_values)}}

        {:error, reason} ->
          {:error, CfCore.Redaction.redact(reason, config.redaction_values)}
      end
    end
  end

  @doc """
  Makes a DELETE request to the Cloudflare API.
  """
  @spec delete(String.t()) :: response()
  def delete(endpoint) do
    delete(Config.standalone(), endpoint)
  end

  @spec delete(Config.t(), String.t()) :: response()
  def delete(config, endpoint) do
    with :ok <- Config.validate_governed(config) do
      url = Path.join(config.base_url || Config.calls_base_url(), endpoint)
      headers = Config.headers(config)

      case HTTPoison.delete(url, headers) do
        {:ok, %{status_code: status}} when status in 200..299 ->
          {:ok, nil}

        {:ok, %{status_code: status, body: resp_body}} ->
          {:error, {status, CfCore.Redaction.redact(resp_body, config.redaction_values)}}

        {:error, reason} ->
          {:error, CfCore.Redaction.redact(reason, config.redaction_values)}
      end
    end
  end
end
