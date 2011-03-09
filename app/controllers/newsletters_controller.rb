class NewslettersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    newsletter = Newsletter.new(params[:newsletter].to_s.strip)
    if newsletter.save
      flash[:notice] = t(:success, :scope => [:create, :newsletter])
      @page = Page.find_by_single_key('inscription_reussie')
      return redirect_to :back
    else
      flash[:error] = newsletter.errors.full_messages.first
      return redirect_to :back
    end
  end

end
