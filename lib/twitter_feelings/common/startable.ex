defmodule TwitterFeelings.Common.Startable do

  defmacro __using__(_opts) do
    quote do

      def start_link do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end

      def start_link(state, name) do
        GenServer.start_link(__MODULE__, state, name: name)
      end

      def start do
        GenServer.start(__MODULE__, [], name: __MODULE__)
      end

      def start(state) do
        GenServer.start(__MODULE__, state, name: __MODULE__)
      end

      def start(state, name) do
        GenServer.start(__MODULE__, state, name: name)
      end

    end
  end

end