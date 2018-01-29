defmodule Ueberauth.Strategy.Disqus.OAuth do
  use Tesla
  plug Tesla.Middleware.DebugLogger

  use OAuth2.Strategy

  require Logger

  #"site" is used by the OAuth2 Client for url resolution
  #Stack Exchange also uses a site param, and uses of this library
  #might be more knowledgable about Stack Exchange's usage rather than
  #the OAuth2 usage. So "site" here is for Stack Exchange and "server_url"
  #is renamed in client/1 to "site"
  @defaults [
    strategy: __MODULE__,
    server_url: "https://disqus.com",
    endpoint: "/"
  ]

  @moduledoc """

  Add `consumer_key` and `consumer_secret` to your configuration:

  config :ueberauth, Ueberauth.Strategy.Disqus.OAuth,
    consumer_key: System.get_env("DISQUS_CONSUMER_KEY"),
    consumer_secret: System.get_env("DISQUS_CONSUMER_SECRET"),
    redirect_uri: System.get_env("DISQUS_REDIRECT_URI")
  """

  @doc """
  Construct a client for requests to StackOverflow.
  Optionally include any OAuth2 options here to be merged with the defaults.
      Ueberauth.Strategy.Disqus.OAuth.client(redirect_uri: "http://localhost:4000/auth/disqus/callback")
  This will be setup automatically for you in `Ueberauth.Strategy.Disqus`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = config(opts)
    client_opts = config
      |> Keyword.put(:site, Keyword.get(config, :server_url))
      |> Keyword.put(:authorize_url, "/api/oauth/2.0/authorize/")

    OAuth2.Client.new(client_opts)
  end

  def access_token(token, token_secret, oauth_verifier, opts \\ []) do
    Logger.warn "disqus::access_token"

    raise RuntimeError, "Figure out what to do here"
    case response do
      %Tesla.Env{status: 200} ->
        #Convert the string form encoded body to a map
        #I don't like this, would love something else
        #https://stackoverflow.com/questions/42262115/elixir-convert-list-into-a-map
        {:ok, response.body
          |> String.split("&")
          |> Enum.map(fn(x) -> String.split(x, "=") end)
          |> Map.new(fn [k, v] -> {k, v} end)
        }
      error ->
        {:error, error}
    end
  end

  def access_token!(token, secret, verifier, opts \\ []) do
    Logger.warn "disqus::access_token!"
    Logger.warn "#{inspect token }"
    Logger.warn "#{inspect secret}"
    Logger.warn "#{inspect verifier}"
    Logger.warn "#{inspect opts}"

    case access_token(token, secret, verifier, opts) do
      {:ok, token} ->
        token
      error ->
        raise RuntimeError, """
        UeberauthDisqus Error

        #{inspect error}
        """
    end
  end

  def authorize_url(client, params) do
    Logger.warn "disqus::authorize_url!"

    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  #The contract provided by ueberauth is the access token, but we have two in a map
  def get_info(tokens, opts \\ []) do
    token = tokens["oauth_token"]
    token_secret = tokens["oauth_token_secret"]

    config =
      opts
      |> config()
      |> put_access_token(tokens)

    api_server = ""
    access_endpoint = ""
    creds = OAuther.credentials(consumer_key: "",
      consumer_secret: "",
      token_secret: token_secret)
    params = OAuther.sign("get", api_server <> access_endpoint,
      [{"oauth_token", token}],
      creds)

    response = Tesla.get(api_server <> access_endpoint, query: params, headers: [{"content-type", "text/plain"}])

    case response do
      %Tesla.Env{status: 200} ->
        #Convert the string form encoded body to a map
        #I don't like this, would love something else
        #https://stackoverflow.com/questions/42262115/elixir-convert-list-into-a-map
        {:ok, response.body
          |> Poison.decode!
        }
      error ->
        error
    end
  end

  defp config(opts \\ []) do

    config = :ueberauth
      |> Application.fetch_env!(__MODULE__)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)

    @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)
  end

  defp put_access_token(config, access_token) do
    tokens =
      access_token
      |> Map.take([:oauth_token, :oauth_token_secret])
      |> Keyword.new()

    Keyword.merge(config, tokens)
  end

  def request_token(opts \\ []) do
    config = config(opts)

    params = [{"oauth_callback", config[:redirect_uri]}]

    #Tesla.post("http://posttestserver.com/post.php", query: [dir: "blah"])
    #Tesla.post("http://posttestserver.com/post.php")

    creds = OAuther.credentials(consumer_key: "", consumer_secret: "")
    signed_params = OAuther.sign("post",
      "",
      params,
      creds)

    response = Tesla.request(method: :post, body: "", url: "", query: signed_params, headers: [{"content-type", "text/plain"}])

    case response do
      %Tesla.Env{status: 200} ->
        {:ok, response.body}
      error ->
        {:error, error}
    end
  end

  def request_token!(opts \\ []) do
    case request_token(opts) do
      {:ok, token} ->
        token
      error ->
        raise RuntimeError, """
        UeberauthDisqus Error

        #{inspect error}
        """
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect (key)} missing from config :ueberauth, Ueberauth.Strategy.Disqus"
    end
    config
  end
  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Disqus is not a keyword list, as expected"  end
end
