require "tweetstream"
require "twitter"

# Config Twitter
#
@rest_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["TWITTER_API_KEY"]
  config.consumer_secret     = ENV["TWITTER_API_SECRET"]
  config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
end

TweetStream.configure do |config|
  config.consumer_key       = ENV["TWITTER_API_KEY"]
  config.consumer_secret    = ENV["TWITTER_API_SECRET"]
  config.oauth_token        = ENV["TWITTER_ACCESS_TOKEN"]
  config.oauth_token_secret = ENV["TWITTER_ACCESS_SECRET"]
  config.auth_method        = :oauth
end

# Search
keywords = "got style, fashion app, dress shopping, dresses"
$stderr.puts keywords.inspect

# List
# London's Best Dressed
@list_id = 162554063
@screen_names = []

# Stream
tweetstream = TweetStream::Client.new
tweetstream.filter({:track => keywords, :locations => '-0.11009,51.516682,-0.073703,51.528592'}) do |status|
  # puts "#{status.user.screen_name} - #{status.text}"
  puts status.user.screen_name
  # $stderr.puts status.attrs.inspect

  @screen_names << status.user.screen_name
  puts "User count: #{@screen_names.length}" if @screen_names.length % 10 == 0

  list_members_count = @rest_client.list_members(@list_id).attrs[:users].length

  if @screen_names.length == 100 && list_members_count.length < 5000
    puts "Adding Members to list"
    @rest_client.add_list_members(@list_id, @screen_names)

    # Reset array
    @screen_names = []
  elsif list_members_count.length == 5000
    puts "LIST IS FULL"
  end
end

tweetstream.on_error do |message|
  puts message
  $stderr.puts message
end