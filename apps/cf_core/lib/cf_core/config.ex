defmodule CfCore.Config do
  @moduledoc """
  Configuration management for Cloudflare API interactions.
  """
  def calls_api do
    Application.get_env(:cf_core, :calls_api) ||
      System.get_env("CALLS_API")
  end

  @doc """
  Gets the configured Cloudflare App ID.
  """
  def app_id do
    Application.get_env(:cf_core, :calls_app_id) ||
      System.get_env("CALLS_APP_ID")
  end

  @doc """
  Gets the configured Cloudflare App Secret.
  """
  def app_secret do
    Application.get_env(:cf_core, :calls_app_secret) ||
      System.get_env("CALLS_APP_SECRET")
  end

  @doc """
  Gets the base URL for Cloudflare Calls API.
  """
  def calls_base_url do
    "#{calls_api()}/v1/apps/#{app_id()}"
  end

  @doc """
  Gets the authorization headers for Cloudflare API requests.
  """
  def auth_headers do
    [{"Authorization", "Bearer #{app_secret()}"}, {"Content-Type", "application/json"}]
  end

  @doc """
  Constructs a full API endpoint URL.
  """
  @spec endpoint(String.t()) :: String.t()
  def endpoint(path) do
    "#{calls_base_url()}#{path}"
  end

  @doc """
  Constructs a full API endpoint URL for sessions.
  """
  @spec session_endpoint(String.t()) :: String.t()
  def session_endpoint(path) do
    "#{calls_base_url()}/sessions#{path}"
  end

  @doc """
  Constructs a full API endpoint URL for turn keys.
  """
  @spec turn_key_endpoint(String.t()) :: String.t()
  def turn_key_endpoint(path) do
    "#{calls_base_url()}/turn_keys#{path}"
  end

  @doc """
  Constructs a full API endpoint URL for apps.
  """
  @spec app_endpoint(String.t()) :: String.t()
  def app_endpoint(path) do
    "#{calls_base_url()}/apps#{path}"
  end

  @doc """
  Creates a new configuration struct.
  """
  @spec new(String.t(), String.t(), String.t()) :: __MODULE__.t()
  def new(base_url, app_id, app_token) do
    %__MODULE__{
      base_url: base_url,
      app_id: app_id,
      app_token: app_token
    }
  end

  @doc """
  Returns standard headers for API requests.
  """
  @spec headers(t()) :: list({String.t(), String.t()})
  def headers(%__MODULE__{app_token: app_token}) do
    [{~c"Authorization", "Bearer #{app_token}"}, {~c"Content-Type", ~c"application/json"}]
  end
end
