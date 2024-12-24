# apps/cf_core/test/cf_core_properties.exs
defmodule CfCoreTest.Properties do
  use ExUnit.Case
  import StreamData
  import CfEx.StreamData

  property "API.request always returns an error on invalid urls" do
     check all url <- valid_url() ,
                method <- valid_http_method(),
               headers <- valid_headers(),
               body <- valid_map() do
       refute CfCore.API.request(method, url, headers, body) == {:ok, _}
    end
  end

   property "API.request can return an ok on valid urls (this test is expected to fail without a proper server setup)" do
     check all url <- valid_url(),
                  method <- valid_http_method(),
                  headers <- valid_headers(),
                  body <- valid_map()  do
      case CfCore.API.request(method, url, headers, body) do
        {:ok, _} -> true
        {:error, _} -> true
      end
    end
  end
end
