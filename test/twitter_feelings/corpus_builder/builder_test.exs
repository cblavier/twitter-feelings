defmodule TwitterFeelings.CorpusBuilder.BuilderTest do

  use ExUnit.Case, async: false
  import Mock
  import TimeHelper

  alias TwitterFeelings.CorpusBuilder.Builder,       as: Builder
  alias TwitterFeelings.CorpusBuilder.TweetStore,    as: TStore
  alias TwitterFeelings.CorpusBuilder.TwitterSearch, as: TSearch
  alias TwitterFeelings.Common.Stash,                as: Stash

  setup do
    {:ok, _ } = Stash.start(:no_max_id, Builder.stash_name)
    {:ok, _ } = Builder.start
    on_exit fn ->
      Builder.stop
      Stash.stop(Builder.stash_name)
    end
    {:ok, []}
  end

  test "processes and store tweets" do
    time = x_msecs_from_now(700)
    tweet_count = fn ->
      change_behavior_after(time,
        fn -> 1 end,
        fn -> 2 end
      )
    end
    with_mock TSearch, [search: fn(_,_,_) -> {:ok, statuses, max_id} end] do
      with_mock TStore, [store_tweet: fn(_) -> end, tweet_count: tweet_count] do
        Builder.build_corpus(:fr, :positive, 2)
        :timer.sleep(10)
        assert called TStore.store_tweet("thee namaste nerdz #freebandnames")
        assert called TStore.store_tweet("mexican heaven the hell #freebandnames")
        assert called TStore.store_tweet("the foolish mortals #freebandnames")
      end
    end
  end

  test "it stops when there is no longer max_id" do
    with_mock TSearch, [search: fn(_,_,_) -> {:ok, statuses, :no_more_max_id} end] do
      with_mock TStore, [store_tweet: fn(_) -> end, tweet_count: fn -> 1 end] do
        Builder.build_corpus(:fr, :positive, 2)
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