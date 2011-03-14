class OrdersController < ApplicationController

  def index
    @orders = Order.paginate(:conditions => {:status => ['paid', 'shipped']}, :order => :updated_at, :page => page, :per_page => per_page)
  end

private

  def page
    params[:page].to_i > 0 ? params[:page] : 1
  end

  def per_page
    params[:per_page].to_i > 0 ? params[:per_page] : 10
  end

end
