# coding: utf-8
class Notifier < ActionMailer::Base

  helper_method :price_with_currency
  helper :application
  include ActionController::UrlWriter

  def validation_user_account(user, password)
    application = Setting.first.name
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :new_account])}"
    from Setting.first.email
    recipients user.email
    content_type "text/html"

    body[:user] = user
    body[:password] = password
  end

  def reset_password(user)
    application = Setting.first.name
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :reset_password])}"
    from Setting.first.email
    recipients user.email
    content_type "text/html"

    body :user => user
  end

  def newsletter(email)
    application = Setting.first.name
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :newsletter])}"
    recipients email
    from Setting.first.email
    content_type "text/html"
    body[:email] = email
  end

  def order_confirmation(user, order)
    application = Setting.first.name
    content_type "multipart/alternative"
    recipients user.email
    from Setting.first.email
    subject "[#{application}] #{I18n.t(:subject, :scope => [:emails, :order_confirmation])}"
    sent_on Time.now

    part :content_type => 'text/html', :body => render_message(
      'order_confirmation',
      :user => user,
      :order => order,
      :address_invoice => order.address_invoice,
      :address_delivery => order.address_delivery,
      :url => url_for(:action=>"root", :controller=>"url_catcher")
      )

    #TODO check PDFKIT and pdf mime_type
    current_body = {
      :user_fullname => order.user.fullname,
      :order_total => order.total,
      :order => order,
      :order_details => order.order_details,
      :user => user,
      :address_invoice => order.address_invoice,
      :address_delivery => order.address_delivery
    }

   attachment "application/pdf" do |a|
      a.filename = "#{I18n.t(:order, :scope => [:emails, :order_confirmation])}_#{application.parameterize('_')}_#{order.reference}.pdf"
      html = render(:file => '/orders/show.pdf.haml', :body => current_body, :layout => 'order_pdf')

      kit = PDFKit.new(html, :title => "#{I18n.t(:order, :scope => [:emails, :order_confirmation]).capitalize} #{order.reference}" )
      kit.stylesheets = ["#{RAILS_ROOT}/public/stylesheets/front/invoice-print.css" ]
      a.body = kit.to_pdf
    end
  end

  private
  def price_with_currency(price)
    template.number_to_currency(price, :precision => 2, :unit => '€')
  end

end
