require 'sha1'
class OrderController < ApplicationController
  before_filter :must_be_logged, :only => [:new, :deliveries]
  before_filter :validate_and_update_address, :only => [:new]
  skip_before_filter :verify_authenticity_token, :only => [:call_autoresponse, :paypal_notification, :success, :cancel]

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
      @order.payment_type = t(params[:payment_type], :scope => 'payment')
      if @order.valid_for_payment?
        @order.save
        case @order.payment_type
          when t("cmc_cic", :scope => 'payment') ## carte bancaire
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
          when t("cyberplus", :scope => 'payment')
            ts = Time.now

            @payment = {
              :version => 'V1',
              :site_id => '49234738',
              :ctx_mode => 'TEST',
              :trans_id => ts.strftime('%H%M%S'),
              :trans_date => ts.strftime('%Y%m%d%H%M%S'),
              :validation_mode => '',
              :capture_delay => '',
              :payment_config => 'SINGLE',
              :payment_cards => 'VISA;MASTERCARD;CB',
              :amount => (@order.total*100).to_i,
              :currency => '978',
              :key => '6852324211274299',
              :url_cancel => url_for(:action => 'cancel'),
              :url_success => url_for(:action => 'success'),
              :url_refused => url_for(:action => 'cancel'),
              :url_return => url_for(:action => 'new'),
              :url_referral => url_for(:action => 'new'),
              :order_id => @order.id
            }

            sign = [:version, :site_id, :ctx_mode, :trans_id,
                     :trans_date, :validation_mode, :capture_delay,
                     :payment_config, :payment_cards, :amount,
                     :currency, :key].map{ |key| @payment[key] }
                     
            @payment[:signature] = SHA1.new(sign.join('+'))

        end
      end
    else
      #TODO use translations
      flash[:error] = "Vous devez accepter les conditions générales de vente"
      render :action => 'new'
    end
  end
  
  
  def call_autoresponse
#    TODO check payment autoresponse
#    oTpe = CMCIC_Tpe.new()
#    oHmac = CMCIC_Hmac.new(oTpe)

#    sChaineMAC = [oTpe.sNumero, params["date"], params['montant'], params['reference'], params['texte-libre'], oTpe.sVersion, params['code-retour'], params['cvx'], params['vld'], params['brand'], params['status3ds'], params['numauto'], params['motifrefus'], params['originecb'], params['bincb'], params['hpancb'], params['ipclient'], params['originetr'], params['veres'], params['pares']].join('*') + "*";


#    if oHmac.isValidHmac?(sChaineMAC, params['MAC'])
#      case params['code-retour']
#        when "payetest":
#          # Payment has been accepted on the test server
#          # put your code here (email sending / Database update)
#          @order = Order.find_by_reference(params[:reference].split('A').last)
#          if @order
#            @order.pay!
#            Cart.destroy(@order.reference)
#          else
#            status = :bad_request
#          end
#        when "paiement":
#          # Payment has been accepted on the productive server
#          # put your code here (email sending / Database update)
#          @order = Order.find_by_reference(params[:reference].split('A').last)
#          if @order
#            @order.pay!
#            Cart.destroy(@order.reference)
#          else
#            status = :bad_request
#          end
#        else
#          status = :bad_request
#        end
#        sResult = "0"
#    else
#      # your code if the HMAC doesn't match
#      sResult = "1\n" + sChaineMAC
#    end

#    #-----------------------------------------------------------------------------
#    # Send receipt to CMCIC server
#    #-----------------------------------------------------------------------------
#    render :text => "Pragma: no-cache\nContent-type: text/plain\n\nversion=2\ncdr=" + sResult
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
