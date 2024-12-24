defmodule CfCalls.Metrics do
  @moduledoc """
  Handles rate limiting, quotas, and metrics for Cloudflare Calls API.

  This module provides:
  - Rate limit tracking and enforcement
  - API quota management
  - Telemetry integration
  - Error rate monitoring
  """

  require Logger
  alias CfCore.Config

  # Cloudflare API Limits
  @api_rate_limit 50          # calls per second per session
  @max_tracks_per_call 64     # maximum tracks per API call
  @max_sessions_per_app 1000  # maximum concurrent sessions per app
  @track_timeout 30           # seconds before inactive tracks are closed

  @type metric_name :: :api_calls | :track_count | :error_rate | :latency
  @type metric_value :: number()
  @type rate_limit_info :: %{
    limit: pos_integer(),
    remaining: non_neg_integer(),
    reset_at: DateTime.t()
  }

  @doc """
  Tracks an API call and enforces rate limits.
  Returns :ok if the call is allowed, or {:error, reason} if rate limited.
  """
  @spec track_api_call(Config.t(), Types.session_id()) :: :ok | {:error, String.t()}
  def track_api_call(config, session_id) do
    case get_rate_limit_info(config, session_id) do
      %{remaining: remaining} when remaining > 0 ->
        update_rate_limit(config, session_id)
        :ok
      _ ->
        {:error, "Rate limit exceeded"}
    end
  end

  @doc """
  Validates track count against limits.
  """
  @spec validate_track_count(non_neg_integer()) :: :ok | {:error, String.t()}
  def validate_track_count(count) when is_integer(count) do
    if count <= @max_tracks_per_call do
      :ok
    else
      {:error, "Exceeds maximum tracks per call (#{@max_tracks_per_call})"}
    end
  end

  @doc """
  Records metrics for telemetry.
  """
  @spec record_metric(metric_name(), metric_value(), keyword()) :: :ok
  def record_metric(name, value, metadata \\ []) do
    :telemetry.execute(
      [:cf_calls, :api, name],
      %{value: value},
      Map.new(metadata)
    )
    :ok
  end

  @doc """
  Returns current rate limit information for a session.
  """
  @spec get_rate_limit_info(Config.t(), Types.session_id()) :: rate_limit_info()
  def get_rate_limit_info(_config, session_id) do
    # In a real implementation, this would check Redis or another store
    # For now, we return a default value
    %{
      limit: @api_rate_limit,
      remaining: @api_rate_limit,
      reset_at: DateTime.utc_now() |> DateTime.add(1, :second)
    }
  end

  @doc """
  Returns the configured limits for the API.
  """
  @spec get_limits() :: %{
    api_rate_limit: pos_integer(),
    max_tracks_per_call: pos_integer(),
    max_sessions_per_app: pos_integer(),
    track_timeout: pos_integer()
  }
  def get_limits do
    %{
      api_rate_limit: @api_rate_limit,
      max_tracks_per_call: @max_tracks_per_call,
      max_sessions_per_app: @max_sessions_per_app,
      track_timeout: @track_timeout
    }
  end

  @doc """
  Records error metrics and logs the error.
  """
  @spec record_error(atom(), String.t(), keyword()) :: :ok
  def record_error(type, message, metadata \\ []) do
    Logger.error("Cloudflare Calls error: #{message}",
      type: type,
      metadata: metadata
    )

    record_metric(:error_rate, 1, [error_type: type] ++ metadata)
    :ok
  end

  @doc """
  Records latency metrics for API calls.
  """
  @spec record_latency(atom(), integer(), keyword()) :: :ok
  def record_latency(operation, latency_ms, metadata \\ []) do
    record_metric(:latency, latency_ms, [operation: operation] ++ metadata)
    :ok
  end

  # Private Helpers

  defp update_rate_limit(_config, _session_id) do
    # In a real implementation, this would update Redis or another store
    :ok
  end

  # Telemetry Event Handlers

  def handle_api_call(event_name, measurements, metadata, _config) do
    Logger.debug("API call metrics",
      event: event_name,
      measurements: measurements,
      metadata: metadata
    )
  end

  def handle_error(event_name, measurements, metadata, _config) do
    Logger.warn("Error metrics",
      event: event_name,
      measurements: measurements,
      metadata: metadata
    )
  end

  def handle_latency(event_name, measurements, metadata, _config) do
    Logger.debug("Latency metrics",
      event: event_name,
      measurements: measurements,
      metadata: metadata
    )
  end

  # Attach telemetry handlers
  def attach_telemetry do
    :telemetry.attach(
      "cf-calls-api-handler",
      [:cf_calls, :api, :api_calls],
      &handle_api_call/4,
      nil
    )

    :telemetry.attach(
      "cf-calls-error-handler",
      [:cf_calls, :api, :error_rate],
      &handle_error/4,
      nil
    )

    :telemetry.attach(
      "cf-calls-latency-handler",
      [:cf_calls, :api, :latency],
      &handle_latency/4,
      nil
    )
  end
end
