# Requirements
require 'httparty'

# Choose the tag you want to like based on, keep the word in double quotes, do not put a # sign in front of the tag
TAGS = ["fashion", "style", "stylish", "love", "me", "cute", "photooftheday", "instagood", "instafashion", "pretty", "girly", "pink", "girl", "girls", "eyes", "model", "dress", "skirt", "shoes", "heels", "styles", "outfit", "purse", "jewelry", "shopping"]

# IF YOU WANT THE ACTION TO FOLLOW OR LIKE SOMEONE BASED ON THE CHOSEN TAG CHANGE IT TO EITHER
#   ACTION=:popular   - Popular follows people who have liked an image on the popular page (this means they are active users)
#   ACTION=:like
#   ACTION=:like_follow
ACTION = :like

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
#   https://api.instagram.com/oauth/authorize/?client_id=f3de7f80695549739c48a2e20538a3e1&redirect_uri=http://joinpingle.com&response_type=token&display=touch&scope=likes+relationships
IG_CLIENT_ID     = 'f3de7f80695549739c48a2e20538a3e1'
IG_CLIENT_SECRET = 'edfbe3b8981142889e4d8abe18a7b56e'
# IG_ACCESS_TOKEN  = '595214910.f3de7f8.c92a1adf58004687bb3657bdfbd4de46'
IG_ACCESS_TOKEN = '1427663286.f3de7f8.f46d002289224b3c845248b2c0954961'

TOTAL_ACTIONS = 0

###### DO NOT TOUCH ANYTHING UNDER HERE UNLESS YOU KNOW WHAT YOU ARE DOING, DANGER DANGER, SERIOUS PROBLEMS IF YOU TOUCH ###########

puts "FOLLOW PIE BEGINS - GRAB A SLICE AND SIT BACK"
puts ""
puts "The script will now proceed to follow and like users"
puts ""
puts ""

def send_request(http_method, url, query={})
  puts "URL Requested: #{url}, METHOD: #{http_method}"

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
  send_request(:post, url)

  increment_actions

  # Take a Break - Be Human Like
  take_a_break(5)
end

def followUser(userId)
  puts "Following User: #{userId}"
  url = "https://api.instagram.com/v1/users/#{userId}/relationship"
  query = {"action" => "follow"}
  send_request(:post, url, query)

  increment_actions

  # Take a Break - Be Human Like
  take_a_break
end
        
def likeAndFollowUser(userId)
  url = "https://api.instagram.com/v1/users/#{userId}/media/recent"
  response = send_request(:get, url)

  picsToLike = rand(1..3)
  puts "Liking #{picsToLike} pics for user #{userId}"

  begin
    # Like Users Photos
    response['data'].each_with_index do |picture, index|
      puts "Liking picture #{picture['id']}."
      likePicture picture['id']
      increment_actions
      break if (index + 1) == picsToLike
    end
  rescue Exception => error
    puts error
  end

  # Follow User
  followUser userId
end

def take_a_break(max = MAX_SECS)
  seconds = rand(1..max)
  puts "Taking a break for #{seconds} seconds."
  sleep seconds
end

def increment_actions
  TOTAL_ACTIONS +=1
end

def print_response(response)
  response_code = response["meta"]["code"]
  string = "Response: #{response_code}"
  string = "#{string}, Details: #{response["meta"]}" if response_code != 200
  return string
end

# Run the script.
if ACTION == :like or ACTION == :like_follow
  def likeUsers(max_results, max_id, tag, picturesLiked=[], usersFollowing=[])
    url = "https://api.instagram.com/v1/tags/#{tag}/media/recent"

    response = send_request(:get, url)

    numResults = response['data'].length

    pictureId = 0
    response['data'].each do |picture|
      puts ''
      pictureId    = picture['id']
      paginationId = response["pagination"]['next_max_id']
      user         = picture['user']
      userId       = user['id']

      # Like Picture
      likePicture pictureId
      picturesLiked << pictureId

      if ACTION == :like_follow
        # Follow User
        followUser userId
        usersFollowing << userId
      end

      # Print some stats
      if picturesLiked.length % 10 == 0
        puts "Liked ##{tag} pictures: #{picturesLiked.length}"
      end

      if usersFollowing.length % 10 == 0 and usersFollowing.length != 0
        puts "Followed ##{tag}: #{usersFollowing.length}"
      end

      if picturesLiked.length == max_results
        break
      else
        likeUsers max_results, paginationId, tag, picturesLiked, usersFollowing
      end

      return picturesLiked, usersFollowing
    end
  end

  # While less than 30 requests
  # Instagram limit
  while TOTAL_ACTIONS < 30
    TAGS.each do |tag|
      picturesLiked, usersFollowing = likeUsers(MAX_COUNT, 0, tag)
      puts "Liked #{picturesLiked}: Followed #{usersFollowing}: for tag #{tag}"
    end
  end

  TOTAL_ACTIONS = 0



elsif ACTION == :popular
  puts "Checking Popular Photos"

  usersFollowing = []
  url = "https://api.instagram.com/v1/media/popular"
  puts url

  response = send_request(:get, url)

  response['data'].each do |picture|

    # Look for people who have liked the photo
    picture['likes']['data'].each do |user|
      userId = user['id']
      
      # Follow User
      usersFollowing << userId if likeAndFollowUser(userId)

      break if usersFollowing.length == MAX_COUNT
    end

    break if usersFollowing.length == MAX_COUNT
  end
end

puts "FOLLOW PIE ENDS - HAPPY DIGESTING"