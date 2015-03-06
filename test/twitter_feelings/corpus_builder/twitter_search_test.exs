defmodule TwitterFeelings.CorpusBuilder.TwitterSearchTest do

  use ExUnit.Case, async: false
  import Mock

  alias TwitterFeelings.CorpusBuilder.TwitterSearch
  alias TwitterFeelings.CorpusBuilder.TwitterRateLimiter

  setup do
    HTTPoison.start
    with_mock HTTPoison, [post!: fn(_,_,_) -> token_response end] do
      {:ok, _} = TwitterSearch.start
    end
    on_exit fn ->
      TwitterSearch.stop
    end
    {:ok, []}
  end

  test "it fetches statuses and max_id" do
    with_mock HTTPoison, [get: fn("https://api.twitter.com/1.1/search/tweets.json",_,_) -> {:ok, statuses_response} end] do
      {:ok, statuses, result_max_id} = TwitterSearch.search(:fr, :positive, :no_max_id)
      for i <- 0..2 do
         tweet_status = Enum.at(statuses, i)["text"]
         assert ^tweet_status = status(i)
      end
      assert ^result_max_id = max_id
    end
  end

  test "it throws rate_limit_errors when rate limit is reached" do
    with_mock HTTPoison, [get: fn("https://api.twitter.com/1.1/search/tweets.json",_,_) -> {:ok, rate_limit_error} end] do
      with_mock TwitterRateLimiter, [handle_rate_limit: expect_raise_exception(ExTwitter.RateLimitExceededError)] do
        TwitterSearch.search(:fr, :positive, :no_max_id)
      end
    end
  end

  test "it throws error when other errors occur" do
    with_mock HTTPoison, [get: fn("https://api.twitter.com/1.1/search/tweets.json",_,_) -> {:ok, other_error} end] do
      with_mock TwitterRateLimiter, [handle_rate_limit: expect_raise_exception(ExTwitter.Error)] do
        TwitterSearch.search(:fr, :positive, :no_max_id)
      end
    end
  end

  def token_response do
    %HTTPoison.Response {
      status_code: 200,
      body: ~s/{ "access_token": "a_token" }/
    }
  end

  def statuses_response do
    %HTTPoison.Response {
      status_code: 200,
      body: """
      {
        "statuses": [
          { "text": "#{status(0)}" },
          { "text": "#{status(1)}" },
          { "text": "#{status(2)}" }
        ],
        "search_metadata": {
          "next_results": "?max_id=#{max_id}&q=%23freebandnames&count=4&include_entities=1&result_type=mixed"
        }
      }
      """
    }
  end

  def rate_limit_error do
    %HTTPoison.Response {
      status_code: 429,
      body: ~s/{ "errors": [ { "code": 88, "message": "Rate limit exceeded" } ] }/,
      headers: %{"x-rate-limit-reset" => "1200"}
    }
  end

  def other_error do
    %HTTPoison.Response {
      status_code: 401,
      body: ~s/{ "errors": [ { "code": 37, "message": "Other error" } ] }/
    }
  end

  def status(0), do: ":) Thee Namaste Nerdz. #FreeBandNames"
  def status(1), do: "Mexican Heaven, hi to the Hell #freebandnames :)"
  def status(2), do: "The Foooolish Mortals :D #freebandnames @jordy"
  def max_id,    do: 249279667666817023

  def expect_raise_exception(exception) do
    fn(fun) ->
      assert_raise exception, fn ->
        fun.()
      end
      {[], :no_max_id}
    end
  end

end