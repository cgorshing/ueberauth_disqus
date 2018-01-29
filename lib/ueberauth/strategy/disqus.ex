defmodule Ueberauth.Strategy.Disqus do
  require Logger

  @moduledoc """
  Disqus Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    default_scope: "read",
    oauth2_module: Ueberauth.Strategy.Disqus.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  alias Ueberauth.Strategy.Disqus.OAuth

  @doc """
  Handles initial request for Disqus authentication

  The initial entry point from ueberauth
  """
  def handle_request!(conn) do
    Logger.warn "handle_request!"
    scopes = conn.params["scope"] || option(conn, :default_scope) || "read"
    send_redirect_uri = Keyword.get(options(conn), :send_redirect_uri, true)

    opts = if send_redirect_uri do
        [redirect_uri: callback_url(conn), scope: scopes]
      else
        [scope: scopes]
    end

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Disqus
  """
  def handle_callback!(%Plug.Conn{params: %{"oauth_token" => oauth_token, "oauth_token_secret" => oauth_token_secret, "oauth_verifier" => oauth_verifier}} = conn) do
    IO.puts "+++ handle_callback! with params"

    case OAuth.access_token(oauth_token, oauth_token_secret, oauth_verifier) do
      {:ok, access_token} -> fetch_user(conn, access_token)
      {:error, reason} -> set_errors!(conn, [error("access_error", reason)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    IO.puts "+++ handle_callback! with just conn"
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    IO.puts "+++ handle_cleanup!"
    conn
    |> put_private(:disqus_user_map, nil)
    |> put_private(:disqus_tokens, nil)
    |> put_session(:disqus_request_token, nil)
    |> put_session(:disqus_request_token_secret, nil)
  end

  @doc """
  Fetches the uid/kaid field from the response
  """
  def uid(conn) do
    IO.puts "+++ uid"
    conn.private.disqus_user_map["kaid"]
  end

  @doc """
  Includes the credentials from the Disqus response
  """
  def credentials(conn) do
    IO.puts "+++ credentials"
    %Credentials{
      token: conn.private.disqus_tokens["oauth_token"],
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    IO.puts "+++ info(conn)"

    m = conn.private.disqus_user_map

    #TODO We really need the kaid
    %Ueberauth.Auth.Info{
      name: m["nickname"],
      nickname: m["username"],
      #email: m["email"] || Enum.find(user["emails"] || [], &(&1["primary"]))["email"],
      email: m["email"],
      #kaid: m["kaid"],
      image: m["avatar_url"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the callback
  """
  def extra(conn) do
    IO.puts "+++ extra(conn)"
    %Extra{
      raw_info: %{
        token: conn.private.disqus_tokens["oauth_token"],
        user: conn.private.disqus_user_map
      }
    }
  end

  defp fetch_user(conn, tokens) do
    case OAuth.get_info(tokens) do
      {:ok, person} ->
        conn
        |> put_private(:disqus_user_map, person)
        |> put_private(:disqus_tokens, tokens)
      {:error, reason} ->
        set_errors!(conn, [error("get_info", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
