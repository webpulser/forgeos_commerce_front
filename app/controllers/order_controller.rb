class OrderController < ApplicationController
  before_filter :must_be_logged, :only => [:new, :deliveries]
  before_filter :validate_and_update_address, :only => [:new]
  skip_before_filter :verify_authenticity_token, :only => [:call_autoresponse, :paypal_notification]

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
    
    @order = Order.from_cart(current_cart)
    #TODO check for config options
    if params[:validchk]
      @order.payment_type = params[:payment_type]
      if @order.valid_for_payment?
        @order.save
        case @order.payment_type
          when "cmc_cic" ## carte bancaire
            ##CMCIC form
            @sReference = "#{rand(1000)}A#{@order.reference}" # Reference: unique, alphaNum (A-Z a-z 0-9), 12 characters max
            @sMontant = '%.2f' % @order.total # Amount : format  "xxxxx.yy" (no spaces)
            @sDevise  = "EUR" # Currency : ISO 4217 compliant
            @sTexteLibre = ""
            @sDate = DateTime.now().strftime("%d/%m/%Y:%H:%M:%S") # transaction date : format dd/mm/YYYY:HH:mm:ss
            @sLangue = "FR" # Language of the company code
            @sUrlOk = "#{request.protocol}#{request.host}#{CMCIC_URLOK}"
            @sUrlKo = "#{request.protocol}#{request.host}#{CMCIC_URLKO}"
            @sEmail = @order.user.email # customer email
            @sOptions = ""
            @oTpe = CMCIC_Tpe.new(@sLangue)
            @oMac = CMCIC_Hmac.new(@oTpe)
            @sChaineDebug = "V1.04.sha1.rb--[CtlHmac" + @oTpe.sVersion + @oTpe.sNumero + "]-" + @oMac.computeHMACSHA1("CtlHmac" + @oTpe.sVersion + @oTpe.sNumero) # Control String for support
            @sChaineMAC = [@oTpe.sNumero, @sDate, "#{@sMontant}#{@sDevise}", @sReference, @sTexteLibre, @oTpe.sVersion, @sLangue, @oTpe.sCodeSociete, @sEmail, @sNbrEch, @sDateEcheance1, @sMontantEcheance1, @sDateEcheance2, @sMontantEcheance2, @sDateEcheance3, @sMontantEcheance3, @sDateEcheance4, @sMontantEcheance4, @sOptions].join("*") # Data to certify         
          when "cyberplus"
            @url = '/'
            @site_id = "deded"
            @mode = "TEST"
            @page_action = "PAYMENT"
            @action_mode = "INTERACTIVE"
            @payment_config = "SINGLE"
            @vads_version 	= "V2"
            @sReference = "#{rand(1000)}A#{@order.reference}"
            @sDevise  = "978"
            @sMontant = '%.2f' % @order.total*100
            @key = "sdsdfgsdfgsdfg"
            values = [
              @site_id,
              @mode,
              @payment,
              @action_mode,
              @payment_config,
              @vads_version,
              @sReference,
              @sDevise,
              @sMontant,
            ]
            values = values.sort.join('+')
            @sChaineMAC = values + @key
        end
      end
    else
      #TODO use trnaslations
      flash[:error] = "Vous devez accepter les conditions générales de vente"
      render :action => 'new'
    end
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
      if params[:payment_status] == "Completed" && params[:secret] == APP_CONFIG[:paypal_secret] && params[:receiver_email] == APP_CONFIG[:paypal_email] && params[:mc_gross].to_f == @order.total.to_f
        Cart.destroy(@order.reference)
        @order.pay!
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
