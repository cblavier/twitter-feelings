defmodule TwitterFeelings.Common.Redis do

  def run(query) do
    RedisPool.q(pool, query)
  end

  def load_script(script) do
    {:ok, sha} = run(["SCRIPT", "LOAD", script])
    sha
  end

  def clear_keys(pattern) do
    run(["EVAL", delete_keys_script, 0, pattern])
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

  defp delete_keys_script do
    """
    for _,k in ipairs(redis.call('keys', ARGV[1])) do
      redis.call('del', k)
    end
    """
  end

end