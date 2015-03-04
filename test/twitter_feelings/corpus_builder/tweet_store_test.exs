defmodule TwitterFeelings.CorpusBuilder.TweetStoreTest do

  use ExUnit.Case, async: true

  alias TwitterFeelings.CorpusBuilder.TweetStore, as: TweetStore
  alias TwitterFeelings.Common.Stash,             as: Stash

  setup do
    {:ok, _ } = Stash.start({:no_lang, :no_mood},TweetStore.stash_name)
    {:ok, store_pid } = TweetStore.start
    on_exit fn ->
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
    TweetStore.store_tweet("foo")
  end

  test "it works when lang and mood are set 2" do
    TweetStore.set_lang_and_mood(:fr, :positive)
    TweetStore.store_tweet("bar")
  end

  def assert_server_error(monitor, message) do
    assert_receive {:DOWN, ^monitor, :process, _, ^message}, 200
  end

end