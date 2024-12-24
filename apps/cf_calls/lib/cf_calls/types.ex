defmodule CfCalls.Types do
  @moduledoc """
  Types for Cloudflare Calls API responses.
  Note: WebRTC/SDP/ICE handling happens client-side.
  """

  @type session_description :: %{
    sdp: String.t(),
    type: String.t()
  }

  @type session_response :: %{
    session_id: String.t(),
    created: String.t(),
    modified: String.t(),
    status: String.t()
  }

  @type track :: %{
    track_id: String.t(),
    session_id: String.t(),
    created: String.t(),
    modified: String.t(),
    status: String.t(),
    media_type: String.t()
  }

  @type tracks_response :: %{
    tracks: [track()],
    session_description: session_description()
  }

  @type turn_key :: %{
    key_id: String.t(),
    created: String.t(),
    modified: String.t(),
    name: String.t(),
    status: String.t()
  }

  @type error_response :: %{
    code: integer(),
    message: String.t()
  }
end
