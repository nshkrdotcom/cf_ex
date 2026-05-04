defmodule CfDurable.AuthorityGuard do
  @moduledoc """
  Fixed-literal checks for governed Durable Object authority inputs.
  """

  defmodule Error do
    @moduledoc false
    defexception [:blocked_fields, :missing_refs, :message]
  end

  @raw_fields [:binding_name, :object_id, :deployment_env, :workspace_secret, :target_credential]
  @required_refs [
    :authority_ref,
    :binding_ref,
    :target_ref,
    :attach_grant_ref,
    :target_auth_posture_ref
  ]

  @spec validate_namespace(term(), term(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def validate_namespace(name_or_refs, object_id, opts) do
    authority =
      opts
      |> Keyword.get(:governed_authority, %{})
      |> normalize_map()

    refs =
      case name_or_refs do
        value when is_map(value) -> value
        value when is_list(value) -> normalize_map(value)
        _value -> %{}
      end

    blocked =
      []
      |> add_blocked(is_binary(name_or_refs), :binding_name)
      |> add_blocked(is_binary(object_id), :object_id)
      |> add_authority_raw_fields(authority)

    missing =
      @required_refs
      |> Enum.reject(fn field ->
        present?(get_field(authority, field)) or present?(get_field(refs, field))
      end)

    if blocked == [] and missing == [] do
      {:ok,
       %{
         authority_ref: get_field(authority, :authority_ref),
         binding_ref: get_field(refs, :binding_ref) || get_field(authority, :binding_ref),
         object_ref: get_field(refs, :object_ref) || get_field(authority, :object_ref),
         target_ref: get_field(refs, :target_ref) || get_field(authority, :target_ref),
         attach_grant_ref:
           get_field(refs, :attach_grant_ref) || get_field(authority, :attach_grant_ref),
         target_auth_posture_ref:
           get_field(refs, :target_auth_posture_ref) ||
             get_field(authority, :target_auth_posture_ref)
       }}
    else
      {:error, build_error(blocked, missing)}
    end
  end

  defp add_blocked(blocked, true, field), do: blocked ++ [field]
  defp add_blocked(blocked, false, _field), do: blocked

  defp add_authority_raw_fields(blocked, authority) do
    raw_fields =
      @raw_fields
      |> Enum.filter(&present?(get_field(authority, &1)))

    Enum.uniq(blocked ++ raw_fields)
  end

  defp build_error(blocked, missing) do
    parts =
      []
      |> add_message_part(blocked, "unmanaged fields")
      |> add_message_part(missing, "missing refs")

    %Error{
      blocked_fields: blocked,
      missing_refs: missing,
      message: "Durable Object authority rejected " <> Enum.join(parts, "; ")
    }
  end

  defp add_message_part(parts, [], _label), do: parts

  defp add_message_part(parts, fields, label) do
    rendered = fields |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")
    parts ++ [label <> ": " <> rendered]
  end

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(value) when is_list(value), do: Map.new(value)
  defp normalize_map(_value), do: %{}

  defp get_field(map, field) when is_map(map) do
    Map.get(map, field) || Map.get(map, Atom.to_string(field))
  end

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?([]), do: false
  defp present?(value) when is_map(value), do: map_size(value) > 0
  defp present?(_value), do: true
end
