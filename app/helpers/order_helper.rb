module OrderHelper

  def payment_methods_list
    content = ''
    setting = Setting.current

    setting.payment_method_availables.each do |payment_method|
      payment_infos = setting.payment_method_settings(payment_method)
      content += payment_radio_button_tag(payment_method, payment_infos[:image])

      if payment_method.to_sym == :cyberplus and setting.payment_method_settings_with_env(payment_method)[:payment_config] != 'SINGLE'
        if current_user.cart.total >= setting.payment_method_settings_with_env(payment_method)[:multi_minimum_cart].to_f
          content += payment_radio_button_tag("#{payment_method}_multi", payment_infos[:image_multi])
        else
          message = setting.payment_method_settings_with_env(payment_method)[:multi_message]
          flash[:warning] = message if message.present?
        end
      end
    end

    content
  end

  def payment_radio_button_tag(payment, image = '')
    payment_tag = content_tag(:div, :class => 'paiement' ) do
      radio_button_tag(:payment_type, payment, params[:payment_type] == payment.to_s) +
      content_tag(:label, t(payment, :scope => [:payment], :count => 1).capitalize )
    end
    payment_tag += image_tag(image) if image.present?
  end

  def display_cheque_message
    if Setting.current.payment_method_available?(:cheque)
      Setting.current.cheque_message(@order)
    else
      t(:not_active, :scope => [:payment]).capitalize
    end
  end

  def step_order(index=0)
    ## urls need change
    urls = [{:controller => 'cart'}, {:controller => 'order', :action => 'informations'}, {:controller => 'order', :action => 'informations'}, {:controller => 'order', :action => 'informations'}]
    labels = ['Mon panier', 'Livraison', 'Paiement', 'Validation']
    links = []

    labels.each_with_index do |label,i|
      link = link_to(label, urls[i])
      _class = 'checkout_link'
      _class += " checkout_link_#{i}"
      _class += ' current_checkout_link' if i == index
      span = content_tag(:span, link)
      div = content_tag(:div, span, :class => _class)
      links << div
    end

    content_tag(:div, links, :class => 'checkout_links')
  end

end
