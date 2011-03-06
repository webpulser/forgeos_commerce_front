class OrdersController < ApplicationController

  def index
    @orders = Order.paginate(:conditions => {:status => ['paid', 'shipped']}, :order => :updated_at)
  end

end
