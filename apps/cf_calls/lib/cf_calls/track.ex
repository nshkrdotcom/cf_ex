defmodule CfCalls.Track do
  @moduledoc """
  Track operations for Cloudflare Calls API.

  Tracks are the core concept in Cloudflare Calls, representing audio, video, or data streams
  that can be published and subscribed to across sessions.
  """

  alias CfCore.API
  alias CfCore.Config
  alias CfCalls.Types

  @doc """
  Creates new tracks in a session.

  ## Options
    * `:auto_discover` - When true, automatically discovers tracks from SDP (default: true)
    * `:tracks` - List of track locators to add
    * `:session_description` - Optional SDP for WebRTC negotiation
  """
  @spec create(Config.t(), Types.session_id(), keyword()) ::
    {:ok, %{tracks: [Types.track_response()], session_description: Types.session_description()}} |
    {:error, term()}
  def create(config, session_id, opts \\ []) do
    body = %{}
    |> maybe_add_auto_discover(Keyword.get(opts, :auto_discover, true))
    |> maybe_add_tracks(Keyword.get(opts, :tracks))
    |> maybe_add_session_description(Keyword.get(opts, :session_description))

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
  Closes specific tracks in a session.
  """
  @spec close(Config.t(), Types.session_id(), [Types.track_name()]) ::
    {:ok, map()} | {:error, term()}
  def close(config, session_id, track_names) do
    API.request("PUT",
      "#{config.base_url}/#{config.app_id}/sessions/#{session_id}/tracks/close",
      [
        {"Authorization", "Bearer #{config.app_token}"},
        {"Content-Type", "application/json"}
      ],
      %{trackNames: track_names}
    )
  end

  # Private helpers

  defp maybe_add_auto_discover(body, auto_discover) do
    Map.put(body, :autoDiscover, auto_discover)
  end

  defp maybe_add_tracks(body, nil), do: body
  defp maybe_add_tracks(body, tracks), do: Map.put(body, :tracks, tracks)

  defp maybe_add_session_description(body, nil), do: body
  defp maybe_add_session_description(body, session_description) do
    Map.put(body, :sessionDescription, session_description)
  end
end
