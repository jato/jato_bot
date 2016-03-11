require 'twitter_ebooks'
require 'dotenv'
Dotenv.load(".env")

# Information about a particular Twitter user we know
class UserInfo  
  attr_reader :username

  # @return [Integer] how many times we can pester this user unprompted
  attr_accessor :pesters_left

  # @param username [String]
  def initialize(username)
    @username = username
    @pesters_left = 1
  end
end

class CloneBot < Ebooks::Bot  
  attr_accessor :original, :model, :model_path

  def configure
    # Configuration for all CloneBots
    self.blacklist = ['kylelehk', 'friedrichsays', 'Sudieofna', 'tnietzschequote', 'NerdsOnPeriod', 'FSR', 'BafflingQuotes', 'Obey_Nxme']
    self.delay_range = 1..6
    @userinfo = {}
  end

  def top100; @top100 ||= model.keywords.take(100); end
  def top20;  @top20  ||= model.keywords.take(20); end

  def on_startup
    load_model!

    scheduler.cron '0 0,4,8,12,16,20 * * *' do
    # scheduler.cron '*/59 * * * *' do
      # Each day at midnight, post a single tweet
      tweet(model.make_statement)
    end
  end

  def parse_array(value, array_splitter=nil)
    array_splitter ||= / *[,;]+ */
    value.split(array_splitter).map(&:strip)
  end

  def on_message(dm)
    from_owner = dm.sender.screen_name.downcase == "jato"
    log "[DM from owner? #{from_owner}]"
    if from_owner
      action = dm.text.split.first.downcase
      strip_re = Regexp.new("^#{action}\s*", "i")
      payload = dm.text.sub(strip_re, "")
      #TODO: Add blacklist/whitelist/reject(banned phrase)
      #TODO? Move this into a DMController class or equivalent?
      case action
      when "tweet"
        tweet model.make_response(payload, 140)
      when "follow", "unfollow", "block"
        payload = parse_array(payload.gsub("@", ''), / *[,; ]+ */) # Strip @s and make array
        send(action.to_sym, payload)
      when "mention"
        pre = payload + " "
        limit = 140 - pre.size
        message = "#{pre}#{model.make_statement(limit)}"
        tweet message
      when "cheating"
        tweet payload
      else
        log "Don't have behavior for action: #{action}"
        reply(dm, model.make_response(dm.text))
      end
    else
      #otherwise, just reply like a mention
      delay(dm_delay) do
        reply(dm, model.make_response(dm.text))
      end
    end
  end

  def on_mention(tweet)
    # Become more inclined to pester a user when they talk to us
    userinfo(tweet.user.screen_name).pesters_left += 1

    delay do
      load_model!
      reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
    end
  end

  def on_timeline(tweet)
    return if tweet.retweeted_status?
    return unless can_pester?(tweet.user.screen_name)

    tokens = Ebooks::NLP.tokenize(tweet.text)

    interesting = tokens.find { |t| top100.include?(t.downcase) }
    very_interesting = tokens.find_all { |t| top20.include?(t.downcase) }.length > 2

    delay do
      if very_interesting
        favorite(tweet) if rand < 0.5
        retweet(tweet) if rand < 0.1
        if rand < 0.01
          userinfo(tweet.user.screen_name).pesters_left -= 1
          load_model!
          reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
        end
      elsif interesting
        favorite(tweet) if rand < 0.05
        if rand < 0.001
          userinfo(tweet.user.screen_name).pesters_left -= 1
          load_model!
          reply(tweet, model.make_response(meta(tweet).mentionless, meta(tweet).limit))
        end
      end
    end
  end

  # Find information we've collected about a user
  # @param username [String]
  # @return [Ebooks::UserInfo]
  def userinfo(username)
    @userinfo[username] ||= UserInfo.new(username)
  end

  # Check if we're allowed to send unprompted tweets to a user
  # @param username [String]
  # @return [Boolean]
  def can_pester?(username)
    userinfo(username).pesters_left > 0
  end

  # Only follow our original user or people who are following our original user
  # @param user [Twitter::User]
  def can_follow?(username)
    @original.nil? || username == @original || twitter.friendship?(username, @original)
  end

  def favorite(tweet)
    if can_follow?(tweet.user.screen_name)
      super(tweet)
    else
      log "Unfollowing @#{tweet.user.screen_name}"
      twitter.unfollow(tweet.user.screen_name)
    end
  end

  def on_follow(user)
    if can_follow?(user.screen_name)
      follow(user.screen_name)
    else
      log "Not following @#{user.screen_name}"
    end
  end

  private
  def load_model!
    # return if @model

    @model_path ||= "model/#{original}.model"

    log "Loading model #{model_path}"
    @model = Ebooks::Model.load(model_path)
  end
end

CloneBot.new("jato_ebooks") do |bot|  
  bot.consumer_key = ENV['CONSUMER_KEY']
  bot.consumer_secret = ENV['CONSUMER_SECRET']
  bot.access_token = ENV['ACCESS_TOKEN']
  bot.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
  bot.original = "combined"
end