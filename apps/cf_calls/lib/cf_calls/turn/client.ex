# lib/cf_calls/turn/client.ex
defmodule CfCalls.Turn.Client do
  @moduledoc """
  Client for Cloudflare's TURN service.

  Provides functionality for:
  - Generating TURN credentials
  - Managing TURN configuration
  - Handling credential expiration
  """

  alias CfCore.API
  alias CfCore.Config

  @default_ttl 86400  # 24 hours

  @ice_servers [
    "stun:stun.cloudflare.com:3478",
    "turn:turn.cloudflare.com:3478?transport=udp",
    "turn:turn.cloudflare.com:3478?transport=tcp",
    "turns:turn.cloudflare.com:5349?transport=tcp"
  ]

  @type credentials_response :: %{
    ice_servers: [String.t()],
    username: String.t(),
    credential: String.t()
  }

  @doc """
  Generates TURN credentials with specified TTL.
  """
  @spec generate_credentials(Config.t(), pos_integer()) ::
    {:ok, credentials_response()} | {:error, term()}
  def generate_credentials(config, ttl \\ @default_ttl) do
    API.request("POST",
      "#{config.base_url}/turn/keys/#{config.turn_key_id}/credentials/generate",
      [
        {"Authorization", "Bearer #{config.turn_api_token}"},
        {"Content-Type", "application/json"}
      ],
      %{ttl: ttl}
    )
  end

  @doc """
  Revokes specific TURN credentials.
  """
  @spec revoke_credentials(Config.t(), String.t()) :: :ok | {:error, term()}
  def revoke_credentials(config, username) do
    case API.request("POST",
      "#{config.base_url}/turn/keys/#{config.turn_key_id}/credentials/#{username}/revoke",
      [{"Authorization", "Bearer #{config.turn_api_token}"}]
    ) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  @doc """
  Returns the list of ICE servers with credentials.
  """
  @spec get_ice_servers(credentials_response()) :: [map()]
  def get_ice_servers(%{username: username, credential: credential}) do
    [
      %{
        urls: @ice_servers,
        username: username,
        credential: credential
      }
    ]
  end
end
