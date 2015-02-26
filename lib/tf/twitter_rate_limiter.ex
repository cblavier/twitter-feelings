defmodule TF.TwitterRateLimiter do

  use Timex

  # Check rate limit to the twitter search api
  # - if rate limitation is ok, callback is called
  # - if rate limitation is exhausted, process will sleep until
  #   it is reset and callback will be called after
  def rate_limit(fun) do
    search_limit = get_twitter_rate_limit
    if search_limit["remaining"] > 0 do
      fun.()
    else
      now = Date.convert(Date.now, :secs)
      reset_time = search_limit["reset"]
      :timer.sleep((reset_time - now) * 1000)
      rate_limit(fun)
    end
  end

  defp get_twitter_rate_limit do
    parsed_params = ExTwitter.Parser.parse_request_params([resources: "search"])
    {:ok, json} = ExTwitter.API.Base.request(:get, "1.1/application/rate_limit_status.json", parsed_params)
    get_in(json, ["resources", "search", "/search/tweets"])
  end

end
