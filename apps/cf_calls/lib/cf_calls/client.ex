defmodule CfCalls.Client do
  @moduledoc """
  Client for Cloudflare Calls API endpoints.
  Handles server-side API calls only. WebRTC/SDP/ICE are handled client-side.

  Usage:
    config = CfCalls.Config.new("app_id", "token")
    {:ok, session} = CfCalls.Client.new_session(config)
  """

  alias CfCalls.Types

  @base_url "https://rtc.live.cloudflare.com/v1/apps"

  @doc """
  Creates a new session.
  Returns session ID and details.
  """
  @spec new_session(map()) :: {:ok, Types.session_response()} | {:error, Types.error_response()}
  def new_session(config) do
    request(:post, "#{config.app_id}/sessions/new", config)
  end

  @doc """
  Creates new tracks in a session.
  Requires session_id and SDP offer in body.
  """
  @spec create_tracks(map(), String.t(), map()) :: {:ok, Types.tracks_response()} | {:error, Types.error_response()}
  def create_tracks(config, session_id, body) do
    request(:post, "#{config.app_id}/sessions/#{session_id}/tracks/new", config, body)
  end

  @doc """
  Renegotiates a session.
  Used when adding/removing tracks.
  """
  @spec renegotiate_session(map(), String.t(), map()) :: {:ok, Types.session_response()} | {:error, Types.error_response()}
  def renegotiate_session(config, session_id, body) do
    request(:put, "#{config.app_id}/sessions/#{session_id}/renegotiate", config, body)
  end

  @doc """
  Closes tracks in a session.
  """
  @spec close_tracks(map(), String.t(), map()) :: {:ok, Types.session_response()} | {:error, Types.error_response()}
  def close_tracks(config, session_id, body) do
    request(:put, "#{config.app_id}/sessions/#{session_id}/tracks/close", config, body)
  end

  @doc """
  Gets session information.
  """
  @spec get_session(map(), String.t()) :: {:ok, Types.session_response()} | {:error, Types.error_response()}
  def get_session(config, session_id) do
    request(:get, "#{config.app_id}/sessions/#{session_id}", config)
  end

  defp request(method, path, config, body \\ nil) do
    url = "#{@base_url}/#{path}"
    headers = [
      {"Authorization", "Bearer #{config.app_token}"},
      {"Content-Type", "application/json"}
    ]

    req_body = if body, do: Jason.encode!(body), else: ""

    case HTTPoison.request(method, url, req_body, headers) do
      {:ok, %{status_code: status, body: resp_body}} when status in 200..299 ->
        {:ok, Jason.decode!(resp_body)}
      
      {:ok, %{status_code: status, body: resp_body}} ->
        {:error, %{
          status_code: status,
          error: "API request failed",
          details: Jason.decode!(resp_body)
        }}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{
          error: "HTTP request failed",
          reason: reason
        }}
    end
  end
end
