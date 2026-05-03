defmodule CfCore do
  @moduledoc """
  Common Cloudflare API helpers.
  """

  def hello, do: :world

  defmodule SDP do
    @moduledoc """
    Provides helper functions for working with SDP (Session Description Protocol).
    """
    @spec generate_sdp(String.t(), keyword) :: String.t()
    def generate_sdp(sdp, _opts \\ []) do
      sdp
      |> String.replace("useinbandfec=1", "usedtx=1;useinbandfec=1")
    end
  end
end
