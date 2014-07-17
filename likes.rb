# LIKES ONLY!
# Simplify things!

# Requirements
require 'httparty'

class Liker
  # Choose the tag you want to like based on, keep the word in double quotes, do not put a # sign in front of the tag
  TAGS = ["fashion", "style", "stylish", "love", "me", "cute", "photooftheday", "instagood", "instafashion", "pretty", "girly", "pink", "girl", "girls", "eyes", "model", "dress", "skirt", "shoes", "heels", "styles", "outfit", "purse", "jewelry", "shopping"]

  # CHANGE THE NUMBER OF LIKES OR FOLLOWS YOU WANT TO OCCUR, e.g. NO MORE THEN 100 is the current setting
  MAX_COUNT = 100

  # MAX seconds is the number of seconds to randomly wait between doing your next follow or like (this helps to avoid acting like a crazy spam bot)
  # Blocked: 10s, 20s.
  # 60s seems slow but it trotted along nicely.
  MAX_SECS = 60

  # Hit the URL below, the returned GET request will give you an auth token from Instagram.
  #
  # THE AUTH TOKEN IS THE KEY THAT YOU GET WHEN YOU SIGN IN WITH THE FOLLOWING CLIENT URL.
  # DOES NOT NEED TO CHANGE UNLESS AUTH TOKEN EXPIRES
  #
  #
  # https://api.instagram.com/oauth/authorize/?client_id=f3de7f80695549739c48a2e20538a3e1&redirect_uri=http://joinpingle.com&response_type=token&display=touch&scope=likes+relationships
  IG_CLIENT_ID     = 'f3de7f80695549739c48a2e20538a3e1'
  IG_CLIENT_SECRET = 'edfbe3b8981142889e4d8abe18a7b56e'
  IG_ACCESS_TOKEN = '1427663286.f3de7f8.f46d002289224b3c845248b2c0954961'

  def initialize
    @total_actions = 0

    # Instagram limit
    TAGS.each do |tag|
      if @total_actions < 30
        picturesLiked = likePics(MAX_COUNT, 0, tag)
        puts "Tag: #{tag}, Liked #{picturesLiked}"
      else
        break
      end
    end

    # Sleep for an hour
    # to keep Instagram happy
    puts ""
    puts ""
    puts "IG limit reached"
    puts "Sleeping for an hour!"
    sleep 3600

    # Start again
    self.class.new()
  end

  # While less than 30 requests
  def likePics(max_results, max_id, tag, picturesLiked=[])
    url = "https://api.instagram.com/v1/tags/#{tag}/media/recent"

    response = send_request(:get, url)

    numResults = response['data'].length

    pictureId = 0
    response['data'].each do |picture|
      puts ''
      pictureId    = picture['id']
      paginationId = response["pagination"]['next_max_id']
      
      # Like Picture
      while @total_actions < 30
        puts "TOTAL ACTIONS: #{@total_actions}"
        likePicture pictureId
        picturesLiked << pictureId
      end

      # Print some stats
      if picturesLiked.length % 10 == 0
        puts "Liked ##{tag} pictures: #{picturesLiked.length}"
      end

      if picturesLiked.length == max_results || @total_actions >= 30
        puts 'Break the cycle'
        break
      else
        likePics max_results, paginationId, tag, picturesLiked
      end

      return picturesLiked
    end
  end

  def send_request(http_method, url, query={})
    # puts "URL Requested: #{url}, METHOD: #{http_method}"
    user_agent = "mozilla/5.0 (iphone; cpu iphone os 7_0_2 like mac os x) applewebkit/537.51.1 (khtml, like gecko) version/7.0 mobile/11a501 safari/9537.53"
    headers    = { "User-Agent" => user_agent, "Content-type" => "application/x-www-form-urlencoded"}
    query      = query.merge({:access_token => IG_ACCESS_TOKEN, :client_id => IG_CLIENT_ID})  
    
    if http_method == :get
      options = headers.merge({:query => query})
    else
      options = headers.merge({:body => query})
    end

    response   = HTTParty.send(http_method, url, options)
    puts print_response(response)
    return response
  rescue Exception => error
    puts error
  end

  def likePicture(pictureId)
    puts "Liking Picture: #{pictureId}"
    url = "https://api.instagram.com/v1/media/#{pictureId}/likes"
    response = send_request(:post, url)

    # 429 is the IG error code
    # for their limit exception
    # i.e we've gone in too hard.
    if response["meta"]["code"] == 429
      @total_actions = 30
    else
      @total_actions +=1

      # Take a Break - Be Human Like
      take_a_break(5)
    end
  end
          
  def take_a_break(max = MAX_SECS)
    seconds = rand(1..max)
    puts "Taking a break for #{seconds} seconds."
    sleep seconds
  end

  def print_response(response)
    response_code = response["meta"]["code"]
    string = "Response: #{response_code}"
    string = "#{string}, Details: #{response["meta"]}" if response_code != 200
    return string
  end
end

puts "LIKE PIE BEGINS - GRAB A SLICE AND SIT BACK"
puts ""
puts "The script will now proceed to like photos"
puts ""
puts ""

# DO STUFF
Liker.new()

puts "LIKE PIE ENDS - HAPPY DIGESTING"