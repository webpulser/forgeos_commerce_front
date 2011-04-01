require 'ruleby'
class CartController < ApplicationController
  include Ruleby
  skip_before_filter :verify_authenticity_token, :only => [:add_product]
  skip_before_filter :get_menu, :only => [:update_quantity, :delete_product]
  before_filter :special_offer, :only => [:index, :add_voucher]
  before_filter :check_voucher_code, :only => [:add_voucher]
  before_filter :voucher, :only => [:index, :add_voucher]

  def index
    
  end
  
  ## add a product
  def add_product
    if params[:id]
      current_cart.add_product_id( params[:id],1 )
      redirect_to(:action => 'index')
    else
      redirect_to(:back)
    end
  end
  
  ## delete or add a product
  def update_quantity
    cart_product = current_cart.cart_items.find_by_id(params[:id])
    unless cart_product.nil?
      new_quantity = params[:quantity].to_i
      if cart_product.quantity < new_quantity  ## add a product
        if !cart_product.product.stop_sales
          cart_product.update_attributes( :quantity => new_quantity )
        elsif cart_product.product.stock >= new_quantity
          cart_product.update_attributes( :quantity => new_quantity )
        else
          flash[:quantity_warning] = "Le stock disponible est insuffisant."
        end
      else ## delete a product
        cart_product.update_attributes( :quantity => new_quantity )
      end
    end

    current_cart.reload

    special_offer
    voucher
    
    if request.xhr?
      render(:update) do |page|
        page.replace_html 'tbody', :partial => 'tbody'
        page.replace_html 'cart_total', :partial => 'total'
        page.replace_html 'free_products', :partial => 'free_products'
      end
    end
  end
  
  def delete_product
    cart_product = current_cart.cart_items.find_by_id(params[:id])
    current_cart.cart_items.find_all_by_product_id(cart_product.product_id).collect(&:delete) unless cart_product.nil?
    special_offer
    voucher
    if request.xhr?
      render(:update) do |page|
        page.replace_html 'tbody', :partial => 'tbody'
        page.replace_html 'cart_total', :partial => 'total'
      end
    end
  end
  
  def add_voucher
    voucher = VoucherRule.find_by_id(current_cart.voucher)
    if voucher.nil?
      session.delete(:voucher_code)
      render(:update) do |page|
        page.replace_html 'voucher_message' , "<span>Le code promo #{@voucher_code} est invalide2.</span>"
        page.replace_html 'tbody',  :partial => 'tbody'
        page.replace_html 'cart_total', :partial => 'total'
        page.replace_html 'free_products', :partial => 'free_products'
      end
    else
      session[:voucher_code] = voucher.code
      render(:update) do |page|
        page.replace_html 'voucher_message' , "<span>Code validé ! #{voucher.name}</span>"
        page.replace_html 'tbody',  :partial => 'tbody'
        page.replace_html 'cart_total', :partial => 'total'
        page.replace_html 'free_products', :partial => 'free_products'
      end
    end
  end
    
  def get_cart_items_count
    render :text => "#{current_cart.cart_items.count} articles"
  end  
    
private
  def check_voucher_code
    @voucher_code = params[:voucher_code] || session[:voucher_code]
    voucher = VoucherRule.find_all_by_active_and_code(true,@voucher_code)
    #get_transporters ## because the shipping was maybe offer with a voucher
    render(:update) do |page|
      page.replace_html 'voucher_message' , "<span>Le code promo #{@voucher_code} est invalide.</span>"
      page.replace_html 'tbody',  :partial => 'tbody'
      page.replace_html 'cart_total', :partial => 'total'
      session.delete(:voucher_code) if session[:voucher_code]
    end if voucher.blank? or voucher.nil?
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
  
end
