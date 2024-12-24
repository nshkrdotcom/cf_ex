### new stateless DataChannel Operations
defmodule CfCalls.DataChannel do
  @moduledoc """
  Handles DataChannel creation for Cloudflare Calls.
  
  DataChannels allow pub/sub style real-time data transmission between sessions.
  The actual data transmission happens client-side via WebRTC DataChannels.
  This module only handles the server-side channel setup.

  Usage:
    # Create a publisher channel
    {:ok, pub} = CfCalls.DataChannel.create_publisher(config, session_id, "my-channel")

    # Create a subscriber that connects to the publisher
    {:ok, sub} = CfCalls.DataChannel.create_subscriber(config, session_id, "my-channel", pub.session_id)
  """
  
  alias CfCalls.Types

  @doc """
  Creates a publisher (local) DataChannel in a session.
  """
  @spec create_publisher(map(), String.t(), String.t()) ::
    {:ok, Types.datachannels_response()} | {:error, Types.error_response()}
  def create_publisher(config, session_id, channel_name) do
    CfCalls.Client.request(:post, "#{config.app_id}/sessions/#{session_id}/datachannels/new", config, %{
      dataChannels: [
        %{location: "local", dataChannelName: channel_name}
      ]
    })
  end

  @doc """
  Creates a subscriber (remote) DataChannel that connects to a publisher.
  """
  @spec create_subscriber(map(), String.t(), String.t(), String.t()) ::
    {:ok, Types.datachannels_response()} | {:error, Types.error_response()}
  def create_subscriber(config, session_id, channel_name, publisher_session_id) do
    CfCalls.Client.request(:post, "#{config.app_id}/sessions/#{session_id}/datachannels/new", config, %{
      dataChannels: [
        %{
          location: "remote",
          dataChannelName: channel_name,
          sessionId: publisher_session_id
        }
      ]
    })
  end
end
