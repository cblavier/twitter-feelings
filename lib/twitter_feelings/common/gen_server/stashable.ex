# Mixin that will automatically init a GenServer with state
# stored in a stash, and save state in that stash after a failure
defmodule TwitterFeelings.Common.GenServer.Stashable do

  defmacro __using__(opts) do
    quote do

      alias TwitterFeelings.Common.GenServer.Stash

      def stash_name, do: unquote(opts[:stash_name])

      def init(_args) do
        state = Stash.get_state(stash_name)
        { :ok, state }
      end

      def terminate(reason, state) do
        Stash.save_state(stash_name, state)
      end

      def state do
        state(__MODULE__)
      end

      def state(name) do
        GenServer.call(name, :get_state)
      end

      # server implementation

      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

    end
  end

end