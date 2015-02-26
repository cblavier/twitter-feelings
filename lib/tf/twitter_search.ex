defmodule TF.TwitterSearch do

  alias TF.TweetProcessor,     as: Processor
  alias TF.TwitterRateLimiter, as: RateLimiter

  @page_size 100

  def search(query, search_count) do
    max_id = inner_search([q: query, count: @page_size])
    if search_count > 1, do: search(query, max_id, search_count - 1)
    :ok
  end

  def search(query, max_id, search_count) do
    max_id = inner_search([q: query, count: @page_size, max_id: max_id])
    if search_count > 1, do: search(query, max_id, search_count - 1)
    :ok
  end

  defp inner_search(params) do
    RateLimiter.rate_limit(fn ->
      parsed_params = ExTwitter.Parser.parse_request_params(params)
      {:ok, json} = ExTwitter.API.Base.request(:get, "1.1/search/tweets.json", parsed_params)
      Task.async(fn -> process_search_output(json) end)
      new_max_id(json)
    end)
  end

  defp process_search_output(json) do
    get_in(json, ["statuses"])
      |> Stream.map(&(&1["text"]))
      |> Stream.filter(&Processor.valid?/1)
      |> Stream.map(&Processor.process/1)
      |> Enum.map(&TF.TweetStore.store/1)
  end

  defp new_max_id(json) do
    next_results = get_in(json, ["search_metadata", "next_results"])
    Regex.named_captures(~r/max_id=(?<max_id>\w+)&/, next_results)["max_id"]
      |> String.to_integer
  end

end
