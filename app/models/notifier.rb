# coding: utf-8
class Notifier < ActionMailer::Base

  helper_method :price_with_currency
  helper :application
  include Rails.application.routes.url_helpers

  def validation_user_account(user, password)

    @user = user
    @password = password

    mail(
      :from => Setting.current.email,
      :to => user.email,
      :subject => "[#{Setting.current.name}] #{I18n.t(:subject, :scope => [:emails, :new_account])}"
    )
  end

  def reset_password(user)
    @user = user

    mail(
      :to => user.email,
      :from => Setting.current.email,
      :subject => "[#{Setting.current.name}] #{I18n.t(:subject, :scope => [:emails, :reset_password])}"
    )
  end

  def newsletter(email)
    @email = email
    mail(
      :to => email,
      :subject => "[#{Setting.current.name}] #{I18n.t(:subject, :scope => [:emails, :newsletter])}",
      :from => Setting.current.email
    )
  end

  def order_confirmation(user, order)

    @user = user
    @order = order
    @address_delivery = order.address_delivery
    @address_invoice = order.address_invoice
    @url = url_for(:action=>"root", :controller=>"url_catcher")

    # Rendering PDF file
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

    html = render(:file => '/orders/show.pdf.haml', :body => current_body, :layout => 'order_pdf')

    kit = PDFKit.new(html, :title => "#{I18n.t(:order, :scope => [:emails, :order_confirmation]).capitalize} #{order.reference}" )
    kit.stylesheets = [Rails.root.join('public', 'stylesheets', 'front', 'invoice-print.css')]

    attachments["#{application.parameterize('_')}_#{I18n.t(:order, :scope => [:emails, :order_confirmation])}_#{order.reference}.pdf"] = kit.to_pdf

    mail(
      :to => user.email,
      :from => Setting.current.email,
      :subject => "[#{Setting.current.name}] #{I18n.t(:subject, :scope => [:emails, :order_confirmation], :id => order.reference)}"
    )

  end

  def waiting_for_cheque_notification(order)
    @order = order
    mail(
      :to => order.user.email,
      :from => Setting.current.email,
      :subject => "[#{Setting.current.name}] #{I18n.t(:subject, :scope => [:emails, :waiting_for_cheque_notification])}"
    )
  end

  private
  def price_with_currency(price)
    template.number_to_currency(price, :precision => 2, :unit => '€')
  end

end
