defmodule ExCloudflareCore.API.Calls do
  @moduledoc """
  API client for Cloudflare Calls service.
  """

  alias ExCloudflareCore.API.Client

  @type session_description :: %{
    type: String.t(),
    sdp: String.t()
  }

  @type track :: %{
    track_name: String.t(),
    mid: String.t()
  }

  @doc """
  Creates a new session.
  """
  @spec create_session() :: {:ok, %{session_id: String.t()}} | {:error, term()}
  def create_session do
    Client.post("sessions/new", %{})
  end

  @doc """
  Creates new tracks in a session.
  """
  @spec create_tracks(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def create_tracks(session_id, params) do
    Client.post("sessions/#{session_id}/tracks/new", params)
  end

  @doc """
  Renegotiates a session with new SDP.
  """
  @spec renegotiate(String.t(), session_description()) :: {:ok, map()} | {:error, term()}
  def renegotiate(session_id, session_description) do
    Client.put("sessions/#{session_id}/renegotiate", %{
      session_description: session_description
    })
  end

  @doc """
  Updates tracks in a session.
  """
  @spec update_tracks(String.t(), [map()]) :: {:ok, map()} | {:error, term()}
  def update_tracks(session_id, tracks) do
    Client.put("sessions/#{session_id}/tracks", %{tracks: tracks})
  end

  @doc """
  Deletes a session.
  """
  @spec delete_session(String.t()) :: {:ok, nil} | {:error, term()}
  def delete_session(session_id) do
    Client.delete("sessions/#{session_id}")
  end
end
