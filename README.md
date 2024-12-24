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


## TODO

Here's a breakdown of inconsistencies, architectural concerns, design flaws, and missing elements, along with a list of detailed areas needing code work.

**General Observations & Architectural Concerns:**

*   **Dependency Management:**  `cf_core` seems to be an internal dependency, but it's not listed in the `deps` of `cf_calls` or `cf_durable`. This needs to be explicitly declared.
*   **Configuration Duplication:** Configuration logic appears in both `cf_core` and `cf_calls`. A more centralized configuration approach might be beneficial.
*   **Error Handling:** Error handling is present but could be more consistent. Consider using a more structured approach for error propagation and reporting throughout the libraries.
*   **Overlapping Functionality:** There's some overlap in the `API` modules of `cf_core` and `cf_calls`. `cf_core` aims to be the common plumbing, and `cf_calls` should leverage it.
*   **Testing Strategy:** While property-based testing is used, consider adding more targeted unit and integration tests for specific scenarios. The "API.request can return an ok on valid urls" test in `cf_core` is explicitly marked as expected to fail, indicating a need for better testing setup or mocking.
*   **Module Naming:**  In `cf_durable`, the `durable.ex` file defines the `CfDurable.Object` module. The filename should ideally match the primary module it defines.
*   **HTTP Client Choice:**  While `HttpPoison` is a reasonable choice, consider the trade-offs and potential benefits of other HTTP clients like `Mint` or `req`.
*   **Lack of Documentation:** While there are module docs, consider adding more detailed documentation, especially around configuration and usage examples.
*   **Implicit Dependencies:**  Modules like `CfCalls.WhipWhep.Store` have implicit dependencies on specific Durable Object names ("LIVE_STORE"). This could be more configurable or managed.
*   **Plug Router Usage:**  The `CfCore.Router` and `CfCalls.Router` seem like example routers within the libraries themselves. It's not immediately clear if these are meant for testing or as a provided feature. If the latter, more context and documentation are needed.

**Detailed Areas Needing Code Work:**

*   **`cf_ex/mix.exs`:**
    *   Ensure all internal dependencies between apps (e.g., `cf_calls` depends on `cf_core`) are explicitly declared in the `deps` function.
*   **`apps/cf_core/lib/cf_core/api.ex`:**
    *   Consider making the HTTP client (currently hardcoded as `HttpPoison`) configurable.
    *   Standardize error return types (e.g., always return a specific error struct or tuple format).
*   **`apps/cf_core/lib/cf_core/api/client.ex`:**
    *   This module seems redundant given the existence of `CfCore.API`. Consolidate the HTTP request logic into `CfCore.API`.
    *   The `Client` module uses `HTTPoison` directly, bypassing the abstraction in `CfCore.API`. This breaks the intended architecture.
    *   Remove direct usage of `Jason.encode!` and `Jason.decode!` here and rely on `CfCore.API`.
*   **`apps/cf_core/lib/cf_core/config.ex`:**
    *   Consider centralizing configuration for both `cf_core` and potentially other apps. Explore options like a dedicated configuration app or using application environment variables consistently.
    *   Inconsistencies in how configuration is accessed (e.g., `calls_api` vs. `app_id`). Strive for a uniform approach.
    *   The `new/3` and `headers/1` functions suggest this config is meant to be used as a struct, but its usage elsewhere doesn't always reflect that. Clarify the intended use.
*   **`apps/cf_core/lib/cf_core.ex`:**
    *   The `CfCore.API` module here duplicates the functionality of `CfCore.API` in `apps/cf_core/lib/cf_core/api.ex`. Remove this duplication.
*   **`apps/cf_core/test/cf_core_properties.ex`:**
    *   Address the failing test ("API.request can return an ok on valid urls") by setting up a proper testing environment or using mocking.
*   **`apps/cf_core/router.ex`:**
    *   Clarify the purpose of this router. If it's for internal testing, ensure it's not included in production builds or clearly marked as such. If it's a feature, provide documentation and usage examples.
    *   The `forward/4` function is a bit verbose. Consider if there's a more concise way to handle the common logic.
*   **`apps/cf_durable/lib/durable.ex`:**
    *   Rename the file to `cf_durable/object.ex` to match the module name.
*   **`apps/cf_durable/lib/cf_durable.ex`:**
    *   The `CfDurable.Room` module looks like a higher-level abstraction built on top of the basic Durable Object interactions. Consider moving this to a separate library or clarifying its purpose within `cf_durable`.
    *   The duplicated module definitions at the end of the file should be removed.
*   **`apps/cf_durable/test/cf_durable_properties.ex`:**
    *   The "Storage.list with a valid prefix" property test has a `case` statement that could be simplified. Checking `is_list(list)` is sufficient.
*   **`apps/cf_calls/lib/cf_calls.ex`:**
    *   The `CfCalls.Session` module seems to be managing state with `GenServer`, but the `new_session` function is also called outside the `GenServer` context. Clarify the intended usage and state management.
    *   The `LiveStream` and `DataChannel` modules also use `GenServer`. Consider if this is the most appropriate pattern for these functionalities or if simple modules might suffice, relying on the calling application for concurrency.
    *   The `Room` module attempts to manage multiple `GenServer` instances. Ensure proper supervision and error handling are in place.
*   **`apps/cf_calls/lib/cf_calls/sfu.ex` & `apps/cf_calls/lib/cf_calls/turn.ex` & `apps/cf_calls/lib/cf_calls/session.ex`:**
    *   These modules directly pass around `body` and `headers`. These should be constructed within these modules using `CfCore.API` and `CfCore.Config`, not passed as arguments. This couples the API implementation to the caller.
    *   The function signatures should focus on the specific parameters needed for the Cloudflare Calls API, not generic `body` and `headers`.
*   **`apps/cf_calls/lib/cf_calls/whip_whep/handler.ex`:**
    *   The error handling in `handle_whep_post` is basic. Implement more robust error logging and potentially more specific error responses.
    *   Consider extracting common header logic into helper functions.
*   **`apps/cf_calls/lib/cf_calls/whip_whep/store.ex`:**
    *   The hardcoded Durable Object namespace name "LIVE_STORE" should be configurable or managed through a constant.
    *   Error handling when fetching the Durable Object namespace could be more explicit.
*   **`apps/cf_calls/lib/cf_calls/router.ex`:**
    *   Similar to `CfCore.Router`, clarify the purpose of this router.
    *   The `forward/4` function has the same potential simplification as in `CfCore.Router`.
*   **`apps/cf_calls/mix.exs`:**
    *   Add `cf_core` as a dependency.
*   **`config/config.exs`:**
    *   Consider providing default configurations or examples here.



**Project Structure and Setup**
Your project is set up as an Elixir umbrella application, which is excellent for managing multiple interconnected applications (cf_core, cf_calls, cf_durable). Here's a quick rundown:

- **cf_core:** Provides the basic plumbing for interacting with Cloudflare's API, including HTTP requests and JSON handling.
- **cf_calls:** Focuses on Cloudflare Calls, handling session management, TURN server interactions, and SFU controls.
- **cf_durable:** Manages interactions with Cloudflare Durable Objects for stateful operations.

**Key Points to Consider:**
- **Dependencies Management:** Ensure all applications have the necessary dependencies listed in their respective mix.exs files. cf_core depends on httpoison for HTTP requests and jason for JSON handling, which should be reflected in cf_calls and cf_durable if they use these libraries indirectly or directly.
- **Configuration:** Your applications use environment variables for sensitive information like API keys. Make sure these are set in your development environment or use a configuration file (like config/config.exs) for non-sensitive configurations.

**Testing:**
You've implemented property-based tests using StreamData, which is great for ensuring robustness. Remember to mock external API calls for tests to avoid rate limiting and to make tests faster and more reliable. Libraries like Mox or Mock can help with this.
- **Documentation:** The README.md files are placeholders. Flesh these out with usage examples, setup instructions, and perhaps some diagrams or flowcharts to explain how each component interacts.
- **Deployment Considerations:** If you plan to deploy this, consider how you'll handle the Cloudflare bindings, which might require specific setup on Cloudflare Workers or similar environments where Elixir might not run natively.
- **Error Handling:** Your error handling seems basic. Consider making it more robust across all modules, especially for API interactions where network issues or Cloudflare-specific errors might occur.
- **Performance and Concurrency:** Elixir's advantage is in handling concurrency. Make sure your modules are designed to leverage this, especially in cf_durable where operations might be I/O-bound.

**Next Steps:**
- **Complete Documentation:** Update all README.md files with comprehensive documentation.
- **CI/CD Setup:** Consider setting up a CI pipeline with GitHub Actions to automate tests, formatting, and potentially deployment.
- **Integration Testing:** While you have good unit and property-based tests, think about integration tests that check how these applications work together.
- **Security:** Since you're dealing with APIs, consider security aspects like proper authentication, rate limiting, and handling of sensitive data.
- **Code Review:** If possible, have someone else review your code for potential improvements or issues you might have missed.
- **Publishing:** Once you're confident in your libraries, consider publishing them to Hex.pm for wider use or to make dependency management easier for other projects.

This project seems like a solid foundation for integrating BEAM with Cloudflare's services. Keep up the good work, and consider these points as you move forward!