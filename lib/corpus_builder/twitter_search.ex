defmodule CorpusBuilder.TwitterSearch do

  use GenServer

  alias CorpusBuilder.TweetProcessor,     as: Processor
  alias CorpusBuilder.TwitterRateLimiter, as: RateLimiter
  alias CorpusBuilder.TweetStore,         as: TweetStore

  @page_size 100

  def start_link do
    GenServer.start_link(__MODULE__, {:no_max_id, 0}, name: __MODULE__)
  end

  def search_and_store(lang, mood, query_count) do
    GenServer.cast(__MODULE__, {:set_query_count, query_count})
    search_and_store_loop(lang, mood)
  end

  # server implementation

  def handle_call({:search_and_store, _lang, _mood}, _from, {max_id, 0}) do
    {:reply, :stop, {max_id, 0}}
  end

  def handle_call({:search_and_store, lang, mood}, _from, {max_id, query_count}) do
    max_id = RateLimiter.handle_rate_limit(fn ->
      parsed_params = search_params(lang, mood, max_id) |> ExTwitter.Parser.parse_request_params
      json = ExTwitter.API.Base.request(:get, "1.1/search/tweets.json", parsed_params)
      Task.start_link(fn -> process_search_output(json) end)
      new_max_id(json)
    end)
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

  defp search_params(lang, mood, :no_max_id), do: [q: query(lang, mood), count: @page_size]
  defp search_params(lang, mood, max_id),     do: [q: query(lang, mood), count: @page_size, max_id: max_id]

  defp query(lang, :positive), do: "lang:#{Atom.to_string(lang)} :)"
  defp query(lang, :negative), do: "lang:#{Atom.to_string(lang)} :("

  defp process_search_output(json) do
    get_in(json, ["statuses"])
      |> Stream.map(&(&1["text"]))
      |> Stream.filter(&Processor.valid?/1)
      |> Stream.map(&Processor.normalize/1)
      |> Enum.map(&(TweetStore.store_tweet(&1)))
  end

  defp new_max_id(json) do
    next_results = get_in(json, ["search_metadata", "next_results"])
    Regex.named_captures(~r/max_id=(?<max_id>\w+)&/, next_results)["max_id"]
      |> String.to_integer
  end

end
