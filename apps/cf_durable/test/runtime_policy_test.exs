defmodule CfDurableRuntimePolicyTest do
  use ExUnit.Case, async: true

  alias CfDurable.RuntimePolicy

  test "bounds durable runtime vocabularies" do
    assert :ok = RuntimePolicy.validate_durable_state(:runtime_unavailable)

    assert {:error, {:unknown_durable_state, :half_open}} =
             RuntimePolicy.validate_durable_state(:half_open)

    assert :ok = RuntimePolicy.validate_binding_state(:governed_ref)

    assert {:error, {:unknown_binding_state, :ambient_binding}} =
             RuntimePolicy.validate_binding_state(:ambient_binding)

    assert :ok = RuntimePolicy.validate_alarm_kind(:scheduled)

    assert {:error, {:unknown_alarm_kind, :operator_supplied_alarm}} =
             RuntimePolicy.validate_alarm_kind(:operator_supplied_alarm)

    assert :ok = RuntimePolicy.validate_storage_record_kind(:object_value)

    assert {:error, {:unknown_storage_record_kind, :external_blob}} =
             RuntimePolicy.validate_storage_record_kind(:external_blob)

    assert :ok = RuntimePolicy.validate_target_mode(:governed_target)

    assert {:error, {:unknown_target_mode, :raw_runtime_target}} =
             RuntimePolicy.validate_target_mode(:raw_runtime_target)

    assert :ok = RuntimePolicy.validate_runtime_event_kind(:storage_put)

    assert {:error, {:unknown_runtime_event_kind, :runtime_supplied_event}} =
             RuntimePolicy.validate_runtime_event_kind(:runtime_supplied_event)
  end

  test "bounds public Cloudflare runtime atom dispatch" do
    assert {:ok, :namespace_lookup} = RuntimePolicy.runtime_event_kind_for_function(:binding_get)

    assert {:error, {:unknown_runtime_function, :operator_supplied_call}} =
             RuntimePolicy.runtime_event_kind_for_function(:operator_supplied_call)

    assert {:error, "Unknown Cloudflare runtime function"} =
             CfDurable.Runtime.call(:operator_supplied_call, [])
  end
end
