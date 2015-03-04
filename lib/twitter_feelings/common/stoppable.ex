defmodule TwitterFeelings.Common.Stoppable do

  defmacro __using__(opts) do
    quote do

      def stop do
        stop(__MODULE__)
      end

      def stop(name) do
        if alive?(name) do
          GenServer.call(name, :stop)
        end
      end

      def alive? do
        alive?(__MODULE__)
      end

      def alive?(name) do
        pid = Process.whereis(name)
        cond do
          is_pid(pid) -> Process.alive?(pid)
          true -> false
        end
      end

      def handle_call(:stop, _from, state) do
        {:stop, :normal, :ok, state}
      end

    end
  end

end