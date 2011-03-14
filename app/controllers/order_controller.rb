class OrderController < ApplicationController
  before_filter :must_be_logged, :only => [:new, :deliveries]
  before_filter :validate_and_update_address, :only => [:new]
  
  def new
    
    
    
    @order = Order.new(params[:order])
  end
  
  def deliveries
    params[:order] ||= {}
    params[:order][:address_invoice_attributes] ||= current_user.address_invoice.attributes.merge(:id => nil) if current_user.address_invoice
    params[:order][:address_delivery_attributes] ||= current_user.address_delivery.attributes.merge(:id => nil) if current_user.address_delivery
    params[:order][:address_invoice_attributes] ||= current_cart.address_invoice.attributes if current_cart.address_invoice
    params[:order][:address_delivery_attributes] ||= current_cart.address_delivery.attributes if current_cart.address_delivery
    @order = Order.new(params[:order])
  end
  
private
  def must_be_logged
    unless current_user
      session[:return_to] = {:controller => 'order', :action => 'new'}
      return redirect_to(:login)
    end
  end
  
  def validate_and_update_address
    if params[:order] and params[:order][:address_invoice_attributes] and params[:order][:address_delivery_attributes]
      address_invoice = current_user.address_invoices.find_or_create_by_id(params[:order][:address_invoice_attributes])
      address_delivery = current_user.address_deliveries.find_or_create_by_id(params[:order][:address_delivery_attributes])
            
      if address_delivery.update_attributes(params[:order][:address_delivery_attributes]) && address_invoice.update_attributes(params[:order][:address_invoice_attributes])
        current_cart.options[:address_invoice_id] = address_invoice.id
        current_cart.options[:address_delivery_id] = address_delivery.id
      else
        @order = Order.new(params[:order])
        flash[:error] = "Il y a une erreur dans l'adresse de facturation ou de livraison"
        render :action => "deliveries"        
      end
    else
      redirect_to :action => 'deliveries'
    end
  end

end