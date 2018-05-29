require 'twitter'
require 'yaml'
require 'erb'

class Twitterr

  attr_reader :twitter

  def initialize
    config = YAML.load(ERB.new(File.read("config/twitter.yml")).result).freeze
    @twitter = Twitter::REST::Client.new(config["twitter"])
  end
end
