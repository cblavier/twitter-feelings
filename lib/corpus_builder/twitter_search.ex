defmodule CorpusBuilder.TwitterSearch do

  alias CorpusBuilder.TweetProcessor,     as: Processor
  alias CorpusBuilder.TwitterRateLimiter, as: RateLimiter
  alias CorpusBuilder.TweetStore,         as: TweetStore

  @page_size 100

  def search(lang, mood, query_count) do
    max_id = inner_search([q: query(lang, mood), count: @page_size])
    if query_count > 1, do: search(lang, mood, max_id, query_count - 1)
    :ok
  end

  def search(lang, mood, max_id, query_count) do
    max_id = inner_search([q: query(lang, mood), count: @page_size, max_id: max_id])
    if query_count > 1, do: search(lang, mood, max_id, query_count - 1)
    :ok
  end

  # private

  defp inner_search(params) do
    RateLimiter.handle_rate_limit(fn ->
      parsed_params = ExTwitter.Parser.parse_request_params(params)
      json = ExTwitter.API.Base.request(:get, "1.1/search/tweets.json", parsed_params)
      Task.start_link(fn -> process_search_output(json) end)
      new_max_id(json)
    end)
  end

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
