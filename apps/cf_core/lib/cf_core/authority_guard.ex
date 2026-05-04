defmodule CfCore.AuthorityGuard do
  @moduledoc """
  Fixed-literal checks for governed Cloudflare authority inputs.
  """

  defmodule Error do
    @moduledoc false
    defexception [:scope, :blocked_fields, :missing_refs, :message]

    @type t :: %__MODULE__{
            scope: atom(),
            blocked_fields: [atom()],
            missing_refs: [atom()],
            message: String.t()
          }
  end

  @calls_raw_fields [
    :base_url,
    :calls_api,
    :app_id,
    :calls_app_id,
    :app_token,
    :app_secret,
    :calls_app_secret,
    :turn_key_id,
    :turn_api_token,
    :headers,
    :authorization,
    :workspace_secret,
    :target_credential
  ]

  @calls_required_refs [
    :authority_ref,
    :base_url_ref,
    :app_id_ref,
    :app_token_ref,
    :target_ref,
    :attach_grant_ref,
    :target_auth_posture_ref
  ]

  @doc """
  Validates an options keyword or map containing `:governed_authority`.
  """
  @spec validate_calls_authority(keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def validate_calls_authority(opts) when is_list(opts) or is_map(opts) do
    opts
    |> normalize_map()
    |> fetch_governed_authority()
    |> validate_governed_authority(:cloudflare_calls)
  end

  @doc """
  Validates a Cloudflare config value when it carries governed authority refs.
  """
  @spec validate_config(term()) :: :ok | {:error, Error.t()}
  def validate_config(config) when is_map(config) do
    authority = get_field(config, :governed_authority)

    if authority_present?(authority) do
      blocked =
        @calls_raw_fields
        |> Enum.filter(&present?(get_field(config, &1)))

      with {:ok, _authority} <- validate_governed_authority(authority, :cloudflare_calls) do
        if blocked == [] do
          :ok
        else
          {:error, build_error(:cloudflare_calls, blocked, [])}
        end
      end
    else
      :ok
    end
  end

  def validate_config(_config), do: :ok

  defp validate_governed_authority(nil, _scope), do: {:ok, %{mode: :standalone}}
  defp validate_governed_authority([], _scope), do: {:ok, %{mode: :standalone}}

  defp validate_governed_authority(authority, scope)
       when is_list(authority) or is_map(authority) do
    authority = normalize_map(authority)

    blocked =
      @calls_raw_fields
      |> Enum.filter(&present?(get_field(authority, &1)))

    missing =
      @calls_required_refs
      |> Enum.reject(&present?(get_field(authority, &1)))

    if blocked == [] and missing == [] do
      {:ok,
       %{
         authority_ref: get_field(authority, :authority_ref),
         base_url_ref: get_field(authority, :base_url_ref),
         app_id_ref: get_field(authority, :app_id_ref),
         app_token_ref: get_field(authority, :app_token_ref),
         turn_key_ref: get_field(authority, :turn_key_ref),
         turn_token_ref: get_field(authority, :turn_token_ref),
         target_ref: get_field(authority, :target_ref),
         attach_grant_ref: get_field(authority, :attach_grant_ref),
         target_auth_posture_ref: get_field(authority, :target_auth_posture_ref)
       }}
    else
      {:error, build_error(scope, blocked, missing)}
    end
  end

  defp validate_governed_authority(_authority, scope) do
    {:error, build_error(scope, [:governed_authority], @calls_required_refs)}
  end

  defp build_error(scope, blocked, missing) do
    parts =
      []
      |> add_message_part(blocked, "unmanaged fields")
      |> add_message_part(missing, "missing refs")

    %Error{
      scope: scope,
      blocked_fields: blocked,
      missing_refs: missing,
      message: "Governed Cloudflare authority rejected " <> Enum.join(parts, "; ")
    }
  end

  defp add_message_part(parts, [], _label), do: parts

  defp add_message_part(parts, fields, label) do
    rendered = fields |> Enum.map(&Atom.to_string/1) |> Enum.join(", ")
    parts ++ [label <> ": " <> rendered]
  end

  defp fetch_governed_authority(opts) do
    get_field(opts, :governed_authority)
  end

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(value) when is_list(value), do: Map.new(value)

  defp get_field(map, field) when is_map(map) do
    Map.get(map, field) || Map.get(map, Atom.to_string(field))
  end

  defp present?(value), do: not empty?(value)

  defp authority_present?(value), do: not empty?(value)

  defp empty?(nil), do: true
  defp empty?(""), do: true
  defp empty?([]), do: true
  defp empty?(value) when is_map(value), do: map_size(value) == 0
  defp empty?(_value), do: false
end
