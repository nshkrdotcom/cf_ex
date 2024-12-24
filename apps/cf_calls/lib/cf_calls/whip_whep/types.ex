defmodule CfCalls.WhipWhep.Types do
  @moduledoc """
  Types specific to WHIP (WebRTC-HTTP Ingestion Protocol) and
  WHEP (WebRTC-HTTP Egress Protocol) implementations.
  """

  alias CfCalls.Types

  @type whip_response :: %{
    sdp: Types.sdp(),
    session_id: Types.session_id(),
    location: String.t(),
    etag: String.t()
  }

  @type whep_response :: %{
    sdp: Types.sdp(),
    session_id: Types.session_id(),
    location: String.t(),
    etag: String.t()
  }

  @type http_headers :: %{
    required(:content_type) => String.t(),
    required(:protocol_version) => String.t(),
    optional(:etag) => String.t(),
    optional(:location) => String.t(),
    optional(:link) => String.t()
  }

  @whip_protocol_version "draft-ietf-wish-whip-06"
  @whep_protocol_version "draft-ietf-wish-whep-00"

  @doc """
  Returns the WHIP protocol version.
  """
  def whip_protocol_version, do: @whip_protocol_version

  @doc """
  Returns the WHEP protocol version.
  """
  def whep_protocol_version, do: @whep_protocol_version

  @doc """
  Builds WHIP response headers.
  """
  @spec whip_headers(String.t(), String.t(), String.t()) :: http_headers()
  def whip_headers(session_id, location, content_type \\ "application/sdp") do
    %{
      content_type: content_type,
      protocol_version: @whip_protocol_version,
      etag: ~s("#{session_id}"),
      location: location,
      link: "<stun:stun.cloudflare.com:3478>; rel=\"ice-server\""
    }
  end

  @doc """
  Builds WHEP response headers.
  """
  @spec whep_headers(String.t(), String.t(), String.t()) :: http_headers()
  def whep_headers(session_id, location, content_type \\ "application/sdp") do
    %{
      content_type: content_type,
      protocol_version: @whep_protocol_version,
      etag: ~s("#{session_id}"),
      location: location,
      link: "<stun:stun.cloudflare.com:3478>; rel=\"ice-server\""
    }
  end

  @doc """
  Validates WHIP/WHEP content type.
  """
  @spec valid_content_type?(String.t()) :: boolean()
  def valid_content_type?(content_type) do
    content_type == "application/sdp"
  end
end
