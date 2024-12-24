defmodule CfCallsTest.Properties do
  @moduledoc """
  Properties for testing CfCalls functionality.
  """
  use ExUnit.Case
  import StreamData
  import CfEx.StreamData
  alias CfCore.Config

  property "Session.new_session always returns an error with invalid app id" do
    check all app_id <- string(:alphanumeric, min_length: 5, max_length: 10),
    app_token <- string(:alphanumeric, min_length: 20, max_length: 30) do
      refute CfCalls.Session.new_session(app_id, app_token,  base_url: "http://localhost:8888") == {:ok, _}
    end
  end

  property "Session.new_tracks always returns an error with invalid data" do
    check all app_id <- string(:alphanumeric, min_length: 5, max_length: 10),
    app_token <- string(:alphanumeric, min_length: 20, max_length: 30),
    session_id <- valid_session_id(),
    tracks <- list_of(valid_map()) do
      refute CfCalls.Session.new_tracks(session_id, app_id, tracks, app_token: app_token, base_url: "http://localhost:8888") == {:ok, _}
    end
  end
end
