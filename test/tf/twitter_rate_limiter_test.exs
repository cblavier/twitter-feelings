defmodule TF.TwitterRateLimiterTest do

  use ExUnit.Case, async: false
  use Timex
  import Mock

  alias TF.TwitterRateLimiter, as: RL

  test "callback immediately when rate limit is ok" do
    reset_time = x_seconds_from_now(0)
    with_mock ExTwitter.API.Base, [request: fn(_,_,_) -> rate_limit_json(reset_time) end] do
      with_mock IO, [puts: fn(_) -> end] do
        RL.rate_limit(fn -> IO.puts("here") end)
        assert called IO.puts("here")
      end
      assert called ExTwitter.API.Base.request(:_, :_, :_)
    end
  end

  test "callback after small delay when rate limit is reset soon" do
    reset_time = x_seconds_from_now(1)
    with_mock ExTwitter.API.Base, [request: fn(_,_,_) -> rate_limit_json(reset_time) end] do
      with_mock IO, [puts: fn(_) -> end] do
        RL.rate_limit(fn -> IO.puts("here") end)
        assert called IO.puts("here")
      end
      assert called ExTwitter.API.Base.request(:_, :_, :_)
    end
  end

  def rate_limit_json(reset_time) do
    ExTwitter.JSON.decode("""
    {
      "resources": {
        "search": {
          "/search/tweets": {
            "limit": 180,
            "remaining": #{if Time.now(:secs) > reset_time, do: 1, else: 0},
            "reset": #{reset_time}
          }
        }
      }
    }
    """)
  end

  def x_seconds_from_now(x) do
    Date.convert(Date.shift(Date.now, secs: x), :secs)
  end

end