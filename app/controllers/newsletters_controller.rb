class NewslettersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    newsletter = Newsletter.new(params[:newsletter])
    newsletter.email = newsletter.email.to_s.strip
    if newsletter.save
      flash[:notice] = t(:success, :scope => [:newsletter, :create])
      @page = Page.find_by_single_key('inscription_reussie')
    else
      if error = newsletter.errors.on(:email)
        flash[:error] = t(:invalid_email, :scope => [:newsletter, :create], :error => error.last)
      else
        flash[:error] = newsletter.errors.full_messages.first
      end
    end
    return redirect_to :back
  end

end
