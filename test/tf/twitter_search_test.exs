defmodule TF.TwitterSearchTest do

  use ExUnit.Case, async: false
  import Mock

  alias TF.TwitterSearch, as: TS

  test "processes and store tweets" do
    with_mock ExTwitter.API.Base, [request: fn(_,_,_) -> statuses_json end] do
      with_mock TF.TwitterRateLimiter, [rate_limit: fn(fun) -> fun.() end] do
        with_mock TF.TweetStore, [store: fn(_) -> end] do
          TS.search(":)", 1)
          :timer.sleep(100)
          assert called TF.TweetStore.store(":) thee namaste nerdz #freebandnames")
          assert called TF.TweetStore.store("mexican heaven the hell #freebandnames :)")
          assert called TF.TweetStore.store("the foolish mortals :D #freebandnames")
        end
      end
    end
  end

  def statuses_json do
    ExTwitter.JSON.decode("""
    {
      "statuses": [
        {
          "text": ":) Thee Namaste Nerdz. #FreeBandNames"
        },
        {
          "text": "Mexican Heaven, hi to the Hell #freebandnames :)"
        },
        {
          "text": "The Foooolish Mortals :D #freebandnames @jordy"
        }
      ],
      "search_metadata": {
        "next_results": "?max_id=249279667666817023&q=%23freebandnames&count=4&include_entities=1&result_type=mixed"
      }
    }
    """)
  end


end