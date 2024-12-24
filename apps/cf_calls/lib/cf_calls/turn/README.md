# Generate credentials
```elixir
config = %CfCore.Config{
  base_url: "https://rtc.live.cloudflare.com/v1",
  turn_key_id: "your_turn_key_id",
  turn_api_token: "your_turn_api_token"
}

{:ok, credentials} = CfCalls.Turn.Client.generate_credentials(config)
ice_servers = CfCalls.Turn.Client.get_ice_servers(credentials)
```
# Use in WebRTC configuration
# ice_servers will be used in the RTCPeerConnection configuration


# Key Features:

1. Credential Management
- Generation with configurable TTL
- Revocation support
- Automatic expiration handling
2. Security
Short-lived credentials (default 24h)
Proper API token handling
Secure transport options
3. Protocol Support
STUN over UDP
TURN over UDP
TURN over TCP
TURN over TLS

# TURN Key Management

Note: TURN key management is part of Cloudflare's API but handled separately from the main Calls API:
- Create TURN key: POST /accounts/{account_id}/calls/turn_keys
- Delete TURN key: DELETE /accounts/{account_id}/calls/turn_keys/{key_id}
- Get TURN key: GET /accounts/{account_id}/calls/turn_keys/{key_id}
- List TURN keys: GET /accounts/{account_id}/calls/turn_keys
- Edit TURN key: PUT /accounts/{account_id}/calls/turn_keys/{key_id}

These endpoints are account-level operations, not app-level like the main Calls API.