class ExceptionLog
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  field :error_class,   type: String, default: ''
  field :kontroller,    type: String, default: ''
  field :message,       type: String, default: ''
  field :view,          type: String, default: ''
  field :request,       type: Hash,   default: {}
  field :session_id,    type: String, default: ''
  field :session_data,  type: Hash,   default: {}
  field :environment,   type: Array,  default: []
  field :backtrace,     type: Array,  default: []

  def self.make_entry(messages)

    begin
      self.create({
          message: messages[:message],
          error_class: messages[:error_class],
          kontroller: messages[:kontroller],
          view: messages[:view],
          request: messages[:request],
          session_id: messages[:session_id],
          session_data: messages[:session_data],
          environment: messages[:environment],
          backtrace: messages[:backtrace]
      })
    rescue Exception => e
      print e.message.inspect
    end
  end
end
