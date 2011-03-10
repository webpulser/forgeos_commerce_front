# coding: utf-8
class Notifier < ActionMailer::Base

  helper_method :price_with_currency
  helper :application
  include ActionController::UrlWriter

  def validation_user_account(user, password)
    application = Setting.first.name
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :new_account])}"
    from Setting.first.email
    recipients user.email
    content_type "text/html"

    body[:user] = user
    body[:password] = password
  end

  def password_reset_instructions(user, password)
    application = Setting.first.name
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :reset_password])}"
    from Setting.first.email
    recipients user.email
    content_type "text/html"

    body :user => url
  end

  def newsletter(email)
    application = Setting.first.name
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :newsletter])}"
    recipients email
    from Setting.first.email
    content_type "text/html"
    body[:email] = email
  end

  private
  def price_with_currency(price)
    template.number_to_currency(price, :precision => 2, :unit => '€')
  end

end
