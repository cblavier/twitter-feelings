defmodule TwitterFeelings.CorpusBuilder.TweetStore do

  use GenServer
  use TwitterFeelings.Common.Stashable, stash_name: :tweet_store_stash
  use TwitterFeelings.Common.Startable
  use TwitterFeelings.Common.Stoppable

  def set_lang_and_mood(lang, mood) do
    GenServer.cast(__MODULE__, {:set_lang, lang})
    GenServer.cast(__MODULE__, {:set_mood, mood})
  end

  def store_tweet(tweet) do
    GenServer.cast(__MODULE__, {:store_tweet, tweet})
  end

  # server implementation

  def handle_cast({:set_lang, lang}, {_, mood}) do
    {:noreply, {lang, mood}}
  end

  def handle_cast({:set_mood, mood}, {lang, _}) do
    {:noreply, {lang, mood}}
  end

  def handle_cast({:store_tweet, _}, {:no_lang, mood}), do: {:stop, :no_lang_set, {:no_lang, mood}}
  def handle_cast({:store_tweet, _}, {lang, :no_mood}), do: {:stop, :no_mood_set, {lang, :no_mood}}

  def handle_cast({:store_tweet, tweet}, {lang, mood}) do
    Task.start_link(fn -> store_tweet(redis_set_key(lang, mood), tweet) end)
    {:noreply, {lang, mood}}
  end

  # private

  defp store_tweet(key, tweet) do
    redis_query(["SADD", key, tweet])
  end

  defp redis_query(query) do
    RedisPool.q({:global, :tf_pool}, query)
  end

  defp redis_set_key(lang, mood) do
    "tf-corpus-#{lang}-#{mood}"
  end

end