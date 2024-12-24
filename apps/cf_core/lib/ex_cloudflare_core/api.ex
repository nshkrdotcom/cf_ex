defmodule ExCloudflareCore.API do
  @moduledoc """
  Handles all HTTP requests to Cloudflare API.
  """

  require Logger
  alias Jason
  # alias ExCloudflareCore.Config

  @spec request(String.t(), String.t(), String.t(), String.t(), map()) ::
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

  # @spec request_with_config(String.t(), Config.t(), String.t(), map()) ::
  #       {:ok, map()} | {:error, String.t()}
  # def request_with_config(method, config, path, body \\ %{}) do
  #       url = Config.endpoint(config, path)
  #       request(method, url, Config.headers(config), body)
  # end


  #   @spec request_with_session_config(String.t(), Config.t(), String.t(), map()) ::
  #       {:ok, map()} | {:error, String.t()}
  #  def request_with_session_config(method, config, path, body \\ %{}) do
  #        url = Config.session_endpoint(config, path)
  #        request(method, url, Config.headers(config), body)
  #  end

  #   @spec request_with_turn_key_config(String.t(), Config.t(), String.t(), map()) ::
  #       {:ok, map()} | {:error, String.t()}
  #   def request_with_turn_key_config(method, config, path, body \\ %{}) do
  #       url = Config.turn_key_endpoint(config, path)
  #       request(method, url, Config.headers(config), body)
  #   end

  #   @spec request_with_app_config(String.t(), Config.t(), String.t(), map()) ::
  #       {:ok, map()} | {:error, String.t()}
  #   def request_with_app_config(method, config, path, body \\ %{}) do
  #      url = Config.app_endpoint(config, path)
  #      request(method, url, Config.headers(config), body)
  #   end
end
