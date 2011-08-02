module OrderHelper

  def payment_methods_list
    available_payments = []
    setting = Setting.first
    payment_infos = setting.payment_method_list
    payment_infos.each do |key, values|
      if values[:active] == 1
        available_payments << key
      end
    end
    content = ""
    available_payments.each do |payment_method|
      payment_tag = content_tag(:div, :class => 'paiement' ) do
        radio_button_tag( :payment_type, payment_method, params[:payment_type] == payment_method.to_s) +
        content_tag(:label, t(payment_method, :scope => [:payment], :count => 1).capitalize )
      end
      if payment_infos[payment_method.to_sym][:image].present?
        payment_tag  += image_tag(payment_infos[payment_method.to_sym][:image])
      end

      if payment_method == :cyberplus and payment_infos[payment_method.to_sym][:payment_config] != 'SINGLE'
        pm = "#{payment_method}_multi"
        payment_tag += content_tag(:div, :class => 'paiement' ) do
          radio_button_tag( :payment_type, pm, params[:payment_type] == pm) +
          content_tag(:label, t(pm, :scope => [:payment], :count => 1).capitalize )
        end
        if payment_infos[payment_method.to_sym][:image].present?
          payment_tag  += image_tag(payment_infos[payment_method.to_sym][:image].sub(/\.\(\w+\)$/, "_multi.#{$1}"))
        end
      end

      content += payment_tag
    end
    return content
  end

  def display_cheque_message
    if payment_infos = YAML.load(Setting.first.payment_methods)
      if payment_infos[:cheque] && payment_infos[:cheque][:active] == 1
        content = Setting.first.cheque_message(@order)
      else
        content = t(:not_active, :scope => [:payment]).capitalize
      end
    else
      content = t(:not_active, :scope => [:payment]).capitalize
    end
    return content
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
