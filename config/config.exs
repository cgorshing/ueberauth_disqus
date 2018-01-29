use Mix.Config

if Mix.env == :test do

  config :ueberauth, Ueberauth,
    providers: [
      disqus: {Ueberauth.Strategy.Disqus, []}
    ]

  config :ueberauth, Ueberauth.Strategy.Disqus.OAuth,
    client_id: System.get_env("DISQUS_CONSUMER_KEY"),
    client_secret: System.get_env("DISQUS_CONSUMER_SECRET")
end
