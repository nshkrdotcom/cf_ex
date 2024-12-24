defmodule ExCloudflareCalls.WhipWhep.Handler do
  @moduledoc """
  Handles WHIP (WebRTC-HTTP ingestion protocol) and WHEP (WebRTC-HTTP egress protocol) requests.
  """

  alias ExCloudflareCalls.WhipWhep.Store
  alias ExCloudflareCore.API.Calls

  @type session_description :: %{
    sdp: String.t(),
    type: String.t()
  }

  @doc """
  Handles WHIP (ingestion) requests.
  """
  @spec handle_whip(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def handle_whip(conn, %{"live_id" => live_id} = _params) do
    case conn.method do
      "OPTIONS" -> handle_options(conn)
      "POST" -> handle_whip_post(conn, live_id)
      "DELETE" -> handle_whip_delete(conn, live_id)
      _ -> send_resp(conn, 400, "Not supported")
    end
  end

  @doc """
  Handles WHEP (playback) requests.
  """
  @spec handle_whep(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def handle_whep(conn, %{"live_id" => live_id, "session_id" => session_id} = _params) do
    case conn.method do
      "OPTIONS" -> handle_options(conn)
      "POST" -> handle_whep_post(conn, live_id)
      "PATCH" -> handle_whep_patch(conn, session_id)
      "DELETE" -> send_resp(conn, 200, "OK")
      _ -> send_resp(conn, 404, "Not supported")
    end
  end

  defp handle_options(conn) do
    conn
    |> put_resp_header("accept-post", "application/sdp")
    |> put_resp_header("access-control-allow-credentials", "true")
    |> put_resp_header("access-control-allow-headers", "content-type,authorization,if-match")
    |> put_resp_header("access-control-allow-methods", "PATCH,POST,PUT,DELETE,OPTIONS")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-expose-headers", "x-thunderclap,location,link,accept-post,accept-patch,etag")
    |> put_resp_header("link", "<stun:stun.cloudflare.com:3478>; rel=\"ice-server\"")
    |> send_resp(204, "")
  end

  defp handle_whip_post(conn, live_id) do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, %{"session_id" => session_id}} <- Calls.create_session(),
         {:ok, tracks_result} <- create_tracks(session_id, body) do
      
      tracks = Enum.map(tracks_result["tracks"], fn track ->
        %{
          location: "remote",
          session_id: session_id,
          track_name: track["track_name"]
        }
      end)

      :ok = Store.set_tracks(live_id, tracks)

      conn
      |> put_resp_content_type("application/sdp")
      |> put_resp_header("protocol-version", "draft-ietf-wish-whip-06")
      |> put_resp_header("etag", ~s("#{session_id}"))
      |> put_resp_header("location", "/ingest/#{live_id}/#{session_id}")
      |> send_resp(201, tracks_result["session_description"]["sdp"])
    end
  end

  defp handle_whip_delete(conn, live_id) do
    :ok = Store.delete_tracks(live_id)
    send_resp(conn, 200, "OK")
  end

  defp handle_whep_post(conn, live_id) do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, tracks} <- Store.get_tracks(live_id),
         {:ok, %{"session_id" => session_id}} <- Calls.create_session(),
         {:ok, tracks_result} <- create_tracks(session_id, body, tracks) do
      
      conn
      |> put_resp_content_type("application/sdp")
      |> put_resp_header("protocol-version", "draft-ietf-wish-whep-00")
      |> put_resp_header("etag", ~s("#{session_id}"))
      |> put_resp_header("location", "/play/#{live_id}/#{session_id}")
      |> put_resp_header("access-control-expose-headers", "location")
      |> put_resp_header("access-control-allow-origin", "*")
      |> send_resp(201, tracks_result["session_description"]["sdp"])
    else
      {:ok, []} ->
        conn
        |> put_resp_header("access-control-allow-origin", "*")
        |> send_resp(404, "Live not started yet")
      
      error ->
        handle_error(conn, error)
    end
  end

  defp handle_whep_patch(conn, session_id) do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, _} <- Calls.renegotiate(session_id, %{type: "answer", sdp: body}) do
      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> send_resp(200, "")
    end
  end

  defp create_tracks(session_id, offer_sdp, existing_tracks \\ nil) do
    body = if existing_tracks do
      %{
        tracks: existing_tracks,
        session_description: %{
          type: "offer",
          sdp: offer_sdp
        }
      }
    else
      %{
        session_description: %{
          type: "offer",
          sdp: offer_sdp
        },
        auto_discover: true
      }
    end

    Calls.create_tracks(session_id, body)
  end

  defp handle_error(conn, error) do
    # Log error and return appropriate response
    send_resp(conn, 500, "Internal Server Error")
  end
end
