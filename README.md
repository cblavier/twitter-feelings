# TwitterFeelings

TwitterFeelings is a Twitter sentiment analysis engine. It streams live statuses from Twitter and categorizes them according to their mood (positive or negative).
It is written in Elixir, runs on Erlang VM and uses Redis for storage.

It is partly based on _Twitter Sentiment Classification using Distant Supervision_ described in this [Stanford paper](http://cs.stanford.edu/people/alecmgo/papers/TwitterDistantSupervision09.pdf).

TwitterFeelings is composed of 3 parts :
- **streaming machine** : uses Twitter streaming API to get live tweets on a specific topic, and updates Redis mood counters accordingly.
- **sentiment analyzer**: based on a corpus of tweets, computes each word's probability to appear in a positive and in a negative tweet.
- **corpus builder**: uses Twitter search API to build a very large set of tweets that will feed the sentiment analyzer, to make it learn.

## Setup
- install Elixir / Erlang / Redis
- build script with `mix escript.build` command
- have following environment variables declared:
   - TWITTER_CONSUMER_KEY
   - TWITTER_CONSUMER_SECRET
   - TWITTER_ACCESS_TOKEN
   - TWITTER_ACCESS_TOKEN_SECRET

## Streaming Machine
TODO

## Sentiment Analyzer
TODO

## Corpus Builder
This application runs thousand of queries on Twitter Search API, to build a large corpus of Tweets that we will able to analyze later.
Since we need to know if each retrieved status is either positive or negative, we will use Stanford approach (see link in intro) to categorize Twitter statutes according to the smileys they contain.

Each tweet retrieved is:
  - filtered (we don't keep biased twitters containing both positive and negative smileys)
  - normalized (downcased, stripped of urls/usernames/accents/smileys/short words/...)
  - stored in a dedicated Redis set

To build a large corpus of french positive and negative tweets, run the following commands:
```
./twitter_feelings build-corpus --lang fr --mood positive --query-count 5000
./twitter_feelings build-corpus --lang fr --mood negative --query-count 5000
```
It will take hours since the application has to deal with Twitter rate limitations (180 queries per 15mn).
Each query fetches 100 tweets at once.