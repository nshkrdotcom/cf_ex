defmodule CfCalls.Negotiation do
  @moduledoc """
  Utilities for handling Session Description Protocol (SDP) negotiation in WebRTC.

  This module provides functions for:
  - Parsing and validating SDP messages
  - Handling offer/answer exchanges
  - Managing media descriptions (m-lines)
  - ICE candidate integration
  """

  alias CfCalls.Types

  @type sdp_type :: "offer" | "answer" | "pranswer" | "rollback"
  @type media_type :: "audio" | "video" | "application"
  @type direction :: "sendonly" | "recvonly" | "sendrecv" | "inactive"

  @doc """
  Validates an SDP string for correct format and required fields.
  """
  @spec validate_sdp(Types.sdp()) :: :ok | {:error, String.t()}
  def validate_sdp(sdp) when is_binary(sdp) do
    cond do
      not String.contains?(sdp, "v=0") ->
        {:error, "Missing version (v=) line"}
      not String.contains?(sdp, "o=") ->
        {:error, "Missing origin (o=) line"}
      not String.contains?(sdp, "s=") ->
        {:error, "Missing session name (s=) line"}
      not String.contains?(sdp, "t=") ->
        {:error, "Missing timing (t=) line"}
      not String.contains?(sdp, "m=") ->
        {:error, "Missing media (m=) description"}
      true ->
        :ok
    end
  end

  def validate_sdp(_), do: {:error, "SDP must be a string"}

  @doc """
  Extracts media sections from an SDP string.
  Returns a list of media descriptions with their attributes.
  """
  @spec extract_media_sections(Types.sdp()) ::
    {:ok, [{media_type(), direction(), map()}]} | {:error, String.t()}
  def extract_media_sections(sdp) when is_binary(sdp) do
    with :ok <- validate_sdp(sdp) do
      media_sections = sdp
      |> String.split("m=")
      |> Enum.drop(1)  # First element is session-level attributes
      |> Enum.map(&parse_media_section/1)
      |> Enum.reject(&is_nil/1)

      {:ok, media_sections}
    end
  end

  def extract_media_sections(_), do: {:error, "Invalid SDP format"}

  @doc """
  Creates an SDP answer based on a received offer and local capabilities.
  """
  @spec create_answer(Types.sdp(), keyword()) :: {:ok, Types.sdp()} | {:error, String.t()}
  def create_answer(offer_sdp, opts \\ []) when is_binary(offer_sdp) do
    with :ok <- validate_sdp(offer_sdp),
         {:ok, media_sections} <- extract_media_sections(offer_sdp) do
      answer = build_sdp_answer(media_sections, opts)
      {:ok, answer}
    end
  end

  # Private Helpers

  defp parse_media_section(section) do
    lines = String.split(section, "\r\n")
    case parse_media_line(List.first(lines)) do
      {:ok, media_type} ->
        direction = find_direction(lines)
        attributes = parse_attributes(lines)
        {media_type, direction, attributes}
      _ ->
        nil
    end
  end

  defp parse_media_line(line) do
    case String.split(line, " ") do
      [type | _] when type in ["audio", "video", "application"] ->
        {:ok, type}
      _ ->
        {:error, "Invalid media type"}
    end
  end

  defp find_direction(lines) do
    cond do
      Enum.any?(lines, &String.contains?(&1, "a=sendonly")) -> "sendonly"
      Enum.any?(lines, &String.contains?(&1, "a=recvonly")) -> "recvonly"
      Enum.any?(lines, &String.contains?(&1, "a=sendrecv")) -> "sendrecv"
      Enum.any?(lines, &String.contains?(&1, "a=inactive")) -> "inactive"
      true -> "sendrecv"  # Default as per RFC
    end
  end

  defp parse_attributes(lines) do
    lines
    |> Enum.filter(&String.starts_with?(&1, "a="))
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        ["a=" <> key, value] ->
          Map.put(acc, key, String.trim(value))
        ["a=" <> key] ->
          Map.put(acc, key, true)
        _ -> acc
      end
    end)
  end

  defp build_sdp_answer(media_sections, opts) do
    session_id = System.system_time(:second)
    username = Keyword.get(opts, :username, "-")

    [
      "v=0",
      "o=#{username} #{session_id} #{session_id} IN IP4 0.0.0.0",
      "s=-",
      "t=0 0"
    ]
    |> Kernel.++(build_media_sections(media_sections, opts))
    |> Enum.join("\r\n")
    |> Kernel.<>("\r\n")
  end

  defp build_media_sections(media_sections, opts) do
    Enum.flat_map(media_sections, fn {media_type, direction, attrs} ->
      build_media_section(media_type, direction, attrs, opts)
    end)
  end

  defp build_media_section(type, direction, attrs, _opts) do
    [
      "m=#{type} 9 UDP/TLS/RTP/SAVPF 0",  # Simplified for example
      "c=IN IP4 0.0.0.0",
      "a=rtcp:9 IN IP4 0.0.0.0",
      "a=ice-ufrag:#{generate_ice_ufrag()}",
      "a=ice-pwd:#{generate_ice_pwd()}",
      "a=fingerprint:sha-256 #{generate_fingerprint()}",
      "a=setup:active",
      "a=#{direction}",
      "a=mid:0",
      "a=rtcp-mux"
    ] ++ build_codec_attributes(type, attrs)
  end

  defp build_codec_attributes("audio", _attrs) do
    ["a=rtpmap:0 PCMU/8000"]
  end

  defp build_codec_attributes("video", _attrs) do
    ["a=rtpmap:96 VP8/90000"]
  end

  defp build_codec_attributes(_, _), do: []

  defp generate_ice_ufrag, do: :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  defp generate_ice_pwd, do: :crypto.strong_rand_bytes(24) |> Base.encode16(case: :lower)
  defp generate_fingerprint, do: :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
end
