defmodule TwitterFeelings.CorpusBuilder.TwitterSearchTest do

  use ExUnit.Case, async: false
  import Mock

  alias TwitterFeelings.CorpusBuilder.TwitterSearch, as: TSearch
  alias TwitterFeelings.CorpusBuilder.TweetStore,    as: TStore

  setup do
    TSearch.start_link
    {:ok, []}
  end

  test "processes and store tweets" do
    lang = :fr
    mood = :positive
    with_mock ExTwitter.API.Base, [request: fn(_,_,_) -> statuses_json end] do
      with_mock TStore, [store_tweet: fn(_) -> end] do
        TSearch.search_and_store(lang, mood, 2)
        :timer.sleep(10)
        assert called TStore.store_tweet("thee namaste nerdz #freebandnames")
        assert called TStore.store_tweet("mexican heaven the hell #freebandnames")
        assert called TStore.store_tweet("the foolish mortals #freebandnames")
      end
    end
  end

  def statuses_json do
    {:ok, json} = ExTwitter.JSON.decode("""
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
    json
  end


end