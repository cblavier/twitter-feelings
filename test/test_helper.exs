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

end
