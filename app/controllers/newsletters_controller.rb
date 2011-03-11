class NewslettersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    newsletter = Newsletter.new(params[:newsletter])
    newsletter.email = newsletter.email.to_s.strip
    if newsletter.save
      flash[:notice] = t(:success, :scope => [:create, :newsletter])
      @page = Page.find_by_single_key('inscription_reussie')
    else
      flash[:error] = newsletter.errors.full_messages.first
    end
    return redirect_to :back
  end

end
