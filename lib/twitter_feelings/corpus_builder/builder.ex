defmodule TwitterFeelings.CorpusBuilder.Builder do

  use GenServer
  use TwitterFeelings.Common.Stashable, stash_name: :builder_stash

  require Logger

  alias TwitterFeelings.CorpusBuilder.TweetProcessor,     as: Processor
  alias TwitterFeelings.CorpusBuilder.TwitterSearch,      as: TwitterSearch
  alias TwitterFeelings.CorpusBuilder.TweetStore,         as: TweetStore

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Runs query_count calls on TwitterSearch, with given lang / mood.
  # Tweets are filtered, normalized and then stored into a Redis set.
  def build_corpus(lang, mood, query_count) do
    GenServer.cast(__MODULE__, {:set_query_count, query_count})
    search_and_store_loop(lang, mood)
  end

  # server implementation

  def handle_call({:search_and_store, _lang, _mood}, _from, {max_id, 0}) do
    {:reply, :stop, {max_id, 0}}
  end

  def handle_call({:search_and_store, lang, mood}, _from, {max_id, query_count}) do
    Logger.debug("searching tweets for lang:#{lang}, mood:#{mood}. Still #{query_count} queries to run.")
    {:ok, statuses, max_id} = TwitterSearch.search(lang, mood, max_id)
    Task.start_link fn ->
      process_statuses(statuses)
    end
    {:reply, :ok, {max_id, query_count - 1}}
  end

  def handle_cast({:set_query_count, query_count}, {max_id, _}) do
    {:noreply, {max_id, query_count}}
  end

  # private

  defp search_and_store_loop(lang, mood) do
    result = GenServer.call(__MODULE__, {:search_and_store, lang, mood}, :infinity)
    case result do
    :ok -> search_and_store_loop(lang, mood)
    :stop -> :ok
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

