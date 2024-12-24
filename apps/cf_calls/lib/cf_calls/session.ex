defmodule CfCalls.Session do
  @moduledoc """
  Sessions for tracks
  """

  alias CfCore.API
  alias CfCore.Config
  require Logger

  @type session :: %{
    session_id: String.t()
  }

  @spec new_session(map(), list(map())) ::
    {:ok, session} | {:error, String.t()}
  def new_session(config, opts \\ []) do
    headers = Config.headers(config)
    endpoint = Config.endpoint("/sessions/new") # Use Config to build URLs

    with {:ok, response} <- API.request(:post, endpoint, headers, %{}), # Make the API call directly
    {:ok, body} <- Jason.decode(response.body),
    %{"sessionId" => session_id} <- body do
      {:ok, %{session_id: session_id}}
    end
  end

  @spec new_tracks(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def new_tracks(session_id, params) do
    headers = Config.auth_headers() # Or however your auth headers are managed
    endpoint = Config.session_endpoint("/#{session_id}/tracks/new")
    API.request(:post, endpoint, headers, params)
  end

  @spec renegotiate(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def renegotiate(session_id, params) do
    headers = Config.auth_headers() # Or however your auth headers are managed
    endpoint = Config.session_endpoint("/#{session_id}/renegotiate")
    API.request(:post, endpoint, headers, params)
  end
  @spec close_track(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def close_track(session_id, params) do
    headers = Config.auth_headers() # Or however your auth headers are managed
    endpoint = Config.session_endpoint("/#{session_id}/tracks/close")
    API.request(:post, endpoint, headers, params)
  end
end
