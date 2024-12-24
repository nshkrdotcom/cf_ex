# test/support/stream_data.ex
defmodule CfEx.StreamData do
  import StreamData

  def valid_sdp() do
    string(:ascii, min_length: 20, max_length: 1000)
    |> such_that(fn sdp -> String.starts_with?(sdp, "v=") end)
  end

  def valid_session_id() do
    string(:alphanumeric, min_length: 10, max_length: 30)
  end


  def valid_track_name() do
    string(:alphanumeric, min_length: 5, max_length: 20)
  end

    def valid_url() do
      string(:ascii, min_length: 20, max_length: 200)
      |> such_that(fn url ->
        try do
          URI.parse(url)
          true
        rescue
          _ -> false
        end
      end)
    end


    def valid_http_method() do
      one_of([
       "GET",
       "POST",
        "PUT",
        "PATCH",
        "DELETE"
      ])
    end

  def valid_map() do
       map(string(:alphanumeric, min_length: 3, max_length: 10), any())
  end

  def valid_headers() do
     list(tuple(string(:alphanumeric, min_length: 3, max_length: 10),string(:ascii, min_length: 3, max_length: 20)))
  end

  # Add more shared generators here
end
