defmodule ExCloudflareCalls.WhipWhep.Router do
  @moduledoc """
  Router for WHIP/WHEP endpoints.
  """

  use Plug.Router

  alias ExCloudflareCalls.WhipWhep.Handler

  plug :match
  plug :dispatch

  # WHIP endpoints
  options "/ingest/:live_id" do
    Handler.handle_whip(conn, params)
  end

  post "/ingest/:live_id" do
    Handler.handle_whip(conn, params)
  end

  delete "/ingest/:live_id" do
    Handler.handle_whip(conn, params)
  end

  # WHEP endpoints
  options "/play/:live_id" do
    Handler.handle_whep(conn, params)
  end

  post "/play/:live_id" do
    Handler.handle_whep(conn, params)
  end

  patch "/play/:live_id/:session_id" do
    Handler.handle_whep(conn, params)
  end

  delete "/play/:live_id/:session_id" do
    Handler.handle_whep(conn, params)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
