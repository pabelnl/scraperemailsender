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
    count = 1
    current_page = ""
    # Init Koala for facebook api
    @array = Array.new
    @graph = Koala::Facebook::API.new()
    puts "### Facebook API initialized"

    if not dashboard_params[:target_username] == nil and not dashboard_params[:target_username] == ""
      target_username = dashboard_params[:target_username]
      puts "### Username = "+target_username
      # @graph.get_connection('171572419565247', 'posts')
      target_feed = @graph.get_connections(get_userid_from_string(target_username), 'posts', fields: "message,id,created_time,comments.fields(comments.fields(from,message),message,from),from", limit: 100)
      current_page = target_feed
      if not target_feed == nil and not target_feed == ""
        puts "### Iterating feed posts "
        posts_loop(target_feed)
        #Check for other result page
        while count <= 4
          if not current_page.nil?
            next_page = current_page.next_page
            current_page = next_page
            if not next_page == nil and not next_page == ""
              puts "### Iterating Next page for Feed posts "
              puts "### PAGE "+count.to_s
              posts_loop(target_feed)
            else
              puts "### No more feed posts"
            end
          else
            puts "### No more feed posts"
          end
          count = count + 1
        end
        # We clean the array from duplicates
        unique = @array.uniq
        puts "### Cleaning up the results"
        # We return a json with the array
        render json: {users: unique}, status: 200
      else
        puts "### No feed posts"
      end
    else
      puts "### No username given"
    end
  end

  def posts_loop(target_feed)
      target_feed.each do |post|
        post_id = post["id"]
        if post["comments"]
          comments = @graph.get_connections(post_id, 'comments', limit: 300)
          puts "### Getting post = "+post_id.to_s+"'s comments"
          if not comments.nil? and comments.count > 0
            comments_loop(comments)
          end
        else
          puts "### Post doesn't have comments"
        end
      end

  end

  def comments_loop(comments)
    comments.each do |data|
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
