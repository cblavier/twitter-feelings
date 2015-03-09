defmodule TwitterFeelings.CorpusBuilder.BuilderTest do

  use ExUnit.Case, async: false
  import Mock
  import TimeHelper

  alias TwitterFeelings.CorpusBuilder.Builder
  alias TwitterFeelings.CorpusBuilder.TweetStore
  alias TwitterFeelings.CorpusBuilder.TwitterSearch
  alias TwitterFeelings.Common.GenServer.Stash

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
    time = x_msecs_from_now(500)
    tweet_count = fn ->
      change_behavior_after(time,
        fn -> 1 end,
        fn -> 2 end
      )
    end
    with_mock TwitterSearch, [search: fn(_,_,_) -> {:ok, statuses, "249279667666817023"} end] do
      with_mock TweetStore, [set_lang_and_mood: fn(_,_) -> end, store_tweet: fn(_) -> end, tweet_count: tweet_count] do
        Builder.build_corpus(:fr, :positive, 2)
        wait_until fn ->
          assert called TweetStore.store_tweet("thee namaste nerdz #freebandnames :)")
          assert called TweetStore.store_tweet("mexican heaven the hell #freebandnames :)")
          assert called TweetStore.store_tweet("the foolish mortals #freebandnames :D")
        end
      end
    end
  end

  test "it stops when there is no longer max_id" do
    with_mock TwitterSearch, [search: fn(_,_,_) -> {:ok, statuses, :no_more_max_id} end] do
      with_mock TweetStore, [set_lang_and_mood: fn(_,_) -> end, store_tweet: fn(_) -> end, tweet_count: fn -> 1 end] do
        Builder.build_corpus(:fr, :positive, 2)
        wait_until fn ->
          assert called TweetStore.store_tweet("thee namaste nerdz #freebandnames :)")
          assert called TweetStore.store_tweet("mexican heaven the hell #freebandnames :)")
          assert called TweetStore.store_tweet("the foolish mortals #freebandnames :D")
        end
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

end