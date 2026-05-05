# CfDurable

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cf_durable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cf_durable, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cf_durable>.

**1. `cf_durable` Architecture:**

```mermaid
graph LR
   subgraph "cf_durable"
        Object(Object Module)
        Storage(Storage Module)
    end
    
    subgraph "cloudflare"
    binding("Durable Object Binding")
    end
   
    Object --> binding
    Storage --> binding
    
    classDef durable fill:#e8f5e9,stroke:#1b5e20
     classDef cloudflare fill:#fff3e0,stroke:#e65100
    
    class CfDurable,Object,Storage durable
    class Cloudflare,binding cloudflare
```

**Discussion:**

`cf_durable` is another low-level library, but instead of focusing on the Cloudflare Calls API, its focus is on simplifying interactions with Durable Objects using the Elixir API.

The **`Object` module** serves as the entry point to interact with DO namespaces providing the ability to directly fetch the durable object by name from the cloudflare runtime.

The **`Storage` module** has a clean functional API for reading/writing to the Durable Object's storage.

The goal here is to separate the responsibility for interacting with the Durable Objects from higher-level features, offering only the low-level APIs for using DO functionality. These operations are stateless, which is why no supervision tree is created in this module. This design pattern also supports reuse and extensibility of the module, allowing other higher level packages to integrate with it, without requiring a specific implementation. This allows for the core module to stay light-weight and focused on its core concerns.

## Authority contract

Standalone calls may still resolve a Cloudflare runtime binding by name:

```elixir
CfDurable.Object.get_namespace("LIVE_STORE", "stream-id")
```

Governed calls must carry refs and fail closed until the selected authority
materializer provides a scoped binding:

```elixir
CfDurable.Object.get_namespace(
  %{binding_ref: "binding/live-store", object_ref: "object/stream"},
  governed_authority: %{authority_ref: "authority/cloudflare"}
)
```

Raw binding names, object ids, deployment settings, workspace secrets, storage
authority, alarm authority, and target credentials are rejected in governed
mode. Runtime errors use fixed-literal redaction before logs or receipts expose
provider or deployment values.

Runtime dispatch is bounded by `CfDurable.RuntimePolicy`. Public calls into the
Cloudflare runtime accept only the source-owned Durable Object operations used
by this package and reject unknown function atoms before runtime dispatch.
