class PaypalIpnLog
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :raw_data,        type: String
  field :params_data,    type: Hash
  
  
  def self.number_of_logs(period = 'all')
    
    if period == 'month' then
      return self.where(:created_at.gt => Time.now.at_beginning_of_month.utc).count()
    end
    
    if period == 'year' then
      return self.where(:created_at.gt => Time.now.at_beginning_of_year.utc).count()
    end
    
    return self.all.count()
  end
  
  
  def self.as_csv
    
    ipn_logs = self.only(:params_data, :created_at)
    ipn_list = CSV.generate({:col_sep => '|'}) do |csv|
      csv << %w(mc_gross created_at)
      
      ipn_logs.each do |ipn_log|
        csv << [ipn_log.params_data['mc_gross'], ipn_log.created_at]
      end
    end
    
    return ipn_list
  end
  
end
