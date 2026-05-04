defmodule CfDurableAuthorityGuardTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  test "governed Durable Object authority rejects raw binding and object values" do
    assert {:error, message} =
             CfDurable.Object.get_namespace(
               "ENV_LIVE_STORE",
               "env-object-id",
               governed_authority: %{
                 authority_ref: "authority/cloudflare",
                 binding_name: "ENV_LIVE_STORE",
                 object_id: "env-object-id"
               }
             )

    assert String.contains?(message, "Durable Object authority rejected")
    refute String.contains?(message, "ENV_LIVE_STORE")
    refute String.contains?(message, "env-object-id")
  end

  test "governed Durable Object authority accepts refs and fails closed before runtime IO" do
    assert {:error, message} =
             CfDurable.Object.get_namespace(
               %{
                 binding_ref: "binding/live-store",
                 object_ref: "object/live-stream",
                 target_ref: "target://tenant-1/durable-object/live-store",
                 attach_grant_ref: "attach-grant://tenant-1/durable-object/live-store",
                 target_auth_posture_ref: "target-posture://tenant-1/durable-object/live-store"
               },
               governed_authority: %{authority_ref: "authority/cloudflare"}
             )

    assert String.contains?(message, "not materialized")
  end

  test "governed Durable Object authority requires target attach refs" do
    assert {:error, message} =
             CfDurable.Object.get_namespace(
               %{
                 binding_ref: "binding/live-store",
                 object_ref: "object/live-stream"
               },
               governed_authority: %{authority_ref: "authority/cloudflare"}
             )

    assert String.contains?(message, "target_ref")
    assert String.contains?(message, "attach_grant_ref")
    assert String.contains?(message, "target_auth_posture_ref")
  end

  test "standalone namespace lookup preserves runtime-unavailable behavior with redacted logs" do
    secret_name = "ENV_LIVE_STORE_SECRET"

    log =
      capture_log(fn ->
        assert {:error, message} = CfDurable.Object.get_namespace(secret_name)
        assert String.contains?(message, "Cloudflare runtime unavailable")
        refute String.contains?(message, secret_name)
      end)

    refute String.contains?(log, secret_name)
  end
end
