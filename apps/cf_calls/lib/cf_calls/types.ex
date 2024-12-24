defmodule CfCalls.Types do
  @moduledoc """
  Types for Cloudflare Calls API responses.
  Note: WebRTC/SDP/ICE handling happens client-side.
  
  For rate limits and quotas, see: https://developers.cloudflare.com/calls/limits/
  Rate limiting should be implemented at the application level, not in this library.
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

  @type datachannel_publisher :: %{
    location: :local,
    datachannel_name: String.t()
  }

  @type datachannel_subscriber :: %{
    location: :remote,
    datachannel_name: String.t(),
    session_id: String.t()  # Publisher's session ID
  }

  @type datachannel :: %{
    id: integer(),
    datachannel_name: String.t(),
    session_id: String.t()
  }

  @type datachannels_response :: %{
    datachannels: [datachannel()],
    session_description: session_description()
  }

  @type error_response :: %{
    code: integer(),
    message: String.t()
  }
end
