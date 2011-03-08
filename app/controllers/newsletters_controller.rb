class NewslettersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    newsletter = Newsletter.new(params[:newsletter])
    if newsletter.save
      flash[:notice] = "Vous êtes maintenant inscrit à la newsletter de confort du fil"
      @page = Page.find_by_single_key('inscription_reussie')
      return redirect_to :back
    else
      flash[:error] = newsletter.errors.full_messages.first
      return redirect_to :back
    end
  end

end
