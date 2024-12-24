### new stateless DataChannel Operations
defmodule CfCalls.DataChannel do
  @moduledoc """
  Stateless interface for Cloudflare Calls DataChannel operations.
  """

  @type datachannel_config :: %{
    location: String.t(),
    datachannel_name: String.t(),
    optional(:session_id) => String.t()
  }

  @spec create(Config.t(), session_id(), [datachannel_config()]) ::
    {:ok, map()} | {:error, term()}
  def create(config, session_id, channels) do
    API.request("POST",
      "#{config.base_url}/#{config.app_id}/sessions/#{session_id}/datachannels/new",
      [
        {"Authorization", "Bearer #{config.app_token}"},
        {"Content-Type", "application/json"}
      ],
      %{dataChannels: channels}
    )
  end
end
