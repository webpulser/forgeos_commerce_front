class AddressesController < ApplicationController
  #before_filter :manage_address, :only => [:create]
  #before_filter :login_required, :only => [:show, :update]
  before_filter :get_address, :only => [:show, :update]
  skip_before_filter :verify_authenticity_token

  def show
    respond_to do |format|
      format.html { page_not_found }
      format.json { render :json => @address.to_json }
    end
  end

  def new
    @address = UserAddress.new(params[:address])
    render(:update) do |page|
      page.replace_html '#delivery_address .account-form', :partial => 'address_form', :locals => {:address => @address}
    end
  end

  def update
    if @address.update_attributes(params[:address])
      flash[:notice] = I18n.t('address_update_ok').capitalize
    else
      flash[:error] = "Une erreur est survenue lors de la mise à jour de l'addresse"
    end
    render(:update) do |page|
      page.replace_html '#delivery_address .account-form', :partial => 'address_form', :locals => {:address => @address}
    end
  end

private

  #def manage_address
  #  if params[:user] && params[:user][:address_invoice_attributes]
  #    params[:user][:address_invoice_attributes][:name] = params[:user][:lastname]
  #    params[:user][:address_invoice_attributes][:firstname] = params[:user][:firstname]
  #    params[:user][:address_invoice_attributes][:phone] = params[:user][:phone]
  #    params[:user][:address_invoice_attributes][:email] = params[:user][:email]
  #    params[:user][:address_invoice_attributes][:designation] = 'Première adresse'
  #    params[:user][:address_invoice_attributes][:civility] = params[:civility]

  #    params[:user][:address_delivery_attributes] = params[:user][:address_invoice_attributes]
  #    params[:user][:address_delivery_attributes][:designation] = 'Seconde adresse'
  #  end
  #end

  def get_address
    @address = UserAddress.first(:conditions => ['id = ? AND person_id IS NOT NULL', params[:id]])
    if not @address
      flash[:error] = 'Utilisateur non trouvé'
      return render :nothing => true, :status => 404
    elsif not current_user
      flash[:error] = 'Vous devez être connecté pour avoir accès à cette ressource'
      return render :nothing => true, :status => 401
    elsif current_user.id != @address.person_id
      flash[:error] = 'Accès interdit'
      return render :nothing => true, :status => 401
    end
  end

  def destroy
    if @address.destroy
      flash[:notice] = "L'adresse a bien été supprimée"
    else
      flash[:error] = "Une erreur est survenue lors de la suppression de l'adresse"
    end
    render :nothing => true
  end

end
