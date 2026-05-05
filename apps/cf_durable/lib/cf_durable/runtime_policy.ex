defmodule CfDurable.RuntimePolicy do
  @moduledoc """
  Bounded Durable Object runtime vocabulary for CF Ex.
  """

  @durable_states [:unmaterialized, :materialized, :runtime_unavailable]
  @binding_states [:standalone_binding, :governed_ref, :not_materialized]
  @alarm_kinds [:scheduled, :cancelled, :fired]
  @storage_record_kinds [:object_value, :object_list, :object_delete]
  @target_modes [:standalone_runtime, :governed_target]
  @runtime_event_kinds [
    :namespace_lookup,
    :storage_put,
    :storage_get,
    :storage_list,
    :storage_delete
  ]

  @runtime_functions %{
    binding_get: :namespace_lookup,
    durable_object_storage_put: :storage_put,
    durable_object_storage_get: :storage_get,
    durable_object_storage_list: :storage_list,
    durable_object_storage_delete: :storage_delete
  }

  @spec validate_durable_state(term()) :: :ok | {:error, {:unknown_durable_state, term()}}
  def validate_durable_state(state) when state in @durable_states, do: :ok
  def validate_durable_state(state), do: {:error, {:unknown_durable_state, state}}

  @spec validate_binding_state(term()) :: :ok | {:error, {:unknown_binding_state, term()}}
  def validate_binding_state(state) when state in @binding_states, do: :ok
  def validate_binding_state(state), do: {:error, {:unknown_binding_state, state}}

  @spec validate_alarm_kind(term()) :: :ok | {:error, {:unknown_alarm_kind, term()}}
  def validate_alarm_kind(kind) when kind in @alarm_kinds, do: :ok
  def validate_alarm_kind(kind), do: {:error, {:unknown_alarm_kind, kind}}

  @spec validate_storage_record_kind(term()) ::
          :ok | {:error, {:unknown_storage_record_kind, term()}}
  def validate_storage_record_kind(kind) when kind in @storage_record_kinds, do: :ok

  def validate_storage_record_kind(kind),
    do: {:error, {:unknown_storage_record_kind, kind}}

  @spec validate_target_mode(term()) :: :ok | {:error, {:unknown_target_mode, term()}}
  def validate_target_mode(mode) when mode in @target_modes, do: :ok
  def validate_target_mode(mode), do: {:error, {:unknown_target_mode, mode}}

  @spec validate_runtime_event_kind(term()) ::
          :ok | {:error, {:unknown_runtime_event_kind, term()}}
  def validate_runtime_event_kind(kind) when kind in @runtime_event_kinds, do: :ok

  def validate_runtime_event_kind(kind),
    do: {:error, {:unknown_runtime_event_kind, kind}}

  @spec runtime_event_kind_for_function(term()) ::
          {:ok, atom()} | {:error, {:unknown_runtime_function, term()}}
  def runtime_event_kind_for_function(function) when is_atom(function) do
    case Map.fetch(@runtime_functions, function) do
      {:ok, event_kind} -> {:ok, event_kind}
      :error -> {:error, {:unknown_runtime_function, function}}
    end
  end

  def runtime_event_kind_for_function(function),
    do: {:error, {:unknown_runtime_function, function}}
end
