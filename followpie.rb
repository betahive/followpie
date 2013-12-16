# Requirements
require 'httparty'

# DO NOT TOUCH THESE THREE CONST VARIABLES
POPULAR = 1
LIKE = 2
LIKE_FOLLOW = 3

# Choose the tag you want to like based on, keep the word in double quotes, do not put a # sign in front of the tag
TAGS = ["friends", "meeting", "meetup", "social", "chat", "conversation", "buddy", "friend", "coffee", "buddies"]

# IF YOU WANT THE ACTION TO FOLLOW OR LIKE SOMEONE BASED ON THE CHOSEN TAG CHANGE IT TO EITHER
#   ACTION=:popular   - Popular follows people who have liked an image on the popular page (this means they are active users)
#   ACTION=:like
#   ACTION=:like_follow
ACTION = :like_follow

# CHANGE THE NUMBER OF LIKES OR FOLLOWS YOU WANT TO OCCUR, e.g. NO MORE THEN 100 is the current setting
MAX_COUNT = 10

# MAX seconds is the number of seconds to randomly wait between doing your next follow or like (this helps to avoid acting like a crazy spam bot)
MAX_SECS = 15

# Hit the URL below, the returned GET request will give you an auth token from Instagram.
#
# THE AUTH TOKEN IS THE KEY THAT YOU GET WHEN YOU SIGN IN WITH THE FOLLOWING CLIENT URL.
# DOES NOT NEED TO CHANGE UNLESS AUTH TOKEN EXPIRES
#
#
#   https://api.instagram.com/oauth/authorize/?client_id=f3de7f80695549739c48a2e20538a3e1&redirect_uri=http://joinpingle.com&response_type=token&display=touch&scope=likes+relationships


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
  query      = query.merge({:access_token => ENV["IG_ACCESS_TOKEN"], :client_id => ENV["IG_CLIENT_ID"]})  
  
  if http_method == :get
    options = headers.merge({:query => query})
  else
    options = headers.merge({:body => query})
    puts options
  end

  response   = HTTParty.send(http_method, url, options)
  # puts response["meta"]["code"]
  puts response["meta"]
  return response
rescue Exception => error
  puts error
end

def likePicture(pictureId)
  url = "https://api.instagram.com/v1/media/#{pictureId}/likes"
  send_request(:post, url)
end


def followUser(userId)
  url = "https://api.instagram.com/v1/users/#{userId}/relationship"
  query = {"action" => "follow"}
  send_request(:post, url, query)
end
        
def likeAndFollowUser(userId)
  url = "https://api.instagram.com/v1/users/#{userId}/media/recent"
  response = send_request(:get, url)

  picsToLike = rand(1..3)
  puts "Liking #{picsToLike} pics for user #{userId}"

  begin
    response['data'].each_with_index do |picture, index|
      puts "Liking picture #{picture['id']}."
      likePicture picture['id']
      break if (index + 1) == picsToLike
    end
  rescue Exception => error
    puts error
  end

  followUser userId
end

def take_a_break
  seconds = rand(1..MAX_SECS)
  puts "Taking a break for #{seconds} seconds."
  sleep seconds
end


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

      # Follow User
      followUser userId
      usersFollowing << userId

      # Take a Break - Be human like!
      take_a_break

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

  TAGS.each do |tag|
    picturesLiked, usersFollowing = likeUsers(MAX_COUNT, 0, tag)
    puts "Liked #{picturesLiked}: Followed #{usersFollowing}: for tag #{tag}"
  end

elsif ACTION == :popular
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
      
      # Take a Break - Be human like!
      take_a_break

      break if usersFollowing.length == MAX_COUNT
    end

    # Take a Break - Be human like!
      take_a_break

    break if usersFollowing.length == MAX_COUNT
  end

  puts ""
  puts "Followed #{usersFollowing.length}"
end

puts "FOLLOW PIE ENDS - HAPPY DIGESTING"