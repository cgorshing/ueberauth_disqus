# Überauth Disqus

> Disqus strategy for Überauth.

_Note_: Sessions are required for this strategy.

[Source code is available on Github](https://github.com/cgorshing/ueberauth_disqus).<br/>
[Package is available on hex](https://hex.pm/packages/ueberauth_disqus).

## Installation

1. Register your app at [Disqus](https://disqus.com/api/applications/).

1. Add `:ueberauth_disqus` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_disqus, "~> 0.0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_disqus]]
    end
    ```

1. Add Disqus to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        disqus: {Ueberauth.Strategy.Disqus, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Disqus.OAuth,
      consumer_key: System.get_env("DISQUS_CONSUMER_KEY"),
      consumer_secret: System.get_env("DISQUS_CONSUMER_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/disqus

Possible scope values are read, write, email, and admin. See
https://disqus.com/api/docs/auth/

## License

Please see [LICENSE](https://github.com/cgorshing/ueberauth_disqus/blob/master/LICENSE) for licensing details.
