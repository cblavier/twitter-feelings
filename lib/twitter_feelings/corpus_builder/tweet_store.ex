defmodule TwitterFeelings.CorpusBuilder.TweetStore do

  use GenServer
  use TwitterFeelings.Common.Stashable, stash_name: :tweet_store_stash

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def set_lang(lang) do
    GenServer.cast(__MODULE__, {:set_lang, lang})
  end

  def set_mood(mood) do
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

  def handle_cast({:store_tweet, _}, {:no_lang, _}), do: raise "no lang set on TweetStore"
  def handle_cast({:store_tweet, _}, {_, :no_mood}), do: raise "no mood set on TweetStore"
  def handle_cast({:store_tweet, tweet}, {lang, mood}) do
    Task.start_link fn ->
      RedisPool.q({:global, :tf_pool}, ["SADD", redis_set_key(lang, mood), tweet])
    end
    {:noreply, {lang, mood}}
  end

  # private

  defp redis_set_key(lang, mood) do
    "tf-corpus-#{lang}-#{mood}"
  end

end