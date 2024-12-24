defmodule CfCalls.Ice do
  @moduledoc """
  ICE (Interactive Connectivity Establishment) utilities for WebRTC.

  This module handles:
  - ICE candidate parsing and validation
  - STUN/TURN server configuration
  - Candidate priority calculation
  - Connectivity checks
  """

  alias CfCalls.Types

  @type candidate_type :: :host | :srflx | :prflx | :relay
  @type transport_type :: :udp | :tcp | :tls
  @type component_id :: 1 | 2  # 1 for RTP, 2 for RTCP

  @type candidate :: %{
    foundation: String.t(),
    component: component_id(),
    transport: transport_type(),
    priority: non_neg_integer(),
    ip: String.t(),
    port: 0..65535,
    type: candidate_type(),
    raddr: String.t() | nil,
    rport: 0..65535 | nil,
    generation: non_neg_integer()
  }

  @type ice_server :: %{
    urls: String.t() | [String.t()],
    username: String.t() | nil,
    credential: String.t() | nil,
    credentialType: String.t() | nil
  }

  @cloudflare_ice_servers [
    %{urls: "stun:stun.cloudflare.com:3478"},
    %{urls: [
      "turn:turn.cloudflare.com:3478?transport=udp",
      "turn:turn.cloudflare.com:3478?transport=tcp",
      "turns:turn.cloudflare.com:5349?transport=tcp"
    ]}
  ]

  @doc """
  Parses an ICE candidate string into a structured format.
  """
  @spec parse_candidate(String.t()) :: {:ok, candidate()} | {:error, String.t()}
  def parse_candidate("candidate:" <> rest) do
    parse_candidate(rest)
  end

  def parse_candidate(candidate_str) do
    parts = String.split(candidate_str)

    case parts do
      [foundation, component, transport, priority, ip, port, "typ", type | rest] ->
        parse_candidate_parts(foundation, component, transport, priority, ip, port, type, rest)
      _ ->
        {:error, "Invalid ICE candidate format"}
    end
  end

  @doc """
  Calculates the priority for an ICE candidate based on RFC 5245.
  """
  @spec calculate_priority(candidate_type(), component_id(), transport_type()) :: non_neg_integer()
  def calculate_priority(type, component_id, transport) do
    type_preference = get_type_preference(type)
    local_preference = get_local_preference(transport)

    (2**24) * type_preference +
    (2**8) * local_preference +
    (2**0) * (256 - component_id)
  end

  @doc """
  Returns the default Cloudflare ICE servers configuration.
  """
  @spec default_ice_servers() :: [ice_server()]
  def default_ice_servers, do: @cloudflare_ice_servers

  @doc """
  Validates ICE credentials (ufrag and pwd).
  """
  @spec validate_credentials(String.t(), String.t()) :: :ok | {:error, String.t()}
  def validate_credentials(ufrag, pwd) when is_binary(ufrag) and is_binary(pwd) do
    cond do
      byte_size(ufrag) < 4 ->
        {:error, "ICE ufrag must be at least 4 characters"}
      byte_size(ufrag) > 256 ->
        {:error, "ICE ufrag must not exceed 256 characters"}
      byte_size(pwd) < 22 ->
        {:error, "ICE password must be at least 22 characters"}
      byte_size(pwd) > 256 ->
        {:error, "ICE password must not exceed 256 characters"}
      true ->
        :ok
    end
  end

  def validate_credentials(_, _), do: {:error, "Invalid ICE credentials format"}

  @doc """
  Creates a trickle ICE candidate update message.
  """
  @spec create_trickle_candidate(candidate()) :: {:ok, String.t()} | {:error, String.t()}
  def create_trickle_candidate(candidate) do
    try do
      candidate_str = build_candidate_string(candidate)
      {:ok, candidate_str}
    rescue
      _ -> {:error, "Failed to create trickle candidate"}
    end
  end

  @doc """
  Validates ICE candidate IP address.
  """
  @spec validate_ip(String.t()) :: :ok | {:error, String.t()}
  def validate_ip(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, "Invalid IP address format"}
    end
  end

  @doc """
  Collects WebRTC statistics for ICE candidates.
  """
  @type stats_type :: :candidate_pair | :local_candidate | :remote_candidate
  @type webrtc_stats :: %{
    type: stats_type(),
    timestamp: integer(),
    id: String.t(),
    state: String.t(),
    nominated: boolean(),
    bytes_sent: non_neg_integer(),
    bytes_received: non_neg_integer(),
    total_round_trip_time: float(),
    current_round_trip_time: float(),
    available_outgoing_bitrate: float(),
    available_incoming_bitrate: float(),
    requests_received: non_neg_integer(),
    requests_sent: non_neg_integer(),
    responses_received: non_neg_integer(),
    responses_sent: non_neg_integer(),
    consent_requests_sent: non_neg_integer(),
    packets_discarded_on_send: non_neg_integer(),
    bytes_discarded_on_send: non_neg_integer()
  }

  @spec collect_stats(candidate()) :: {:ok, webrtc_stats()} | {:error, String.t()}
  def collect_stats(candidate) do
    # This would be implemented based on the WebRTC stats API
    # For now, we return a placeholder structure
    {:ok, %{
      type: :candidate_pair,
      timestamp: System.system_time(:millisecond),
      id: candidate.foundation,
      state: "succeeded",
      nominated: true,
      bytes_sent: 0,
      bytes_received: 0,
      total_round_trip_time: 0.0,
      current_round_trip_time: 0.0,
      available_outgoing_bitrate: 0.0,
      available_incoming_bitrate: 0.0,
      requests_received: 0,
      requests_sent: 0,
      responses_received: 0,
      responses_sent: 0,
      consent_requests_sent: 0,
      packets_discarded_on_send: 0,
      bytes_discarded_on_send: 0
    }}
  end


  # Private Helpers

  defp parse_candidate_parts(foundation, component, transport, priority, ip, port, type, rest) do
    with {:ok, component_id} <- parse_component(component),
         {:ok, transport_type} <- parse_transport(transport),
         {:ok, priority_int} <- parse_priority(priority),
         {:ok, port_int} <- parse_port(port),
         {:ok, candidate_type} <- parse_type(type),
         {:ok, raddr, rport} <- parse_relay_addr(rest) do

      {:ok, %{
        foundation: foundation,
        component: component_id,
        transport: transport_type,
        priority: priority_int,
        ip: ip,
        port: port_int,
        type: candidate_type,
        raddr: raddr,
        rport: rport,
        generation: 0
      }}
    end
  end

  defp parse_component(str) do
    case Integer.parse(str) do
      {n, ""} when n in [1, 2] -> {:ok, n}
      _ -> {:error, "Invalid component ID"}
    end
  end

  defp parse_transport("udp"), do: {:ok, :udp}
  defp parse_transport("tcp"), do: {:ok, :tcp}
  defp parse_transport("tls"), do: {:ok, :tls}
  defp parse_transport(_), do: {:error, "Invalid transport"}

  defp parse_priority(str) do
    case Integer.parse(str) do
      {n, ""} when n >= 0 -> {:ok, n}
      _ -> {:error, "Invalid priority"}
    end
  end

  defp parse_port(str) do
    case Integer.parse(str) do
      {n, ""} when n in 0..65535 -> {:ok, n}
      _ -> {:error, "Invalid port"}
    end
  end

  defp parse_type("host"), do: {:ok, :host}
  defp parse_type("srflx"), do: {:ok, :srflx}
  defp parse_type("prflx"), do: {:ok, :prflx}
  defp parse_type("relay"), do: {:ok, :relay}
  defp parse_type(_), do: {:error, "Invalid candidate type"}

  defp parse_relay_addr(["raddr", raddr, "rport", rport | _]) do
    case parse_port(rport) do
      {:ok, rport_int} -> {:ok, raddr, rport_int}
      error -> error
    end
  end
  defp parse_relay_addr(_), do: {:ok, nil, nil}

  defp get_type_preference(:host), do: 126
  defp get_type_preference(:prflx), do: 110
  defp get_type_preference(:srflx), do: 100
  defp get_type_preference(:relay), do: 0

  defp get_local_preference(:udp), do: 65535
  defp get_local_preference(:tcp), do: 65534
  defp get_local_preference(:tls), do: 65533

  defp build_candidate_string(%{
    foundation: foundation,
    component: component,
    transport: transport,
    priority: priority,
    ip: ip,
    port: port,
    type: type
  } = candidate) do
    base = "candidate:#{foundation} #{component} #{transport} #{priority} #{ip} #{port} typ #{type}"

    relay = case {candidate.raddr, candidate.rport} do
      {nil, nil} -> ""
      {raddr, rport} -> " raddr #{raddr} rport #{rport}"
    end

    base <> relay <> " generation #{candidate.generation}"
  end
end
