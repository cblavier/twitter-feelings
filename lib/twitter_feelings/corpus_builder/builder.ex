defmodule TwitterFeelings.CorpusBuilder.Builder do

  use GenServer
  use TwitterFeelings.Common.GenServer.Stashable, stash_name: :builder_stash
  use TwitterFeelings.Common.GenServer.Startable
  use TwitterFeelings.Common.GenServer.Stoppable

  require Logger

  alias TwitterFeelings.CorpusBuilder.TweetProcessor,     as: Processor
  alias TwitterFeelings.CorpusBuilder.TwitterSearch,      as: TwitterSearch
  alias TwitterFeelings.CorpusBuilder.TweetStore,         as: TweetStore

  # Calls TwitterSearch with given lang / mood until
  # Tweets are filtered, normalized and then stored into a Redis set.
  def build_corpus(lang, mood, tweet_count) do
    TweetStore.set_lang_and_mood(lang, mood)
    search_and_store_loop(lang, mood, tweet_count)
  end

  # server implementation

  def handle_call({:search_and_store, _lang, _mood}, _from, :no_more_max_id) do
    Logger.debug("Twitter search exhausted, stopping.")
    {:reply, :stop, :no_more_max_id}
  end

  def handle_call({:search_and_store, lang, mood}, _from, max_id) do
    {:ok, statuses, new_max_id} = TwitterSearch.search(lang, mood, max_id)
    Task.start_link fn ->
      process_statuses(statuses)
    end
    {:reply, :ok, new_max_id}
  end

  # private

  defp search_and_store_loop(lang, mood, tweet_count) do
    actual_tweet_count = TweetStore.tweet_count
    if actual_tweet_count >= tweet_count do
      Logger.debug("#{actual_tweet_count} tweets stored, stopping.")
      :ok
    else
      Logger.debug("Searching #{lang} tweets with #{mood} mood. #{actual_tweet_count} tweets stored.")
      result = GenServer.call(__MODULE__, {:search_and_store, lang, mood}, :infinity)
      case result do
      :ok   -> search_and_store_loop(lang, mood, tweet_count)
      :stop -> :ok
      end
    end
  end

  defp process_statuses(statuses) do
    statuses
      |> Stream.map(&(&1["text"]))
      |> Stream.filter(&Processor.valid?/1)
      |> Stream.map(&Processor.normalize/1)
      |> Enum.map(&(TweetStore.store_tweet(&1)))
  end

end

