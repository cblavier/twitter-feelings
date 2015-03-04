# Mixin that will automatically init a GenServer with state
# stored in a stash, and save state in that stash after a failure
defmodule TwitterFeelings.Common.Stashable do

  defmacro __using__(opts) do
    quote do

      def stash_name, do: unquote(opts[:stash_name])

      def init(_args) do
        state = TwitterFeelings.Common.Stash.get_state(stash_name)
        { :ok, state }
      end

      def terminate(reason, state) do
        TwitterFeelings.Common.Stash.save_state(stash_name, state)
      end

    end
  end

end