# encoding: UTF-8
class Admin::OrdersController < ApplicationController
  filter_access_to :all
  layout 'management'

  def index
    @orders = Order.all.limit(200)
    respond_to do |format|
      format.html
    end
  end

  def show
    @order = Order.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def download
    @orders = Order.all
    respond_to do |format|
      format.xml {send_data( @orders.to_xml, :type => 'text/xml', :filename => 'orders.xml', :disposition => 'attachment' )}
      format.csv {send_data( Order.as_csv,   :type => 'text/csv', :filename => 'orders.csv', :disposition => 'attachment' )}
    end
  end
end
