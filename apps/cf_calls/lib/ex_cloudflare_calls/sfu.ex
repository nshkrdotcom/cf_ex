defmodule ExCloudflareCalls.SFU do
  @moduledoc """
  Manages Application interactions.
  """
  alias ExCloudflareCore.API
  alias ExCloudflareCore.Config
  require Logger

  @spec create_app(map(), list(map())) ::
      {:ok, map()} | {:error, String.t()}
  def create_app(body, headers) do
    API.request(:post, Config.app_endpoint(""), headers, body)
  end

   @spec get_app(map(), list(map())) ::
     {:ok, map()} | {:error, String.t()}
  def get_app(body, headers) do
    API.request(:get, Config.app_endpoint(""), headers, body)
  end

  @spec delete_app(map(), list(map()), keyword) ::
    {:ok, map()} | {:error, String.t()}
  def delete_app(body, headers, app_id: app_id) do
    API.request(:delete, Config.app_endpoint("/#{app_id}"), headers, body)
  end

  @spec edit_app(map(), list(map()), keyword) ::
    {:ok, map()} | {:error, String.t()}
  def edit_app(body, headers, app_id: app_id) do
    API.request(:put, Config.app_endpoint("/#{app_id}"), headers, body)
  end

  @spec list_apps(map(), list(map())) ::
    {:ok, map()} | {:error, String.t()}
  def list_apps(body, headers) do
    API.request(:get, Config.app_endpoint(""), headers, body)
  end
end
