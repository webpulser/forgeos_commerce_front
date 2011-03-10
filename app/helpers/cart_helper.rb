module CartHelper

  # Display a link to remove a cart product from the current cart
  def remove_cart_product_link(cart_product_id)
    link_to_function 'supprimer', remote_function(:url => { :controller => 'cart', :action => 'delete_product', :id => cart_product_id} , :confirm =>  'Voulez-vous vraiment supprimer ce produit de votre panier ?'), :class => 'delete_product'
  end
  
  # Display the voucher form
  def display_voucher
    content = "<span> Bénéficiez-vous d'un code avantage ?</span>"
    content += "<div class='voucherbox'> <label> Code avantage </label>"
    content += text_field_tag(:voucher_code, "", :id => 'voucher_code') + ""
    content +=
      button_to_function(
        'Valider le code',
        remote_function(
          :url => {:controller => 'cart', :action => 'add_voucher'},
          :with => "'voucher_code='+$('#voucher_code').val()"
        ),
        :class => 'no-custom'
      )
    content += "</div>"
  end
end