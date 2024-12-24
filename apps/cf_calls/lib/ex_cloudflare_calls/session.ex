defmodule ExCloudflareCalls.Session do
  @moduledoc """
  Handles the creation and negotiation of Cloudflare Call Sessions
  """
  alias ExCloudflareCore.API
  alias ExCloudflareCore.Config
  require Logger

  @type session :: %{
    session_id: String.t()
  }

  @spec new_session(map(), list(map())) ::
    {:ok, session} | {:error, String.t()}
  def new_session(body, headers) do
    API.request(:post, Config.session_endpoint("/new"), headers, body)
      |> case do
        {:ok, %{"sessionId" => session_id}} ->
          {:ok, %{session_id: session_id}}
        other ->
          other
        end
  end

  @spec new_tracks(map(), list(map()), keyword()) ::
    {:ok, map()} | {:error, String.t()}
  def new_tracks(body, headers, session_id: session_id) do
    API.request(:post, Config.session_endpoint("/#{session_id}/tracks/new"), headers, body)
  end

  @spec renegotiate(map(), list(map()), keyword()) ::
    {:ok, map()} | {:error, String.t()}
  def renegotiate(body, headers, session_id: session_id) do
    API.request(:put, Config.session_endpoint("/#{session_id}/renegotiate"), headers, body)
  end

  @spec close_track(map(), list(map()), keyword()) ::
    {:ok, map()} | {:error, String.t()}
  def close_track(body, headers, session_id: session_id) do
    API.request(:put, Config.session_endpoint("/#{session_id}/tracks/close"), headers, body)
  end
end
