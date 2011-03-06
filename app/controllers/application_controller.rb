# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

#require 'app/models/product'
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  def get_login_link
    render :partial => '/users/login_link'
  end

  def set_locale_with_config
    if Forgeos::CONFIG[:multilang]
      set_locale_without_config
    elsif locale = Forgeos::CONFIG[:default_locale]
      I18n.locale = locale
      ActiveRecord::Base.locale = locale
    end
  end
  alias_method_chain :set_locale, :config
end
