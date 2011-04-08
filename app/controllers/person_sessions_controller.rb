class PersonSessionsController < ApplicationController

  def new
    @person_session = PersonSession.new
    @user = User.new(params[:user])
    session[:return_to] = params[:return_to] if params[:return_to].present?
  end

  def create
    @person_session = PersonSession.new(params[:person_session])
    if @person_session.save
      redirect_to_stored_location(:user)
      flash[:notice] = t('log.in.success').capitalize
    else
      flash[:error] = t('log.in.failed').capitalize
      redirect_to_stored_location do
        @user = User.new
        render :action => :new
      end
    end
  end

end
