defmodule TwitterFeelings.CorpusBuilder.TwitterRateLimiterTest do

  use ExUnit.Case, async: false
  use Timex
  import Mock

  alias TwitterFeelings.CorpusBuilder.TwitterRateLimiter, as: RL
  alias ExTwitter.RateLimitExceededError, as: RateLimitError

  test "callback immediately when rate limit is ok" do
    with_mock IO, [puts: fn(_) -> end] do
      RL.handle_rate_limit(fn -> IO.puts("here") end)
      assert called IO.puts("here")
    end
  end

  test "callback after small delay when rate limit is reset soon" do
    reset_time = x_seconds_from_now(1)
    rate_limited_function = fn ->
      raise_rate_limit_error_before(reset_time,fn ->
        IO.puts("here")
      end)
    end

    with_mock IO, [puts: fn(_) -> end ] do
      RL.handle_rate_limit(rate_limited_function)
      :timer.sleep(10)
      assert called IO.puts("here")
    end
  end

  def raise_rate_limit_error_before(reset_time, fun) do
    if Time.now(:secs) > reset_time do
      fun.()
    else
      raise RateLimitError, reset_in: 0.1
    end
  end

  def x_seconds_from_now(x) do
    Date.convert(Date.shift(Date.now, secs: x), :secs)
  end

end