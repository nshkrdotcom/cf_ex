defmodule ExCloudflareCalls.WhipWhep.Store do
  @moduledoc """
  Manages track storage for WHIP/WHEP sessions using Cloudflare Durable Objects.
  """

  alias ExCloudflareDurable.Object
  alias ExCloudflareDurable.Storage

  @type track_locator :: %{
    location: String.t(),
    session_id: String.t(),
    track_name: String.t()
  }

  @doc """
  Sets tracks for a specific live stream ID.
  """
  @spec set_tracks(String.t(), [track_locator()]) :: :ok | {:error, term()}
  def set_tracks(live_id, tracks) do
    with {:ok, object} <- Object.get_namespace("LIVE_STORE", live_id) do
      Storage.put(object, "tracks", tracks)
    end
  end

  @doc """
  Gets tracks for a specific live stream ID.
  """
  @spec get_tracks(String.t()) :: {:ok, [track_locator()]} | {:error, term()}
  def get_tracks(live_id) do
    with {:ok, object} <- Object.get_namespace("LIVE_STORE", live_id),
         {:ok, tracks} <- Storage.get(object, "tracks") do
      {:ok, tracks || []}
    end
  end

  @doc """
  Deletes tracks for a specific live stream ID.
  """
  @spec delete_tracks(String.t()) :: :ok | {:error, term()}
  def delete_tracks(live_id) do
    with {:ok, object} <- Object.get_namespace("LIVE_STORE", live_id) do
      Storage.delete(object, "tracks")
    end
  end
end
