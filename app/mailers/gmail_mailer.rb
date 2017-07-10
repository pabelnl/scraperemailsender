class GmailMailer < ApplicationMailer
  default from: "gabymaria28@gmail.com"

  def send(body, user, subject)
    @body = body
    @user = user
    mail(to: @user.email, subject: subject)
  end

end
