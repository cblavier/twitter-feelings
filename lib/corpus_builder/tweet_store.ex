defmodule CorpusBuilder.TweetStore do

  use GenServer

  def start_link({lang, mood}) do
    RedisPool.create_pool(:tf_pool, 30, 'localhost', 6379)
    GenServer.start_link(__MODULE__, {lang, mood}, name: __MODULE__)
  end

  def store_tweet(tweet) do
    GenServer.cast __MODULE__, {:store_tweet, tweet}
  end

  def handle_cast({:store_tweet, tweet}, {lang, mood}) do
    RedisPool.q({:global, :tf_pool}, ["SADD", redis_set_key(lang, mood), tweet])
  end

  defp redis_set_key(lang, mood) do
    "tf-corpus-#{Atom.to_string(lang)}-#{Atom.to_string(mood)}"
  end

end