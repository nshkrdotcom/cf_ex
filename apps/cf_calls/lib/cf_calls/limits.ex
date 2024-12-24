defmodule CfCalls.Limits do
  @moduledoc """
  Cloudflare Calls API limits and quotas.
  """

  # API Rate Limits
  @api_calls_per_second 50  # per session
  @tracks_per_call 64       # max tracks per API call
  
  # Timeouts
  @track_timeout 30         # seconds before track garbage collection
  @peer_conn_timeout 5      # seconds to wait for PeerConnection state

  # Free Tier
  @free_egress_gb 1000     # GB/month from Cloudflare to client

  def api_calls_per_second, do: @api_calls_per_second
  def tracks_per_call, do: @tracks_per_call
  def track_timeout, do: @track_timeout
  def peer_conn_timeout, do: @peer_conn_timeout
  def free_egress_gb, do: @free_egress_gb

  @doc """
  Validates track count against API limit.
  """
  def validate_track_count(count) when is_integer(count) do
    if count <= @tracks_per_call do
      :ok
    else
      {:error, "Exceeds maximum tracks per call (#{@tracks_per_call})"}
    end
  end
end
