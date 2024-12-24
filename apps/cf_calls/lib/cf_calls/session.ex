# defmodule CfCalls.Session do
#   @moduledoc """
#   Provides both stateless functions and optional GenServer behavior for managing Cloudflare Call sessions.
#   """
#   ## Usage

#   ### Stateless Usage

#   # Use directly without process
#   #{:ok, session} = CfCalls.Session.new(config)
#   #{:ok, response} = CfCalls.Session.create_track(session, track_params)
#   # Start supervised process
#   #{:ok, pid} = CfCalls.Session.start_link(config)
#   # Use through GenServer
#   #{:ok, response} = CfCalls.Session.create_track(pid, track_params)

#   alias CfCore.API
#   alias CfCore.Config
#   require Logger

#   @type session :: %{
#           session_id: String.t()
#         }

#   @spec new_session(map(), list(map())) ::
#           {:ok, session} | {:error, String.t()}
#   def new_session(config, opts \\ []) do
#     headers = Config.headers(config)
#     # Use Config to build URLs
#     endpoint = Config.endpoint("/sessions/new")

#     # Make the API call directly
#     with {:ok, response} <- API.request(:post, endpoint, headers, %{}),
#          {:ok, body} <- Jason.decode(response.body),
#          %{"sessionId" => session_id} <- body do
#       {:ok, %{session_id: session_id}}
#     end
#   end

#   @spec new_tracks(String.t(), map()) :: {:ok, map()} | {:error, term()}
#   def new_tracks(session_id, params) do
#     # Or however your auth headers are managed
#     headers = Config.auth_headers()
#     endpoint = Config.session_endpoint("/#{session_id}/tracks/new")
#     API.request(:post, endpoint, headers, params)
#   end

#   @spec renegotiate(String.t(), map()) :: {:ok, map()} | {:error, term()}
#   def renegotiate(session_id, params) do
#     # Or however your auth headers are managed
#     headers = Config.auth_headers()
#     endpoint = Config.session_endpoint("/#{session_id}/renegotiate")
#     API.request(:post, endpoint, headers, params)
#   end

#   @spec close_track(String.t(), map()) :: {:ok, map()} | {:error, term()}
#   def close_track(session_id, params) do
#     # Or however your auth headers are managed
#     headers = Config.auth_headers()
#     endpoint = Config.session_endpoint("/#{session_id}/tracks/close")
#     API.request(:post, endpoint, headers, params)
#   end
# end

defmodule CfCalls.Session do
  @moduledoc """
  Client interface for Cloudflare Calls sessions, specifically designed for WHIP/WHEP interactions.

  This module provides functions to interact with Cloudflare's Calls API endpoints,
  handling session creation, track management, and SDP negotiations.
  """

  alias CfCore.API
  alias CfCore.Config

  @type session_id :: String.t()
  @type sdp :: String.t()
  @type track_name :: String.t()

  @type session_description :: %{
    type: String.t(),
    sdp: sdp()
  }

  @type track_response :: %{
    track_name: track_name(),
    mid: String.t(),
    optional(:error_code) => String.t(),
    optional(:error_description) => String.t()
  }

  @doc """
  Creates a new Cloudflare Calls session.

  Returns `{:ok, session_id}` on success.
  """
  @spec new(Config.t()) :: {:ok, session_id()} | {:error, term()}
  def new(config) do
    API.request("POST",
      "#{config.base_url}/#{config.app_id}/sessions/new",
      [
        {"Authorization", "Bearer #{config.app_token}"},
        {"Content-Type", "application/json"}
      ]
    )
    |> case do
      {:ok, %{"sessionId" => session_id}} -> {:ok, session_id}
      error -> error
    end
  end

  @doc """
  Creates new tracks in a session with optional SDP offer.

  ## Options
    * `:auto_discover` - When true, automatically discovers tracks from SDP
    * `:tracks` - List of track locators to add
  """
  @spec create_tracks(Config.t(), session_id(), session_description(), keyword()) ::
    {:ok, %{tracks: [track_response()], session_description: session_description()}} |
    {:error, term()}
  def create_tracks(config, session_id, session_description, opts \\ []) do
    body = %{
      sessionDescription: session_description,
      autoDiscover: Keyword.get(opts, :auto_discover, true)
    }
    |> maybe_add_tracks(Keyword.get(opts, :tracks))

    API.request("POST",
      "#{config.base_url}/#{config.app_id}/sessions/#{session_id}/tracks/new",
      [
        {"Authorization", "Bearer #{config.app_token}"},
        {"Content-Type", "application/json"}
      ],
      body
    )
  end

  @doc """
  Updates an existing session with a new SDP answer during renegotiation.
  """
  @spec renegotiate(Config.t(), session_id(), session_description()) ::
    {:ok, map()} | {:error, term()}
  def renegotiate(config, session_id, session_description) do
    API.request("PUT",
      "#{config.base_url}/#{config.app_id}/sessions/#{session_id}/renegotiate",
      [
        {"Authorization", "Bearer #{config.app_token}"},
        {"Content-Type", "application/json"}
      ],
      %{sessionDescription: session_description}
    )
  end

  defp maybe_add_tracks(body, nil), do: body
  defp maybe_add_tracks(body, tracks), do: Map.put(body, :tracks, tracks)
end
