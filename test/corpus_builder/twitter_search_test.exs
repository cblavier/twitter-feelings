defmodule CorpusBuilder.TwitterSearchTest do

  use ExUnit.Case, async: false
  import Mock

  alias CorpusBuilder.TwitterSearch, as: TSearch
  alias CorpusBuilder.TweetStore,    as: TStore

  test "processes and store tweets" do
    lang = :fr
    mood = :positive
    with_mock ExTwitter.API.Base, [request: fn(_,_,_) -> statuses_json end] do
      with_mock TStore, [store: fn(_,_,_) -> end] do
        TSearch.search(lang, mood, 1)
        :timer.sleep(10)
        assert called TStore.store("thee namaste nerdz #freebandnames", lang, mood)
        assert called TStore.store("mexican heaven the hell #freebandnames", lang, mood)
        assert called TStore.store("the foolish mortals #freebandnames", lang, mood)
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