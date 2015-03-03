defmodule TwitterFeelings.CorpusBuilder.BuilderTest do

  use ExUnit.Case, async: false
  import Mock

  alias TwitterFeelings.CorpusBuilder.Builder,       as: Builder
  alias TwitterFeelings.CorpusBuilder.TweetStore,    as: TStore
  alias TwitterFeelings.CorpusBuilder.TwitterSearch, as: TSearch

  setup do
    Builder.start_link
    {:ok, []}
  end

  test "processes and store tweets" do
    lang = :fr
    mood = :positive
    with_mock TSearch, [search: fn(_,_,_) -> {:ok, statuses, max_id} end] do
      with_mock TStore, [store_tweet: fn(_) -> end] do
        Builder.build_corpus(lang, mood, 2)
        :timer.sleep(10)
        assert called TStore.store_tweet("thee namaste nerdz #freebandnames")
        assert called TStore.store_tweet("mexican heaven the hell #freebandnames")
        assert called TStore.store_tweet("the foolish mortals #freebandnames")
      end
    end
  end

  def statuses do
    [
      %{"text" => ":) Thee Namaste Nerdz. #FreeBandNames"},
      %{"text" => "Mexican Heaven, hi to the Hell #freebandnames :)"},
      %{"text" => "The Foooolish Mortals :D #freebandnames @jordy"}
    ]
  end

  def max_id do
    "249279667666817023"
  end


end