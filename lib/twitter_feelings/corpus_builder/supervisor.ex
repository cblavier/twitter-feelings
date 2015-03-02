defmodule TwitterFeelings.CorpusBuilder.Supervisor do

  use Supervisor

  alias TwitterFeelings.CorpusBuilder.TwitterSearch,  as: TwitterSearch
  alias TwitterFeelings.CorpusBuilder.TweetStore,     as: TweetStore
  alias TwitterFeelings.Common.Stash,                 as: Stash

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_args) do
    children = [
      worker(Stash, [{:no_max_id, 0}, TwitterSearch.stash_name], id: TwitterSearch.stash_name),
      worker(TwitterSearch, []),
      worker(Stash, [{:no_lang, :no_mood}, TweetStore.stash_name], id: TweetStore.stash_name),
      worker(TweetStore, [])
    ]
    supervise(children, strategy: :one_for_one)
  end

end