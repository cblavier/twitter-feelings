defmodule CorpusBuilder.TweetStore do

  def store(tweet, lang, mood) do
    RedisPool.q({:global, :tf_pool}, ["SADD", redis_set_key(lang, mood), tweet])
  end

  defp redis_set_key(lang, mood) do
    "tf-corpus-#{Atom.to_string(lang)}-#{Atom.to_string(mood)}"
  end

end