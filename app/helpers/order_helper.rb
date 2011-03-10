module OrderHelper
  
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