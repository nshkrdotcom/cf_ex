defmodule ExCloudflareCalls do
  @moduledoc """
  Comprehensive Cloudflare Calls API client that combines:
  - Basic session management (echo example)
  - WebRTC relay (openai example)
  - WHIP/WHEP protocols (whip-whep example)
  - Data channels (echo-datachannels example)
  """

  # Core Types
  defmodule Types do
    @type session_description :: %{
      type: String.t(),
      sdp: String.t()
    }

    @type track_locator :: %{
      location: String.t(),
      session_id: String.t(),
      track_name: String.t()
    }

    @type new_track_response :: %{
      track_name: String.t(),
      mid: String.t(),
      optional(:error_code) => String.t(),
      optional(:error_description) => String.t()
    }
  end

  # Session Management
  defmodule Session do
    use GenServer
    alias ExCloudflareCalls.Types

    defstruct [:session_id, :headers, :endpoint]

    def start_link(config) do
      GenServer.start_link(__MODULE__, config)
    end

    def init(config) do
      {:ok, session} = new_session(config)
      {:ok, session}
    end

    # Core Session Operations
    def new_session(config, opts \\ []) do
      headers = [
        {"Authorization", "Bearer #{config.app_token}"},
        {"Content-Type", "application/json"}
      ]

      endpoint = "#{config.base_url}/#{config.app_id}"
      url = "#{endpoint}/sessions/new?streamDebug"

      url = if opts[:third_party],
        do: url <> "&thirdparty=true",
        else: url

      with {:ok, response} <- HTTPoison.post(url, "", headers),
           {:ok, body} <- Jason.decode(response.body),
           %{"sessionId" => session_id} <- body do
        {:ok, %__MODULE__{
          session_id: session_id,
          headers: headers,
          endpoint: endpoint
        }}
      end
    end

    # Track Management
    def new_tracks(session, body) do
      url = "#{session.endpoint}/sessions/#{session.session_id}/tracks/new?streamDebug"

      with {:ok, response} <- HTTPoison.post(url, Jason.encode!(body), session.headers),
           {:ok, body} <- Jason.decode(response.body) do
        validate_tracks_response(body)
      end
    end

    def renegotiate(session, sdp) do
      url = "#{session.endpoint}/sessions/#{session.session_id}/renegotiate?streamDebug"
      body = %{sessionDescription: sdp}

      HTTPoison.put(url, Jason.encode!(body), session.headers)
    end
  end

  # WHIP/WHEP Protocol Support
  defmodule LiveStream do
    use GenServer

    defstruct [:live_id, :tracks, :session]

    def start_link(config) do
      GenServer.start_link(__MODULE__, config)
    end

    # WHIP Ingest
    def create_ingest(live_id, sdp, config) do
      with {:ok, session} <- Session.new_session(config),
           {:ok, tracks} <- Session.new_tracks(session, %{
             sessionDescription: %{type: "offer", sdp: sdp},
             autoDiscover: true
           }) do
        {:ok, %__MODULE__{
          live_id: live_id,
          tracks: tracks,
          session: session
        }}
      end
    end

    # WHEP Playback
    def create_playback(live_id, tracks, config) do
      with {:ok, session} <- Session.new_session(config),
           {:ok, _} <- Session.new_tracks(session, %{
             tracks: tracks
           }) do
        {:ok, session}
      end
    end
  end

  # Data Channels Support
  defmodule DataChannel do
    use GenServer

    def start_link(session) do
      GenServer.start_link(__MODULE__, session)
    end

    def create_channel(session, label) do
      Session.new_tracks(session, %{
        tracks: [%{
          dataChannel: %{
            label: label
          }
        }]
      })
    end
  end

  # High-level API
  defmodule Room do
    @moduledoc """
    High-level abstraction combining all features
    """
    use GenServer

    defstruct [:session, :data_channel, :live_stream]

    def start_link(config) do
      GenServer.start_link(__MODULE__, config)
    end

    def init(config) do
      with {:ok, session} <- Session.start_link(config),
           {:ok, data_channel} <- DataChannel.start_link(session),
           {:ok, live_stream} <- LiveStream.start_link(config) do
        {:ok, %__MODULE__{
          session: session,
          data_channel: data_channel,
          live_stream: live_stream
        }}
      end
    end

    # Comprehensive Room Management
    def create_room(config) do
      start_link(config)
    end

    def join_room(room, sdp) do
      Session.new_tracks(room.session, %{
        sessionDescription: %{type: "offer", sdp: sdp}
      })
    end

    def start_broadcast(room, sdp) do
      LiveStream.create_ingest(room.live_stream.live_id, sdp, config)
    end

    def send_message(room, message) do
      DataChannel.send(room.data_channel, message)
    end
  end

  # Configuration Management
  defmodule Config do
    @enforce_keys [:base_url, :app_id, :app_token]
    defstruct [:base_url, :app_id, :app_token]

    def new(base_url, app_id, app_token) do
      %__MODULE__{
        base_url: base_url,
        app_id: app_id,
        app_token: app_token
      }
    end
  end

  # Error Handling
  defmodule Error do
    defexception [:message, :code]

    def exception({code, description}) do
      %__MODULE__{
        message: description,
        code: code
      }
    end
  end
end








defmodule ExCloudflareCalls.Calls do
  @moduledoc """
  Provides the primary interface for interacting with the Cloudflare Calls API.
  """
    alias ExCloudflareCalls.Session
    alias ExCloudflareCalls.TURN
  alias ExCloudflareCalls.SFU
    require Logger
    @type session :: %{
        session_id: String.t()
      }
  @spec new_session(String.t(), String.t(), keyword) ::
      {:ok, session} | {:error, String.t()}
  def new_session(app_id, app_token, opts \\ []) do
      Session.new_session(app_id, app_token, opts)
  end

  @spec new_tracks(String.t(), String.t(), list(map()), keyword()) ::
      {:ok, map()} | {:error, String.t()}
  def new_tracks(session_id, app_id, tracks, opts \\ []) do
      Session.new_tracks(session_id, app_id, tracks, opts)
    end

  @spec renegotiate(String.t(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def renegotiate(session_id, app_id, sdp, type, opts \\ []) do
      Session.renegotiate(session_id, app_id, sdp, type, opts)
  end

  @spec close_track(String.t(), String.t(), list(map()), keyword()) ::
      {:ok, map()} | {:error, String.t()}
  def close_track(session_id, app_id, tracks, opts \\ []) do
      Session.close_track(session_id, app_id, tracks, opts)
  end

  @spec create_turn_key(String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
  def create_turn_key(app_id, app_token, opts \\ []) do
   TURN.create_turn_key(app_id, app_token, opts)
   end

    @spec get_turn_key(String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
   def get_turn_key(app_id, app_token, key_id, opts \\ []) do
    TURN.get_turn_key(app_id, app_token, key_id, opts)
  end

     @spec list_turn_keys(String.t(), String.t(), keyword) ::
        {:ok, map()} | {:error, String.t()}
   def list_turn_keys(app_id, app_token, opts \\ []) do
    TURN.list_turn_keys(app_id, app_token, opts)
  end

      @spec edit_turn_key(String.t(), String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
     def edit_turn_key(app_id, app_token, key_id, opts \\ []) do
      TURN.edit_turn_key(app_id, app_token, key_id, opts)
    end

       @spec delete_turn_key(String.t(), String.t(), String.t(), keyword) ::
        {:ok, map()} | {:error, String.t()}
    def delete_turn_key(app_id, app_token, key_id, opts \\ []) do
      TURN.delete_turn_key(app_id, app_token, key_id, opts)
    end

     @spec edit_app(String.t(), String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
    def edit_app(app_id, app_token, body, opts \\ []) do
      SFU.edit_app(app_id, app_token, body, opts)
    end

     @spec get_app(String.t(), String.t(), keyword) ::
       {:ok, map()} | {:error, String.t()}
   def get_app(app_id, app_token, opts \\ []) do
      SFU.get_app(app_id, app_token, opts)
    end

       @spec delete_app(String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
     def delete_app(app_id, app_token, opts \\ []) do
        SFU.delete_app(app_id, app_token, opts)
    end

      @spec list_apps(String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
     def list_apps(app_id, app_token, opts \\ []) do
        SFU.list_apps(app_id, app_token, opts)
    end

      @spec create_app(String.t(), String.t(), map(), keyword) ::
        {:ok, map()} | {:error, String.t()}
   def create_app(app_id, app_token, body, opts \\ []) do
      SFU.create_app(app_id, app_token, body, opts)
    end
end
