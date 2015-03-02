# Mixin that will automatically init a GenServer with state store in a Stash
# and save state in that Stash after a failure
defmodule TwitterFeelings.Common.Stashable do

  defmacro __using__(opts) do
    quote do

      def stash_name, do: unquote(opts[:stash_name])

      def init(_args) do
        IO.puts "in init"
        state = TwitterFeelings.Common.Stash.get_state(stash_name)
        { :ok, state }
      end

      def terminate(_reason, state) do
        IO.puts "in terminate"
        TwitterFeelings.Common.Stash.save_state(stash_name, state)
      end

    end
  end

end