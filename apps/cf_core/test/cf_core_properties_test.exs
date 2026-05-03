defmodule CfCorePropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "config headers stay binary and preserve token input" do
    check all(token <- string(:alphanumeric, min_length: 1, max_length: 64)) do
      headers = CfCore.Config.headers(%CfCore.Config{app_token: token})

      assert {"Authorization", "Bearer " <> actual_token} =
               List.keyfind(headers, "Authorization", 0)

      assert {"Content-Type", "application/json"} = List.keyfind(headers, "Content-Type", 0)
      assert actual_token == token
      assert Enum.all?(headers, fn {key, value} -> is_binary(key) and is_binary(value) end)
    end
  end

  property "SDP generation preserves arbitrary payloads while enabling DTX" do
    check all(
            prefix <- string(:printable, max_length: 64),
            suffix <- string(:printable, max_length: 64)
          ) do
      input = prefix <> "useinbandfec=1" <> suffix

      assert CfCore.SDP.generate_sdp(input) == prefix <> "usedtx=1;useinbandfec=1" <> suffix
    end
  end
end
