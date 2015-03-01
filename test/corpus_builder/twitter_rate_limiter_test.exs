defmodule CorpusBuilder.TwitterRateLimiterTest do

  use ExUnit.Case, async: false
  use Timex
  import Mock

  alias CorpusBuilder.TwitterRateLimiter, as: RL
  alias ExTwitter.RateLimitExceededError, as: RateLimitError

  test "callback immediately when rate limit is ok" do
    with_mock IO, [puts: fn(_) -> end] do
      RL.handle_rate_limit(fn -> IO.puts("here") end)
      assert called IO.puts("here")
    end
  end

  test "callback after small delay when rate limit is reset soon" do
    reset_time = x_seconds_from_now(1)
    with_mock IO, [puts: fn(_) -> end ] do
      RL.handle_rate_limit(fn -> raise_rate_limit_error_before(reset_time) end)
      :timer.sleep(10)
      assert called IO.puts("here")
    end
  end

  def raise_rate_limit_error_before(reset_time) do
    if Time.now(:secs) > reset_time do
      IO.puts("here")
    else
      raise RateLimitError, reset_in: 0.1
    end
  end

  def x_seconds_from_now(x) do
    Date.convert(Date.shift(Date.now, secs: x), :secs)
  end

end