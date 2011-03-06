class UsersController < ApplicationController
  before_filter :login_required, :only => [:show, :update]
  before_filter :get_orders, :only => [:show]
  before_filter :manage_address, :only => [:update]
  after_filter :update_newsletter, :only => [:update]
  around_filter FieldErrorProcChanger.new(
    Proc.new do |html_tag, instance|
      error_message = instance.object.errors.on(instance.method_name)
      if error_message && !(html_tag =~ /^<label|type="hidden"/)
        if html_tag.match(/class="/)
          html_tag.gsub!(/class="/, "class=\"error_on_this_field ")
        else
          html_tag.gsub!(/\/>$/, " class=\"error_on_this_field\"\/>")
        end
        html_tag = "#{html_tag}<div class=\"field_error\">#{error_message.is_a?(Array) ? error_message.first : error_message}</div>"
      else
        html_tag
      end
    end
  ), :only => [:create, :update]

  def show
    @user = current_user
  end

  def new
    @user = User.new(params[:user])
  end

  def create
    cookies.delete :auth_token
    @user = User.new(params[:user])
    if Forgeos::CONFIG[:account]['password_generated']
      password = generate_password(10)
      @user.attributes = {
        :password => password,
        :password_confirmation => password
      }
    end
    if @user.save
      Notifier.deliver_validation_user_account(@user, password)
      flash[:notice] = I18n.t('success', :scope => [:user, :create])
      redirect_to(login_path)
    else
      #@user.password = nil
      #@user.password_confirmation = nil
      flash[:error] = I18n.t('error', :scope => [:user, :create])
      render :action => 'new'
    end
  end

  def activate
    unless params[:activation_code].blank?
      user = User.find_by_perishable_token(params[:activation_code])
      if user
        if user.active?
          flash[:warning] = I18n.t('already_active', :scope => [:user, :activate])
          return redirect_to(:root)
        end
        user.activate
        PersonSession.create(@user, true)
        flash[:notice] = I18n.t('success', :scope => [:user, :activate])
        return redirect_to(:action => :show)
      end
    end
    flash[:error] = I18n.t('error', :scope => [:user, :activate])
    redirect_to(:root)
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = I18n.t('success', :scope => [:user, :update])
    else
      flash[:error] = I18n.t('error', :scope => [:user, :update])
    end
    render(:action => :index)
  end

  private
  def generate_password(size)
    s = ""
    size.times { s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    return s
  end

  def manage_address
    if params[:user] and params[:user][:address_invoice_attributes]
      params[:user][:address_invoice_attributes][:name] = params[:user][:lastname]
      params[:user][:address_invoice_attributes][:firstname] = params[:user][:firstname]
      params[:user][:address_invoice_attributes][:designation] = 'Première adresse'
      params[:user][:address_invoice_attributes][:civility] = params[:user][:civility]
    end
  end

  def update_newsletter
    if @user.newsletter_exist?
      unless @user.newsletter
        newsletter = Newsletter.find_by_email(@user.email)
        newsletter.destroy
      end
    elsif @user.newsletter
      Newsletter.create!(:email => @user.email)
    end
  end

  def get_orders
    # XXX Must be paginated ?
    @orders = current_user.orders.all(:conditions => {:status => ['paid','shipped']})
  end

end
