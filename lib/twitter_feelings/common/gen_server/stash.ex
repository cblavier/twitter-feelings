# Stash is a worker process that can be used by GenServers
# to store state outside of their process (and retrieve it after a failure)
defmodule TwitterFeelings.Common.GenServer.Stash do

  use GenServer
  use TwitterFeelings.Common.GenServer.Stoppable
  use TwitterFeelings.Common.GenServer.Startable

  def save_state(name, state) do
    GenServer.cast name, {:save_state, state}
  end

  def get_state(name) do
    GenServer.call name, :get_state
  end

  # server implementation

  def handle_call(:get_state, _from, current_state) do
    { :reply, current_state, current_state }
  end

  def handle_cast({:save_state, new_state}, _current_state) do
    { :noreply, new_state }
  end

end