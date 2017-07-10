class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @failed_login = ""
  end

  def login

    username = login_params[:username] || ""
    password = login_params[:password] || ""

    if username == "pabel" && password == "123"
      # if username == ENV["USERNAME"] && password == ENV["PASSWORD"]
      session["login_status"] = "1"
      redirect_to "/dashboard"
    else
      # nothing
    end

  end

  def login_params
    params.permit(:username, :password)
  end

end
