defmodule CfCoreAuthorityGuardTest do
  use ExUnit.Case, async: false

  @env_keys ["CALLS_API", "CALLS_APP_ID", "CALLS_APP_SECRET"]
  @app_keys [:calls_api, :calls_app_id, :calls_app_secret]

  setup do
    env_snapshot = Enum.map(@env_keys, &{&1, System.get_env(&1)})
    app_snapshot = Enum.map(@app_keys, &{&1, Application.get_env(:cf_core, &1)})

    on_exit(fn ->
      Enum.each(env_snapshot, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)

      Enum.each(app_snapshot, fn
        {key, nil} -> Application.delete_env(:cf_core, key)
        {key, value} -> Application.put_env(:cf_core, key, value)
      end)
    end)

    :ok
  end

  test "standalone config preserves caller supplied values" do
    assert %CfCore.Config{
             base_url: "https://rtc.live.cloudflare.com/v1",
             app_id: "standalone-app",
             app_token: "standalone-token"
           } =
             CfCore.Config.new(
               "https://rtc.live.cloudflare.com/v1",
               "standalone-app",
               "standalone-token"
             )
  end

  test "governed calls authority rejects unmanaged env and app config values" do
    System.put_env("CALLS_API", "https://env.invalid")
    System.put_env("CALLS_APP_ID", "env-app-id")
    System.put_env("CALLS_APP_SECRET", "env-secret-token")
    Application.put_env(:cf_core, :calls_app_secret, "app-secret-token")

    assert {:error, error} =
             CfCore.AuthorityGuard.validate_calls_authority(
               governed_authority: %{
                 authority_ref: "authority/cloudflare",
                 base_url: System.get_env("CALLS_API"),
                 app_id: System.get_env("CALLS_APP_ID"),
                 app_token: Application.get_env(:cf_core, :calls_app_secret)
               }
             )

    assert error.blocked_fields == [:base_url, :app_id, :app_token]
    refute String.contains?(error.message, "env-secret-token")
    refute String.contains?(error.message, "app-secret-token")
  end

  test "governed calls authority accepts bounded refs" do
    assert {:ok, authority} =
             CfCore.AuthorityGuard.validate_calls_authority(
               governed_authority: %{
                 authority_ref: "authority/cloudflare",
                 base_url_ref: "endpoint/cloudflare-calls",
                 app_id_ref: "calls-app/live",
                 app_token_ref: "credential/cloudflare-calls",
                 target_ref: "target://tenant-1/cloudflare-calls/session",
                 attach_grant_ref: "attach-grant://tenant-1/cloudflare-calls/session",
                 target_auth_posture_ref: "target-posture://tenant-1/cloudflare-calls/session"
               }
             )

    assert authority.authority_ref == "authority/cloudflare"
    assert authority.app_token_ref == "credential/cloudflare-calls"
    assert authority.target_ref == "target://tenant-1/cloudflare-calls/session"
    assert authority.attach_grant_ref == "attach-grant://tenant-1/cloudflare-calls/session"
  end

  test "governed calls authority requires target attach refs" do
    assert {:error, error} =
             CfCore.AuthorityGuard.validate_calls_authority(
               governed_authority: %{
                 authority_ref: "authority/cloudflare",
                 base_url_ref: "endpoint/cloudflare-calls",
                 app_id_ref: "calls-app/live",
                 app_token_ref: "credential/cloudflare-calls"
               }
             )

    assert :target_ref in error.missing_refs
    assert :attach_grant_ref in error.missing_refs
    assert :target_auth_posture_ref in error.missing_refs
  end

  test "governed core client rejects raw API config before provider IO" do
    config =
      CfCore.Config.new("https://env.invalid", "env-app-id", "env-secret-token",
        governed_authority: %{
          authority_ref: "authority/cloudflare",
          base_url_ref: "endpoint/cloudflare-calls",
          app_id_ref: "calls-app/live",
          app_token_ref: "credential/cloudflare-calls",
          target_ref: "target://tenant-1/cloudflare-calls/session",
          attach_grant_ref: "attach-grant://tenant-1/cloudflare-calls/session",
          target_auth_posture_ref: "target-posture://tenant-1/cloudflare-calls/session"
        },
        redaction_values: ["env-secret-token", "https://env.invalid"]
      )

    assert {:error, error} = CfCore.API.Client.post(config, "/sessions/new", %{})
    assert error.blocked_fields == [:base_url, :app_id, :app_token]
    refute String.contains?(inspect(error), "env-secret-token")
    refute String.contains?(inspect(error), "https://env.invalid")
  end

  test "redaction removes env-derived values from receipts" do
    receipt =
      CfCore.Redaction.redact(
        %{
          status: :failed,
          provider_error: "token env-secret-token rejected for https://env.invalid"
        },
        ["env-secret-token", "https://env.invalid"]
      )

    rendered = inspect(receipt)

    refute String.contains?(rendered, "env-secret-token")
    refute String.contains?(rendered, "https://env.invalid")
    assert String.contains?(rendered, "[REDACTED]")
  end
end
