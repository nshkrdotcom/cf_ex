defmodule CfCallsPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "config preserves caller supplied app identity strings" do
    check all(
            app_id <- string(:alphanumeric, min_length: 1, max_length: 64),
            app_token <- string(:alphanumeric, min_length: 1, max_length: 128)
          ) do
      assert %CfCalls.Config{app_id: ^app_id, app_token: ^app_token} =
               CfCalls.Config.new(app_id, app_token)
    end
  end

  property "unsupported HTTP methods fail closed before provider IO" do
    check all(method <- member_of(["CONNECT", "OPTIONS", "TRACE"])) do
      assert {:error, %CfCore.API.Error{type: :method, context: %{method: ^method}}} =
               CfCore.API.request(method, "http://127.0.0.1:1", [], %{})
    end
  end

  test "governed Calls client rejects raw app identity before provider IO" do
    config =
      CfCalls.Config.new("env-app-id", "env-secret-token",
        governed_authority: %{
          authority_ref: "authority/cloudflare",
          base_url_ref: "endpoint/cloudflare-calls",
          app_id_ref: "calls-app/live",
          app_token_ref: "credential/cloudflare-calls"
        },
        redaction_values: ["env-secret-token"]
      )

    assert {:error, error} = CfCalls.Client.request(:post, "env-app-id/sessions/new", config)
    assert error.blocked_fields == [:app_id, :app_token]
    refute String.contains?(inspect(error), "env-secret-token")
  end
end
