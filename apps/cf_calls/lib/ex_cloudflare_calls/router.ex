defmodule ExCloudflareCalls.Router do
  @moduledoc """
    Router for Cloudflare Calls API endpoints.
    """
  use Plug.Router

  alias ExCloudflareCalls.Session
  alias ExCloudflareCalls.SFU
  alias ExCloudflareCalls.TURN

  plug :match
  plug :dispatch

   # Session endpoints
  post "/sessions/new" do
       forward(conn, Session, :new_session)
  end

  post "/sessions/:session_id/tracks/new" do
       forward(conn, Session, :new_tracks, session_id: conn.params["session_id"])
  end

  put "/sessions/:session_id/renegotiate" do
      forward(conn, Session, :renegotiate, session_id: conn.params["session_id"])
  end

  put "/sessions/:session_id/tracks/close" do
        forward(conn, Session, :close_track, session_id: conn.params["session_id"])
  end

  # SFU Endpoints

  post "/apps" do
    forward(conn, SFU, :create_app)
  end

  get "/apps" do
    forward(conn, SFU, :get_app)
  end

  delete "/apps/:app_id" do
    forward(conn, SFU, :delete_app, app_id: conn.params["app_id"])
  end

  put "/apps/:app_id" do
    forward(conn, SFU, :edit_app, app_id: conn.params["app_id"])
  end
  get "/apps" do
    forward(conn, SFU, :list_apps)
  end

  # TURN Key Endpoints

  post "/turn_keys" do
  forward(conn, TURN, :create_turn_key)
  end

  get "/turn_keys/:key_id" do
  forward(conn, TURN, :get_turn_key, key_id: conn.params["key_id"])
  end

  get "/turn_keys" do
    forward(conn, TURN, :list_turn_keys)
  end

  put "/turn_keys/:key_id" do
    forward(conn, TURN, :edit_turn_key, key_id: conn.params["key_id"])
  end


  delete "/turn_keys/:key_id" do
    forward(conn, TURN, :delete_turn_key, key_id: conn.params["key_id"])
  end

  match _ do
  send_resp(conn, 404, "Not found")
  end

  defp forward(conn, module, function, params \\ []) do
    with {:ok, body, conn} <- read_body(conn),
        {:ok, response} <- apply(module, function, [body |> Map.merge(params), conn.req_headers]) do
      conn
      |> send_resp(200, Jason.encode!(response))
    else
      {:error, reason} ->
        conn
        |> send_resp(500, "Internal server Error: #{reason}")
    end
  end
end
