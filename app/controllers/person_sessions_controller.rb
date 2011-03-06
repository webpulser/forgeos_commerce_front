class PersonSessionsController < ApplicationController

  def new
    @person_session = PersonSession.new
    @user = User.new(params[:user])
    session[:return_to] = params[:return_to] if params[:return_to].present?
  end

  def create
    @person_session = PersonSession.new(params[:person_session])
    if @person_session.save
      if redirect = session[:return_to]
        session[:return_to] = nil
        redirect_to(redirect)
      else
        redirect_to(:action => :show)
      end
      flash[:notice] = t('log.in.success').capitalize
    else
      flash[:error] = t('log.in.failed').capitalize
      if redirect = session[:return_to]
        session[:return_to] = nil
        redirect_to(redirect)
      else
        @user = User.new
        render :action => :new
      end
    end
  end

end
