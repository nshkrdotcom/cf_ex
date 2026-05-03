defmodule CfDurablePropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import ExUnit.CaptureLog

  property "storage calls fail closed when the Cloudflare runtime is absent" do
    check all(
            key <- string(:alphanumeric, min_length: 1, max_length: 64),
            value <- term()
          ) do
      assert CfDurable.Storage.put(key, value) == {:error, "Cloudflare runtime unavailable"}
      assert CfDurable.Storage.get(key) == {:error, "Cloudflare runtime unavailable"}
      assert CfDurable.Storage.list(key) == {:error, "Cloudflare runtime unavailable"}
      assert CfDurable.Storage.delete(key) == {:error, "Cloudflare runtime unavailable"}
    end
  end

  property "object namespace lookup fails closed for arbitrary runtime names" do
    check all(name <- string(:printable, min_length: 1, max_length: 64)) do
      log =
        capture_log(fn ->
          assert {:error, message} = CfDurable.Object.get_namespace(name)
          send(self(), {:namespace_lookup_message, message})
        end)

      assert log != ""
      assert_received {:namespace_lookup_message, error_message}
      assert String.contains?(error_message, "Cloudflare runtime unavailable")
    end
  end
end
