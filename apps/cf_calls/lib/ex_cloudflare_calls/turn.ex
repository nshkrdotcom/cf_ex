defmodule ExCloudflareCalls.TURN do
   @moduledoc """
   Manages TURN Key Interactions.
   """
    alias ExCloudflareCore.API
    alias ExCloudflareCore.Config
   require Logger


   ## TODO: for all -- why are we passing body, headers around? create for instance should have no args
   ## lets see if we can get body out of here if not needed

   ## TODO:  body = %{ ttl: 86400 } (by the caller)
   @spec create_turn_key(map(), list(map())) ::
       {:ok, map()} | {:error, String.t()}
   def create_turn_key(body, headers) do
         API.request(:post, Config.turn_key_endpoint(""), headers, body)
   end

   @spec get_turn_key(map(), list(map()), keyword) ::
     {:ok, map()} | {:error, String.t()}
  def get_turn_key(body, headers, key_id: key_id) do
       API.request(:get, Config.turn_key_endpoint("/#{key_id}"), headers, body)
   end


   @spec list_turn_keys(map(), list(map())) ::
      {:ok, map()} | {:error, String.t()}
  def list_turn_keys(body, headers) do
      API.request(:get, Config.turn_key_endpoint(""), headers, body)
   end


    @spec edit_turn_key(map(), list(map()), keyword) ::
       {:ok, map()} | {:error, String.t()}
   def edit_turn_key(body, headers, key_id: key_id) do
        API.request(:put, Config.turn_key_endpoint("/#{key_id}"), headers, body)
    end


    @spec delete_turn_key(map(), list(map()), keyword) ::
        {:ok, map()} | {:error, String.t()}
    def delete_turn_key(body, headers, key_id: key_id) do
        API.request(:delete, Config.turn_key_endpoint("/#{key_id}"), headers, body)
     end
 end
