# encoding: UTF-8
class Admin::NewslettersController < ApplicationController
  filter_access_to :all
  layout 'management'
  include ApplicationHelper
  
  def index    
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def download
    
    subscribers = Newsletter.where(:activated_at.ne => nil)
    letters = Account.where(:newsletter => true)
  
    results = (subscribers.to_a | letters.to_a)

    file = CSV.generate({:col_sep => ';'}) do |csv|
      csv << %w(From-Account)
      csv << %w(E-mail Activated Name Country Listingnumber Expires)
      letters.each do |row|
        csv << [row.contact.email, standard_date(row.activated_at, "%F"), row.contact.name, row.country_short, row.get_listing_numbers, standard_date(row.current_subscription.try(:expires_at), "%F")]
      end
      csv << %w(From-Newsletter)
      csv << %w(E-mail Activated Name Country Listingnumber Expires)
      subscribers.each do |row|
        csv << [row.email, standard_date(row.activated_at, "%F"), 'NO NAME', row.country_short, 'NO LISTING', 'NO EXPIRE']
      end
      
    end
    
    respond_to do |format|
      format.xml {send_data( subscribers.to_xml, :type => 'text/xml', :filename => 'subscriber_email_list.xml', :disposition => 'attachment' )}
      format.csv {send_data file, :type => 'text/csv', :filename => 'subscriber_email_list.csv', :disposition => 'attachment'}
    end
    
  end
  
end
