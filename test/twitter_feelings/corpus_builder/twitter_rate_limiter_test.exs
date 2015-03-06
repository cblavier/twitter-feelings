defmodule TwitterFeelings.CorpusBuilder.TwitterRateLimiterTest do

  use ExUnit.Case, async: false
  import Mock
  import TimeHelper

  alias TwitterFeelings.CorpusBuilder.TwitterRateLimiter

  test "callback immediately when rate limit is ok" do
    with_mock IO, [puts: fn(_) -> end] do
      TwitterRateLimiter.handle_rate_limit(fn -> IO.puts("here") end)
      assert called IO.puts("here")
    end
  end

  test "callback after small delay when rate limit is reset soon" do
    reset_time = x_msecs_from_now(100)
    rate_limited_function = fn ->
      change_behavior_after(reset_time,
        fn -> raise ExTwitter.RateLimitExceededError, reset_in: 0.1 end,
        fn -> IO.puts("here") end
      )
    end

    with_mock IO, [puts: fn(_) -> end ] do
      TwitterRateLimiter.handle_rate_limit(rate_limited_function)
      wait_until fn ->
        assert called IO.puts("here")
      end
    end
  end

end