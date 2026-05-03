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
end
