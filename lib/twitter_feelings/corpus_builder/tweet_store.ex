defmodule TwitterFeelings.CorpusBuilder.TweetStore do

  use GenServer
  use TwitterFeelings.Common.GenServer.Stashable, stash_name: :tweet_store_stash
  use TwitterFeelings.Common.GenServer.Startable
  use TwitterFeelings.Common.GenServer.Stoppable

  alias TwitterFeelings.Common.Redis

  def set_lang_and_mood(lang, mood) do
    GenServer.cast(__MODULE__, {:set_lang, lang})
    GenServer.cast(__MODULE__, {:set_mood, mood})
  end

  def store_tweet(tweet) do
    GenServer.cast(__MODULE__, {:store_tweet, tweet})
  end

  def tweet_count do
    {:ok, count} = GenServer.call(__MODULE__, :tweet_count)
    String.to_integer(count)
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
    Task.start_link(fn -> store_tweet(Redis.corpus_key(lang, mood), tweet) end)
    {:noreply, {lang, mood}}
  end

  def handle_call(:tweet_count, _from, {lang, mood}) do
    count = Redis.run(["SCARD", Redis.corpus_key(lang, mood)])
    {:reply, count, {lang, mood}}
  end

  # private

  defp store_tweet(key, tweet) do
    Redis.run(["SADD", key, tweet])
  end

end