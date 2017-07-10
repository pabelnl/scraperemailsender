class DashboardController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    if check_login
      puts "### Login sucessfull"
    else
      return
    end
  end

  def get_data_from_feed
    target_username = dashboard_params[:target_username] || ""
    # Init Koala for facebook api
    @array = Array.new
    @graph = Koala::Facebook::API.new()
    puts "### Facebook API initialized"

    if not dashboard_params[:target_username] == nil and not dashboard_params[:target_username] == ""
      target_username = dashboard_params[:target_username]
      puts "### Username = "+target_username
      # @graph.get_connection('171572419565247', 'posts')
      target_feed = @graph.get_connections(get_userid_from_string(target_username), 'posts', fields: "message,id,created_time,comments.fields(comments.fields(from,message),message,from),from", limit: 100)

      if not target_feed == nil and not target_feed == ""
        puts "### Iterating feed posts "
        target_feed.each do |post|
          if post["comments"]
            post["comments"]["data"].each do |data|
              email_address = get_email_from_string(data["message"])
              if not email_address.first == "" and not email_address.first.nil?
                tempHash = Hash.new
                if not data["from"]["name"] == nil and not data["from"]["name"] == ""
                  tempHash["name"] = data["from"]["name"]
                  puts "### Commentator name = "+tempHash["name"]
                end
                tempHash["email"] = email_address.first || ""
                puts "### Commentator email address = "+ tempHash["email"]
                @array.push(tempHash)
              else
                puts "### Comment doesn't have an email, skipping"
              end
            end
          else
            puts "### Post doesn't have comments"
          end
        end
        # We clean the array from duplicates
        unique = @array.uniq
        # We return a json with the array
        render json: {users: unique}, status: 200
      end

    end
  end

  def method_name

  end

  def get_userid_from_string(string)
    doc = Nokogiri::HTML(open('https://www.facebook.com/'+string))
    referer_string = doc.at('meta[@property="al:android:url"]')[:content]
    target = referer_string.split("?")
    target[0].slice!(0,10)
    puts "### User ID = "+target[0]
    return  target[0]

  end

  def get_email_from_string(string)
    if string.include? "@"
      # byebug
      reg = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
      email = string.scan(reg).uniq || ""
      # email = string.match(/[A-Z0-9._%+-]+@[A-Z0-9.-@]+\.[A-Z]{2,4}/i)[0]
      # email = string.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| puts x }
      if not email.first == "" and not email.first.nil?
        return email
      else
        return ""
      end
    else
      return ""
    end

  end

  def check_login
    if session["login_status"] == "1"
      return true
    else
      return false
    end
  end

  def dashboard_params
    params.permit(:target_username)
  end

end

#  https://graph.facebook.com/oauth/access_token?client_id=501092640043825&client_secret=5541c8cf05f55f7fa06cefc2dac51750&grant_type=client_credentials
# /oauth/access_token
#     ?client_id=501092640043825
#     &client_secret=5541c8cf05f55f7fa06cefc2dac51750
#     &grant_type=client_credentials
#  {"access_token":"501092640043825|b1dXFlwWMrgoVx6R7meSGvQCzUQ","token_type":"bearer"}
