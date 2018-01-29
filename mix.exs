defmodule UeberauthDisqus.Mixfile do
  use Mix.Project

  @project_description """
  Disqus strategy for Überauth
  """

  @version "0.0.1"
  @source_url "https://github.com/cgorshing/ueberauth_disqus"

  def project do
    [app: :ueberauth_disqus,
     version: @version,
     elixir: "~> 1.3 or ~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     docs: docs(),
     description: @project_description,
     source_url: @source_url,
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :plug, :ueberauth, :oauth2]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:ueberauth, "~> 0.4"},
     {:oauth2, "~> 0.9.1"},

     {:tesla, "~> 0.9.0"},
     {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md": [title: "README"]
      ]
    ]
  end

  defp package do
    [
     name: :ueberauth_disqus,
     maintainers: ["Chad Gorshing"],
     licenses: ["MIT"],
     links: %{
       "Github" => @source_url
     }
    ]
  end
end
