defmodule TwitterFeelings.CorpusBuilder.TweetStoreTest do

  use ExUnit.Case, async: false
  import TimeHelper

  alias TwitterFeelings.CorpusBuilder.TweetStore
  alias TwitterFeelings.Common.GenServer.Stash
  alias TwitterFeelings.Common.Redis

  setup do
    Redis.clear_keys("test-*")
    {:ok, _ } = Stash.start({:no_lang, :no_mood},TweetStore.stash_name)
    {:ok, store_pid } = TweetStore.start
    on_exit fn ->
      Redis.clear_keys("test-*")
      TweetStore.stop
      Stash.stop(TweetStore.stash_name)
    end
    {:ok, [monitor: Process.monitor(store_pid)]}
  end

  test "raises error when no lang is set", %{monitor: monitor} do
    TweetStore.store_tweet("foo")
    assert_server_error(monitor, :no_lang_set)
  end

  test "raises error when no mood is set", %{monitor: monitor} do
    TweetStore.set_lang_and_mood(:fr, :no_mood)
    TweetStore.store_tweet("foo")
    assert_server_error(monitor, :no_mood_set)
  end

  test "it works when lang and mood are set" do
    TweetStore.set_lang_and_mood(:fr, :positive)
    assert_tweet_count(0)
    TweetStore.store_tweet("foo")
    wait_until fn ->
      assert_tweet_count(1)
    end
  end

  def assert_server_error(monitor, message) do
    assert_receive {:DOWN, ^monitor, :process, _, ^message}, 200
  end

  def assert_tweet_count(expected_value) do
    count = TweetStore.tweet_count
    assert ^count = expected_value
  end

end