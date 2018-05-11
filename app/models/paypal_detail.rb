class PaypalDetail
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token,           type: String, default: ''
  field :payer_id,        type: String, default: ''
  field :params_data,     type: Hash, default: {}
  field :message,         type: String, default: ''
  field :test,            type: Boolean, default: false
  field :authorization,   type: String, default: ''
  field :avs_result,      type: String, default: ''
  field :raw_data,        type: String, default: ''
  field :order_id,        type: BSON::ObjectId
  field :order_number,    type: String, default: ''
  field :action,          type: String, default: ''


  def self.log_details(params, details, order, action)
    self.create!(
        token: params[:token],
        payer_id: params[:PayerID],
        params_data: details.params,
        message: details.message,
        test: details.test,
        authorization: details.authorization,
        avs_result: details.avs_result,
        raw_data: details.inspect,
        order_id: order.id,
        order_number: order.order_number,
        action: action
      )
  end

end
