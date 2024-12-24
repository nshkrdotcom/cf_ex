defmodule ExCloudflareCore do
  @moduledoc """
  A low-level Elixir package providing core abstractions for HTTP requests and SDP utilities
  """
  defmodule API do
    @moduledoc """
      Handles all HTTP requests to Cloudflare API.
      """

    require Logger
    alias Jason

    @spec request(String.t(), String.t(), list({String.t(), String.t()}), map()) ::
            {:ok, map()} | {:error, String.t()}
    def request(method, url, headers, body \\ %{}) do
        with {:ok, response} <-
            HttpPoison.request(
                method,
                url,
                headers,
                Jason.encode!(body),
                %{}
                )
        do
            case response.status_code do
                200..299 ->
                    case Jason.decode(response.body) do
                    {:ok, json} ->
                        {:ok, json}
                    {:error, reason} ->
                        Logger.error("JSON Decoding error: #{reason} for response:\n #{response.body}")
                        {:error, "JSON Decoding Error"}
                    end
                _ ->
                    Logger.error("Http request to #{url} failed with status: #{response.status_code} and body: #{response.body}")
                    {:error, "Http Request failed"}
            end
        end
        |> handle_response()
        end

    defp handle_response({:ok, result}), do: {:ok, result}
    defp handle_response({:error, reason}), do: {:error, reason}
  end

    defmodule SDP do
    @moduledoc """
    Provides helper functions for working with SDP (Session Description Protocol).
    """
    @spec generate_sdp(String.t(), keyword) :: String.t()
    def generate_sdp(sdp, opts \\ []) do
        sdp
        |> String.replace("useinbandfec=1", "usedtx=1;useinbandfec=1")
    end
    end
end
