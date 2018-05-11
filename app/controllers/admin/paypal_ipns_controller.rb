# encoding: UTF-8
class Admin::PaypalIpnsController < ApplicationController
  filter_access_to :all
  layout 'management'
  
  def index
    
    @paypal_ipns = PaypalIpnLog.all
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def show
    
    @paypal_ipn = PaypalIpnLog.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def download
    
    @paypal_ipn = PaypalIpnLog.only(:id, :params_data, :created_at)
    
    respond_to do |format|
      format.xml {send_data( @paypal_ipn.to_xml, :type => 'text/xml', :filename => 'paypal_ipn_log.xml', :disposition => 'attachment' )}
      format.csv {send_data PaypalIpnLog.as_csv, :type => 'text/csv', :filename => 'paypal_ipn_log.csv', :disposition => 'attachment'}
    end
  end
  
end