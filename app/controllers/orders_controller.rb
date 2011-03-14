class OrdersController < ApplicationController

  before_filter :login_required

  def index
    @orders = current_user.orders(:conditions => {:status => ['paid', 'shipped']}, :order => :updated_at).paginate(:page => page, :per_page => per_page)
  end

  def show
    @order = Order.first(:conditions => {:id => params[:id], :status => ['paid', 'shipped']})
    if not @order
      flash[:error] = t(:not_found, :scope => :order)
      return render :text => '', :status => 404
    elsif current_user.id != @order.user_id
      flash[:error] = t(:not_authorized)
      return render :text => '', :status => 401
    end
    @order = current_user.orders
  end

private

  def page
    params[:page].to_i > 0 ? params[:page] : 1
  end

  def per_page
    params[:per_page].to_i > 0 ? params[:per_page] : 10
  end

end
