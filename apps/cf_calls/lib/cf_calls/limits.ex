defmodule CfCalls.Limits do
  @moduledoc """
  Cloudflare Calls API limits.
  These are enforced by Cloudflare, documented here for reference.
  """

  # max tracks per API call
  @tracks_per_call 64

  @doc """
  Pure function to validate track count.
  """
  def validate_track_count(count) when is_integer(count) do
    if count <= @tracks_per_call,
      do: :ok,
      else: {:error, "Maximum #{@tracks_per_call} tracks per call"}
  end
end
