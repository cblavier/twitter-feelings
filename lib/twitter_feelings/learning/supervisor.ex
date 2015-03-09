defmodule TwitterFeelings.Learning.Supervisor do

  use Supervisor

  alias TwitterFeelings.Learning.TokenCounter
  alias TwitterFeelings.Common.GenServer.Stash

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_args) do
    children = [
      worker(Stash, [TokenCounter.initial_state, TokenCounter.stash_name], id: TokenCounter.stash_name),
      worker(TokenCounter, []),
    ]
    supervise(children, strategy: :one_for_one)
  end

end