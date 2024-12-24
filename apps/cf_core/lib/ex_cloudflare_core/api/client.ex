defmodule ExCloudflareCore.API.Client do
  @moduledoc """
  HTTP client for making requests to Cloudflare APIs.
  """

  alias ExCloudflareCore.Config

  @type response :: {:ok, map()} | {:error, term()}

  @doc """
  Makes a POST request to the Cloudflare API.
  """
  @spec post(String.t(), map() | String.t()) :: response()
  def post(endpoint, body) do
    url = Path.join(Config.calls_base_url(), endpoint)
    headers = Config.auth_headers() ++ [{"Content-Type", "application/json"}]
    
    body = if is_map(body), do: Jason.encode!(body), else: body

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: status, body: resp_body}} when status in 200..299 ->
        {:ok, Jason.decode!(resp_body)}
      
      {:ok, %{status_code: status, body: resp_body}} ->
        {:error, {status, resp_body}}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a PUT request to the Cloudflare API.
  """
  @spec put(String.t(), map()) :: response()
  def put(endpoint, body) do
    url = Path.join(Config.calls_base_url(), endpoint)
    headers = Config.auth_headers() ++ [{"Content-Type", "application/json"}]
    
    case HTTPoison.put(url, Jason.encode!(body), headers) do
      {:ok, %{status_code: status, body: resp_body}} when status in 200..299 ->
        {:ok, Jason.decode!(resp_body)}
      
      {:ok, %{status_code: status, body: resp_body}} ->
        {:error, {status, resp_body}}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Makes a DELETE request to the Cloudflare API.
  """
  @spec delete(String.t()) :: response()
  def delete(endpoint) do
    url = Path.join(Config.calls_base_url(), endpoint)
    headers = Config.auth_headers()
    
    case HTTPoison.delete(url, headers) do
      {:ok, %{status_code: status}} when status in 200..299 ->
        {:ok, nil}
      
      {:ok, %{status_code: status, body: resp_body}} ->
        {:error, {status, resp_body}}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
end
