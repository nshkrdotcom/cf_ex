# CfCalls

Elixir client for Cloudflare Calls API. Handles server-side API calls for managing WebRTC sessions, tracks, and data channels.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cf_calls` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cf_calls, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cf_calls>.


## Usage

### Configuration

```elixir
config = CfCalls.Config.new(
  System.get_env("CALLS_API"),
  System.get_env("CALLS_APP_ID"),
  System.get_env("CALLS_APP_SECRET")
)
```

### Sessions and Tracks

```elixir
# Create a new session
{:ok, session} = CfCalls.Client.new_session(config)

# Add tracks to session
{:ok, tracks} = CfCalls.Client.create_tracks(config, session.session_id, %{
  tracks: [
    %{media_type: "audio"},
    %{media_type: "video"}
  ]
})

# Close tracks
{:ok, _} = CfCalls.Client.close_tracks(config, session.session_id, %{
  tracks: [track_id1, track_id2]
})
```

### DataChannels

DataChannels enable real-time data transmission between sessions in a pub/sub model:

```elixir
# Create a publisher channel
{:ok, pub} = CfCalls.DataChannel.create_publisher(config, session_id, "my-channel")

# Create subscribers that connect to the publisher
{:ok, sub1} = CfCalls.DataChannel.create_subscriber(config, session2_id, "my-channel", pub.session_id)
{:ok, sub2} = CfCalls.DataChannel.create_subscriber(config, session3_id, "my-channel", pub.session_id)
```

The actual data transmission happens client-side via WebRTC DataChannels. Example client-side code:

```javascript
// Publisher (after getting channel ID from server)
const channel = peerConnection.createDataChannel("my-channel", {
  negotiated: true,
  id: channelResponse.datachannels[0].id
});
channel.send("Hello subscribers!");

// Subscribers
channel.addEventListener('message', (evt) => {
  console.log("Received:", evt.data);
});
```

### Rate Limiting

This library is stateless and does not implement rate limiting. See [Cloudflare's documentation](https://developers.cloudflare.com/calls/limits/) for limits and implement rate limiting at the application level.

## Documentation

The docs can be found at [https://hexdocs.pm/cf_calls](https://hexdocs.pm/cf_calls).


## Architecture

```mermaid
graph LR
    subgraph "cf_calls"
        Session(Session Module)
        TURN(TURN Module)
        SFU(SFU Module)
         SDP(SDP Module)
        
    end
    
     subgraph "cf_core"
        API(API Module)
        
        
    end
    
     API --> Session
    API --> TURN
    API --> SFU
  
    classDef calls fill:#b39ddb,stroke:#4527a0
    classDef core fill:#fff3e0,stroke:#e65100
    
    class CfCalls,Session,TURN,SFU,SDP calls
    class cf_core,API core
```

## Discussion

`cf_calls` is a low-level library specifically for Cloudflare Calls. It's structured around three core components: Session Management, TURN Server management, and SFU parameter controls.

The **`Session Module`** is responsible for implementing all functions related to the lifecycle of calls sessions such as creating, renegotiation, closing.
  It will use `cf_core` to make those HTTP API requests using the API module while keeping track of all calls specific information, and transforming the response data to match the Elixir domain requirements. This pattern will be followed in all modules.
  
 The **`TURN Module`**  exposes the functionalities to create, read, update, and delete TURN keys. All of these requests will rely on the underlaying `CfCore.API`.

The  **`SFU Module`**   will provide utilities for manipulating Cloudflare SFU specific configuration. This will also depend on the underlaying `CfCore.API` module to execute requests.

 The **`SDP Module`** is a stateless utility that contains all functions related to SDP manipulation (currently just Opus DTX).

The primary design consideration here is to separate the low-level details about making http requests to a module (`cf_core`) to avoid having to reimplement the same logic in each of the modules here, while still being able to make granular changes at the Cloudflare calls level. Note that this module is stateless and does not have a supervision tree associated with it because it doesn't handle a lifecycle of a long running process.


## TODO:

Next steps for completing cf_calls:

Missing API Features:
Review Cloudflare docs for any missing endpoints
Ensure all error cases are handled properly
Add proper validation for request parameters
Testing:
Add ExUnit tests for all modules
Add doctests for example usage
Add mocks for API responses
Documentation:
Add module documentation
Add typespecs for all functions
Add examples for all functions