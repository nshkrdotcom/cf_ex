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