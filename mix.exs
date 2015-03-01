defmodule TwitterFeelings.Mixfile do
  use Mix.Project

  def project do
    [app: :twitter_feelings,
     version: "0.0.1",
     elixir: "~> 1.0",
     escript: escript_config,
     deps: deps]
  end

  def application do
    [
      applications: [:kernel, :stdlib, :logger, :inets, :ssl, :redis_pool],
      env: [pools: [tf_pool: [size: 12, max_overflow: 20, host: "127.0.0.1", port: 6379]]]
    ]
  end

  defp deps do
    [
      { :oauth, github: "tim/erlang-oauth" },
      { :extwitter, "~> 0.2" },
      { :timex, "~> 0.13.3" },
      { :redis_pool, git: "https://github.com/le0pard/redis_pool" },
      { :mock, "0.1.0", only: :test }
    ]
  end

  defp escript_config do
    [ main_module: TwitterFeelings ]
  end

end
