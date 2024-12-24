defmodule CfCalls.Types do
  @moduledoc """
  Shared types and structs for Cloudflare Calls operations.

  Note: This module should be in cf_calls/lib/cf_calls/types.ex rather than
  in the whip_whep directory since these types are used across the library.
  """

  @type session_id :: String.t()
  @type track_name :: String.t()
  @type sdp :: String.t()

  @type track_location :: :local | :remote

  @type track_config :: %{
    location: track_location(),
    optional(:session_id) => session_id(),
    optional(:track_name) => track_name()
  }

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

  @type new_tracks_response :: %{
    tracks: [track_response()],
    session_description: session_description()
  }

  @type error_response :: %{
    error: String.t(),
    error_description: String.t(),
    optional(:status_code) => integer()
  }

  # API Limits and Constants
  @doc """
  Maximum number of tracks that can be added in a single API call.
  """
  @tracks_per_call 64

  @doc """
  Maximum number of API calls per second per session.
  """
  @api_rate_limit 50

  @doc """
  Track inactivity timeout in seconds.
  After this period without media packets, tracks are garbage collected.
  """
  @track_timeout 30

  def tracks_per_call, do: @tracks_per_call
  def api_rate_limit, do: @api_rate_limit
  def track_timeout, do: @track_timeout
end
