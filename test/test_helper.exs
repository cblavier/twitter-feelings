ExUnit.start()
Logger.remove_backend(:console)
Application.put_env(TwitterFeelings, :test, true)


defmodule TimeHelper do

  use Timex

  def x_msecs_from_now(x) do
    Time.now(:msecs) + x
  end

  def change_behavior_after(date, fun1, fun2) do
    if Time.now(:msecs) < date do
      fun1.()
    else
      fun2.()
    end
  end

  def wait_until(fun), do: wait_until(500, fun)

  def wait_until(0, fun), do: fun.()

  def wait_until(timeout, fun) do
    try do
      fun.()
    rescue
      ExUnit.AssertionError ->
        :timer.sleep(10)
        wait_until(max(0, timeout - 10), fun)
    end
  end

end
