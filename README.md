# cf_ex

Elixir libraries for Cloudflare edge computing services. Battle-tested BEAM implementations of Cloudflare Calls and Durable Objects.

## Structure

This project uses an umbrella structure with the following applications:

* `cf_core`: Common plumbing and utilities for interacting with the Cloudflare API.
* `cf_calls`:  Robust Elixir client for the Cloudflare Calls API.
* `cf_durable`:  High-performance interface to Cloudflare Durable Objects.

## Installation

```elixir
def deps do
  [
    {:cf_calls, "~> 0.1.0"},
    {:cf_durable, "~> 0.1.0"}
  ]
end

## License

MIT License.
