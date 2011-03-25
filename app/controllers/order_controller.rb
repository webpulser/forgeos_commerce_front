require 'sha1'
require 'CMCIC_Config'
require 'CMCIC_Tpe'
require 'cgi'
class OrderController < ApplicationController
  before_filter :must_be_logged, :only => [:new, :deliveries]
  before_filter :validate_and_update_address, :only => [:new]
  skip_before_filter :verify_authenticity_token, :only => [:call_autoresponse_cyberplus, :paypal_notification, :success, :cancel, :call_autoresponse_cmc_cic]

  def new
    special_offer
    voucher
    @order = Order.from_cart(current_cart)
    unless @order.valid_for_payment?
      render :action => 'new'
    end
  end
  
  def create
    special_offer
    voucher
    setting = Setting.first
    if params[:payment_type].nil?
      flash[:error] = "Vous devez choisir un moyen de paiement"
      return redirect_to :action => 'new'
    end
    unless setting.payment_method_list[params[:payment_type].to_sym] && setting.payment_method_list[params[:payment_type].to_sym][:active] == 1
      flash[:error] = "Ce moyen de paiement n'est pas disponible"
      return redirect_to :action => 'new'
    end
    env = setting.payment_method_list[params[:payment_type].to_sym][:test] == 1 ? :development : :production
    @order = Order.from_cart(current_cart)
    if params[:validchk]
      @order.payment_type = t(params[:payment_type], :scope => 'payment')
      if @order.valid_for_payment?
        @order.save
        case @order.payment_type
          when t("cmc_cic", :scope => 'payment') ## carte bancaire
            ##CMCIC form
            @payment = @order.cmc_cic_encrypted
          when t("cyberplus", :scope => 'payment')
            @payment = @order.cyberplus_encrypted
          when t("cheque", :scope => 'payment')
            @order.wait_for_cheque!
            render :action => 'cheque_payment'
          when t("paypal", :scope => 'payment')
            @url_paypal = setting.payment_method_list[:paypal][env][:url]
        end
      end
    else
      #TODO use translations
      flash[:error] = "Vous devez accepter les conditions générales de vente"
      render :action => 'new'
    end
  end
  
  
  def cheque_payment
  end
  
  def call_autoresponse_cmc_cic
    setting = Setting.first
    if setting.payment_method_list[:cmc_cic] && setting.payment_method_list[:cmc_cic][:active]
      oTpe = CMCIC_Tpe.new()
      oHmac = CMCIC_Hmac.new(oTpe)

      sChaineMAC = [oTpe.sNumero, params["date"], params['montant'], params['reference'], params['texte-libre'], oTpe.sVersion, params['code-retour'], params['cvx'], params['vld'], params['brand'], params['status3ds'], params['numauto'], params['motifrefus'], params['originecb'], params['bincb'], params['hpancb'], params['ipclient'], params['originetr'], params['veres'], params['pares']].join('*') + "*";


      if oHmac.isValidHmac?(sChaineMAC, params['MAC'])
        case params['code-retour']
          when "payetest":
            # Payment has been accepted on the test server
            # put your code here (email sending / Database update)
            @order = Order.find_by_reference(params[:reference].split('A').last)
            if @order
              @order.pay!
              Cart.destroy(@order.reference)
            else
              status = :bad_request
            end
          when "paiement":
            # Payment has been accepted on the productive server
            # put your code here (email sending / Database update)
            @order = Order.find_by_reference(params[:reference].split('A').last)
            if @order
              @order.pay!
              Cart.destroy(@order.reference)
            else
              status = :bad_request
            end
          else
            status = :bad_request
          end
          sResult = "0"
      else
        # your code if the HMAC doesn't match
        sResult = "1\n" + sChaineMAC
      end

      #-----------------------------------------------------------------------------
      # Send receipt to CMCIC server
      #-----------------------------------------------------------------------------
      render :text => "Pragma: no-cache\nContent-type: text/plain\n\nversion=2\ncdr=" + sResult
    else
      render :text => false, :status => 500
    end
  end

  def call_autoresponse_cyberplus
    setting = Setting.first
    if setting.payment_method_list[:cyberplus] && setting.payment_method_list[:cyberplus][:active]
      if @order = Order.find_by_id(params[:order_id])
        Cart.destroy(@order.reference)
        @order.update_attribute(:transaction_number,params[:trans_id])
        if params[:result] == '00'
          @order.pay!
        elsif params[:result] == '17'
          @order.cancel!
        end
        render :text => true
      else
        render :text => false, :status => 500
      end
    else
      render :text => false, :status => 500
    end
  end

  
  def cancel
    flash[:error] = 'Le paiement a été annulé'
    redirect_to '/commande-anulee'
  end

  def success
    flash[:success] = 'Le paiement a été validé'
    redirect_to '/commande-validee'
  end
  
  def deliveries
    params[:order] ||= {}
    params[:order][:address_invoice_attributes] ||= current_user.address_invoice.attributes.merge(:id => nil) if current_user.address_invoice
    params[:order][:address_delivery_attributes] ||= current_user.address_delivery.attributes.merge(:id => nil) if current_user.address_delivery
    params[:order][:address_invoice_attributes] ||= current_cart.address_invoice.attributes if current_cart.address_invoice
    params[:order][:address_delivery_attributes] ||= current_cart.address_delivery.attributes if current_cart.address_delivery
    @order = Order.new(params[:order])
  end
  
  def paypal_notification
    @order = Order.find_by_id(params[:invoice])
    unless @order.nil?
      setting = Setting.first
      if setting.payment_method_list[:paypal] && setting.payment_method_list[:paypal][:active]
        env = setting.payment_method_list[:paypal][:test] == 1 ? :development : :production
        secret = setting.payment_method_list[:paypal][env][:secret]
        email = setting.payment_method_list[:paypal][env][:email]
        if params[:payment_status] == "Completed" && params[:secret] == secret && params[:receiver_email] == email && params[:mc_gross].to_f == @order.total.to_f
          if cart = Cart.find_by_id(@order.reference)
            cart.destroy
          end
          @order.pay!
        end
      end
    end
    render :nothing => true
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
