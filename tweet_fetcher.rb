require 'java'

require './twitterr'

java_import 'java.util.concurrent.Callable'

class TweetFetcher < Struct.new(:category, :celebs, :redis)
  include Callable

  def call
    puts "Category: #{category.inspect}"
    celebs.each do |celeb|
      puts "Fetching timeline for celeb: #{celeb.inspect}"
      twitter.user_timeline(celeb, tweet_mode: 'extended').each do |tweet|
        redis.zadd(tweet_info_key(category), get_score(tweet), tweet_info(tweet)) unless tweet.retweet?
      end
    end
  end

  private

  def twitter
    @twitter ||= Twitterr.new.twitter
  end

  def tweet_info_key(category)
    "#{category}:tweets"
  end

  def get_score(tweet)
    # tweet_age = [Time.now - tweet.created_at, 1].max
    # (tweet.retweet_count * tweet.favorite_count).to_f / (tweet_age ** 2)
    tweet.created_at.to_i
  end

  def tweet_info(tweet)
    {
      "id" => tweet.id.to_s,
    }.to_json
  end

end
