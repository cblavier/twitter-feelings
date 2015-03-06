defmodule TwitterFeelings.CorpusBuilder.Supervisor do

  use Supervisor

  alias TwitterFeelings.CorpusBuilder.Builder
  alias TwitterFeelings.CorpusBuilder.TwitterSearch
  alias TwitterFeelings.CorpusBuilder.TweetStore
  alias TwitterFeelings.Common.GenServer.Stash

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_args) do
    children = [
      worker(Stash, [:no_max_id, Builder.stash_name], id: Builder.stash_name),
      worker(Builder, []),
      worker(Stash, [{:no_lang, :no_mood}, TweetStore.stash_name], id: TweetStore.stash_name),
      worker(TweetStore, []),
      worker(TwitterSearch, [])
    ]
    supervise(children, strategy: :one_for_one)
  end

end