defmodule CfCalls.WhipWhep.Client do
  @moduledoc """
  Client implementation for WHIP (WebRTC-HTTP Ingestion Protocol) and
  WHEP (WebRTC-HTTP Egress Protocol).

  This module provides a clean interface for publishing (WHIP) and consuming (WHEP)
  WebRTC streams using Cloudflare Calls.
  """

  alias CfCalls.Session
  alias CfCalls.Track
  alias CfCalls.Types
  alias CfCalls.WhipWhep.Types, as: WhipWhepTypes
  alias CfCore.Config

  @type error :: {:error, String.t() | map()}

  @doc """
  Handles WHIP ingestion by creating a new session and tracks.

  ## Parameters
    * `config` - Cloudflare configuration
    * `live_id` - Unique identifier for the live stream
    * `offer_sdp` - SDP offer from the client
    * `opts` - Optional parameters for track creation

  Returns `{:ok, whip_response()}` on success.
  """
  @spec whip_ingest(Config.t(), String.t(), Types.sdp(), keyword()) ::
    {:ok, WhipWhepTypes.whip_response()} | error()
  def whip_ingest(config, live_id, offer_sdp, opts \\ []) do
    with {:ok, session_id} <- Session.new(config),
         {:ok, track_response} <- Track.create(config, session_id,
           session_description: %{type: "offer", sdp: offer_sdp},
           auto_discover: true
         ) do
      location = "/ingest/#{live_id}/#{session_id}"

      {:ok, %{
        sdp: track_response.sessionDescription.sdp,
        session_id: session_id,
        location: location,
        etag: ~s("#{session_id}")
      }}
    end
  end

  @doc """
  Handles WHEP playback by creating a new session and subscribing to tracks.

  ## Parameters
    * `config` - Cloudflare configuration
    * `live_id` - Unique identifier for the live stream
    * `offer_sdp` - SDP offer from the client (optional for WHEP)
    * `tracks` - List of tracks to subscribe to
    * `opts` - Optional parameters for track creation

  Returns `{:ok, whep_response()}` on success.
  """
  @spec whep_play(Config.t(), String.t(), Types.sdp() | nil, [Types.track_config()], keyword()) ::
    {:ok, WhipWhepTypes.whep_response()} | error()
  def whep_play(config, live_id, offer_sdp \\ nil, tracks, opts \\ []) do
    with {:ok, session_id} <- Session.new(config),
         {:ok, track_response} <- create_whep_tracks(config, session_id, offer_sdp, tracks) do
      location = "/play/#{live_id}/#{session_id}"

      {:ok, %{
        sdp: track_response.sessionDescription.sdp,
        session_id: session_id,
        location: location,
        etag: ~s("#{session_id}")
      }}
    end
  end

  @doc """
  Handles WHEP renegotiation with a new SDP answer.
  """
  @spec whep_renegotiate(Config.t(), Types.session_id(), Types.sdp()) ::
    :ok | error()
  def whep_renegotiate(config, session_id, answer_sdp) do
    case Session.renegotiate(config, session_id, %{
      type: "answer",
      sdp: answer_sdp
    }) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc """
  Handles WHIP/WHEP session termination.
  """
  @spec terminate(Config.t(), Types.session_id(), [Types.track_name()]) ::
    :ok | error()
  def terminate(config, session_id, track_names) do
    case Track.close(config, session_id, track_names) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  # Private Helpers

  defp create_whep_tracks(config, session_id, nil, tracks) do
    Track.create(config, session_id, tracks: tracks)
  end

  defp create_whep_tracks(config, session_id, offer_sdp, tracks) do
    Track.create(config, session_id,
      session_description: %{type: "offer", sdp: offer_sdp},
      tracks: tracks
    )
  end
end
