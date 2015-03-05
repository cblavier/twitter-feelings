defmodule TwitterFeelings.CorpusBuilder.TwitterRateLimiterTest do

  use ExUnit.Case, async: false
  use Timex
  import Mock
  import TimeHelper

  alias TwitterFeelings.CorpusBuilder.TwitterRateLimiter, as: RateLimiter

  test "callback immediately when rate limit is ok" do
    with_mock IO, [puts: fn(_) -> end] do
      RateLimiter.handle_rate_limit(fn -> IO.puts("here") end)
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
      RateLimiter.handle_rate_limit(rate_limited_function)
      :timer.sleep(10)
      assert called IO.puts("here")
    end
  end

end