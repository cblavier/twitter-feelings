defmodule TwitterFeelings.Common.Redis do

  def run(query) do
    RedisPool.q(pool, query)
  end

  def load_script(script) do
    {:ok, sha} = run(["SCRIPT", "LOAD", script])
    sha
  end

  def corpus_key(lang, mood),         do: env_prefix("tf-corpus-#{lang}-#{mood}")
  def count_key(lang, mood, token),   do: env_prefix("tf-count-#{lang}-#{mood}-#{token}")
  def count_key(lang, token),         do: env_prefix("tf-count-#{lang}-all-#{token}")
  def positive_prob_key(lang, token), do: env_prefix("tf-positive-prob-#{lang}-#{token}")

  # private

  defp pool, do: {:global, :tf_pool}

  defp env_prefix(key) do
    if Application.get_env(TwitterFeelings, :test) do
      "test-#{key}"
    else
      key
    end
  end

end