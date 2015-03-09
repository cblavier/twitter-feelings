defmodule TwitterFeelings.Learning.LearnerTest do

  use ExUnit.Case, async: false

  alias TwitterFeelings.Learning.Learner
  alias TwitterFeelings.Learning.TokenCounter
  alias TwitterFeelings.Common.GenServer.Stash
  alias TwitterFeelings.Common.Redis

  setup do
    Redis.clear_keys("test-*")
    {:ok, _ } = Stash.start(TokenCounter.initial_state, TokenCounter.stash_name)
    {:ok, _ } = TokenCounter.start
    for mood <- [:negative, :positive], do: store_tweets(lang, mood, tweets(mood))
    Learner.learn(lang)

    on_exit fn ->
      Redis.clear_keys("test-*")
      TokenCounter.stop
      Stash.stop(TokenCounter.stash_name)
    end

    {:ok, []}
  end

  test "it counts tweet tokens for mood" do
    assert_redis_count(lang, :negative, "how", 1)
    assert_redis_count(lang, :negative, "sad", 1)
    assert_redis_count(lang, :negative, ":(", 1)
    assert_redis_count(lang, :negative, "this", 1)
    assert_redis_count(lang, :negative, "quite", 1)
    assert_redis_count(lang, :negative, "terrific", 1)
    assert_redis_count(lang, :negative, ":((", 1)

    assert_redis_count(lang, :positive, "this", 1)
    assert_redis_count(lang, :positive, "tweet", 2)
    assert_redis_count(lang, :positive, ":)", 1)
    assert_redis_count(lang, :positive, "terrific", 1)
    assert_redis_count(lang, :positive, ":D", 1)
  end


  test "it counts tweet tokens globally" do
    assert_redis_count(lang, "this", 2)
    assert_redis_count(lang, "tweet", 3)
    assert_redis_count(lang, ":)", 1)
    assert_redis_count(lang, "terrific", 2)
    assert_redis_count(lang, ":(", 1)
  end

  test "it computes positive probability" do
    assert_positive_probability(lang, "this", 1/2)
    assert_positive_probability(lang, "awesome", 1.0)
    assert_positive_probability(lang, "sad", 0.0)
    assert_positive_probability(lang, "tweet", 2/3)
  end

  ########

  def lang, do: :en

  def store_tweets(lang, mood, tweets) do
    for tweet <- tweets do
      Redis.run(["SADD", Redis.corpus_key(lang, mood), tweet])
    end
  end

  def assert_redis_count(lang, mood, token, expected) do
    count = redis_get(Redis.count_key(lang, mood, token), :integer)
    assert ^count = expected
  end

  def assert_redis_count(lang, token, expected) do
    count = redis_get(Redis.count_key(lang, token), :integer)
    assert ^count = expected
  end

  def assert_positive_probability(lang, token, expected) do
    prob = redis_get(Redis.positive_prob_key(lang, token), :float)
    rounded_prob = Float.round(prob, 5)
    rounded_expected = Float.round(expected, 5)
    assert ^rounded_prob = rounded_expected
  end

  def redis_get(key) do
    {:ok, value} = Redis.run(["GET", key])
    value
  end

  def redis_get(key, :integer) do
    {value, _} = Integer.parse(redis_get(key))
    value
  end

  def redis_get(key, :float) do
    {value, _} = Float.parse(redis_get(key))
    value
  end

  def tweets(:positive) do
    [
      "this awesome tweet :)",
      "terrific tweet :D"
    ]
  end

  def tweets(:negative) do
    [
      "how tweet sad :(",
      "this quite terrific :(("
    ]
  end

end