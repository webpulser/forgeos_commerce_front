require 'sha1'
require 'CMCIC_Config'
require 'CMCIC_Tpe'
require 'cgi'
require 'ruleby'
class OrderController < ApplicationController
  before_filter :must_be_logged, :only => [:new, :deliveries]
  before_filter :validate_and_update_address, :only => [:new]
  skip_before_filter :verify_authenticity_token, :only => [:call_autoresponse_cyberplus, :paypal_notification, :success, :cancel, :call_autoresponse_cmc_cic, :call_autoresponse_elysnet, :create, :debug_colissimo]
  include Ruleby

  def new
    setting = Setting.first
    colissimo = setting.colissimo_method_list
    special_offer
    voucher
    @order = Order.from_cart(current_cart)

    if @order.valid_for_payment?
      if colissimo[:active] == 1 && current_cart.address_delivery.country.name == 'FRANCE'
        return redirect_to :action => 'so_colissimo'
      else
        options = current_cart.options || {}
        options[:colissimo] = nil
        current_cart.save
        render :action => 'new'
      end
    end
  end

  def so_colissimo
    special_offer
    voucher
    
    setting = Setting.first
    colissimo = setting.colissimo_method_list
    
    if colissimo && colissimo[:active] == 1
      if @order = Order.from_cart(current_cart)
        @_url = "#{colissimo[:url_prod]}?trReturnUrlKo=#{colissimo[:urlko]}"
        order_infos = @order.to_colissimo_params
        @colissimo = order_infos
      else
        render(:action => 'new')
      end
    end
  end

  def update_order_with_colissimo
    setting = Setting.first
    colissimo = setting.colissimo_method_list
    #pudoFOId + ceName + dyPreparationTime + dyForwardingCharges + trClientNumber+ trOrderNumber+ orderId+cléSHA
    s_chaine_mac = [params[:PUDOFOID], params[:CENAME], params[:DYPREPARATIONTIME], params[:DYFORWARDINGCHARGES], params[:TRCLIENTNUMBER], params[:TRORDERNUMBER], params[:ORDERID], colissimo[:sha] ].join('')

    if Digest::SHA1.hexdigest(s_chaine_mac) == params[:SIGNATURE]
      if @order && @order.reference.to_i == params[:ORDERID].split('m').last.to_i
        options = current_cart.options || {}
        options[:colissimo] = params
        current_cart.save
        @order.update_attributes_from_colissimo(params)
        if @order.valid_for_payment?
          return render :action => 'new'
        else
          return render :action => 'deliveries'
        end
      else
        @params = { :order => @order, :order_ref => @order.reference }
        flash[:error] = "La commande n° #{params[:ORDERID].split('m').last.to_i} est introuvable, identifiant de votre panier est #{@order.reference}"
        return render :action => 'deliveries'
      end
    else
      flash[:error] = 'Une erreur est survenue lors la vérification des données'
      @params = { :order => @order, :order_ref => @order.reference }
      render :action => 'deliveries'
    end
  end

  def create
    special_offer
    voucher
    setting = Setting.first
    colissimo = setting.colissimo_method_list

    @order = Order.from_cart(current_cart)
    #If so colissimo enabled && params[SIGNATURE]
    if colissimo && colissimo[:active] == 1 && !params[:SIGNATURE].nil?
      update_order_with_colissimo
      return true
    end

    unless params[:payment_type]
      flash[:error] = "Vous devez choisir un moyen de paiement"
      return render :action => 'new'
    end
    
    unless setting.payment_method_list[params[:payment_type].to_sym] && setting.payment_method_list[params[:payment_type].to_sym][:active] == 1
      flash[:error] = "Ce moyen de paiement n'est pas disponible"
      return render :action => 'new'
    end
    env = setting.payment_method_list[params[:payment_type].to_sym][:test] == 1 ? :development : :production

    if params[:validchk]
      @order.payment_type = t(params[:payment_type], :scope => 'payment', :count => 1)
      if @order.valid_for_payment?
        @order.save
        case @order.payment_type
          when t("cmc_cic", :scope => 'payment', :count => 1)
            @payment = @order.cmc_cic_encrypted
          when t("cyberplus", :scope => 'payment', :count => 1)
            @payment = @order.cyberplus_encrypted
          when t("cheque", :scope => 'payment', :count => 1)
            @order.wait_for_cheque!
            Cart.destroy(@order.reference)
            render :action => 'cheque_payment'
          when t("paypal", :scope => 'payment', :count => 1)
            @url_paypal = setting.payment_method_list[:paypal][env][:url]
          when t("elysnet", :scope => 'payment', :count => 1)
            @payment = @order.elysnet_encrypted
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
        if params[:payment_status] == "Completed" && params[:secret] == secret && params[:receiver_email] == email && params[:mc_gross].to_f.to_s == @order.total.to_f.to_s
          if cart = Cart.find_by_id(@order.reference)
            cart.destroy
          end
          @order.pay!
        end
      end
    end
    render :nothing => true
  end

  def call_autoresponse_elysnet
    message = params['DATA']
    @result = `./lib/elysnet/bin/response pathfile=./lib/elysnet/param/pathfile message=#{message}` #execution of response script

    @response = @result.split("!")

    @code = @response[1]
    @error = @response[2]
    @merchant_id = @response[3]
    @merchant_country = @response[4]
    @amount = @response[5]
    @transaction_id = @response[6]
    @payment_means = @response[7]
    @transmission_date = @response[8]
    @payment_time = @response[9]
    @payment_date = @response[10]
    @response_code = @response[11]
    @payment_certificate = @response[12]
    @authorisation_id = @response[13]
    @currency_code = @response[14]
    @card_number = @response[15]
    @cvv_flag = @response[16]
    @cvv_response_code = @response[17]
    @bank_response_code = @response[18]
    @complementary_code = @response[19]
    @complementary_info= @response[20]
    @return_context = @response[21]
    @caddie = @response[22]
    @receipt_complement = @response[23]
    @merchant_language = @response[24]
    @language = @response[25]
    @customer_id = @response[26]
    @order_id = @response[27]
    @customer_email = @response[28]
    @customer_ip_address = @response[29]
    @capture_day = @response[30]
    @capture_mode = @response[31]
    @data = @response[32]

    if @response_code == "00"
      @order = Order.find(@order_id)
      if @order.pay!
        @order.update_attributes!(:transaction_number => @transaction_id)
        if cart = Cart.find_by_id(@order.reference)
          cart.destroy
        end
        render :text => true
      else
        render :text => false, :status => 500
      end
    else
      render :text => false, :status => 500
    end
  end

private
  def must_be_logged
    unless current_user
      session[:return_to] = {:controller => 'order', :action => 'new'}
      return redirect_to(login_path(:quick => '1'))
    end
  end

  def validate_and_update_address
    if params[:order] and params[:order][:address_invoice_attributes] and params[:order][:address_delivery_attributes]
      address_invoice = current_user.address_invoices.find_or_create_by_id(params[:order][:address_invoice_attributes])
      address_delivery = current_user.address_deliveries.find_or_create_by_id(params[:order][:address_delivery_attributes])

      if address_delivery.update_attributes(params[:order][:address_delivery_attributes]) && address_invoice.update_attributes(params[:order][:address_invoice_attributes])
        options = current_cart.options || {}
        options[:address_invoice_id] = address_invoice.id
        options[:address_delivery_id] = address_delivery.id
        current_cart.save

        special_offer
        voucher
        #have to check transporter after upodate address_delivery  => 2 saves :/
        transporter_rule

        options[:transporter_rule_id] = @transporter_ids
        
        change = false
        if current_user.lastname.blank?
          change = true
          current_user.lastname = address_invoice.name
        end
        
        if current_user.firstname.blank?
          change = true
          current_user.firstname = address_invoice.firstname
        end
        
        if change
          current_user.save
        end
        
        current_cart.save
      else
        @order = Order.new(params[:order])
        @order.valid?
        flash[:error] = "Il y a une erreur dans l'adresse de facturation ou de livraison"
        render :action => "deliveries"
      end
    else
      redirect_to :action => 'deliveries'
    end
  end

  def special_offer
    begin
      engine :special_offer_engine do |e|
        rule_builder = SpecialOffer.new(e)
        rule_builder.cart = current_cart
        @free_product_ids = []
        rule_builder.free_product_ids = @free_product_ids
        rule_builder.rules
        current_cart.cart_items.each do |cart_product|
          e.assert cart_product.product
        end
        e.assert current_cart
        e.match
      end
    rescue Exception
    end
  end

  def voucher
    begin
      engine :voucher_engine do |e|
        rule_builder = Voucher.new(e)
        rule_builder.cart = current_cart
        rule_builder.code = @voucher_code || session[:voucher_code]
        rule_builder.free_product_ids = @free_product_ids
        rule_builder.rules
        current_cart.cart_items.each do |cart_product|
          e.assert cart_product.product
        end
        e.assert current_cart
        e.match
      end
    rescue Exception
    end
  end

  def transporter_rule
    @transporter_ids = []
    begin
      engine :transporter_engine do |e|
        rule_builder = Transporter.new(e)
        rule_builder.transporter_ids = @transporter_ids
        rule_builder.cart = current_cart
        rule_builder.rules
        current_cart.cart_items.each do |cart_product|
          e.assert cart_product.product
        end
        e.assert current_cart
        e.match
      end
    rescue Exception => e
      logger.warn e.message
    end
  end


end
