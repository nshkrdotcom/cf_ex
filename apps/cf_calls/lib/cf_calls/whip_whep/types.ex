# Shared types and structs

## TODO: is this supposed to be in `cf_calls` instead of `cf_calls/whip_whep` ?
defmodule CfCalls.Types do
  @type track_location :: :local | :remote
  @type track_config :: %{
    location: track_location(),
    optional(:session_id) => String.t(),
    optional(:track_name) => String.t()
  }
end
