class MatchAlert
  include Mongoid::Document
  include ActiveModel::ForbiddenAttributesProtection

  embedded_in :account,   :class_name => Account.to_s
  embeds_many :locations, :class_name => Location.to_s

  field :active,                  type: Boolean,  default: false
  field :adults,                  type: Integer,  default: nil
  field :capacity,                type: Integer,  default: nil
  field :children,                type: Integer,  default: nil
  field :earliest_date,           type: DateTime, default: nil
  field :environment_filters,     type: Array,    default: []
  field :exchange_type_filters,   type: Array,    default: []
  field :hotlist,                 type: Boolean,  default: false
  field :house_filters,           type: Array,    default: []
  field :house_type_filters,      type: Array,    default: []
  field :latest_date,             type: DateTime, default: nil
  field :min_duration,            type: Integer
  field :pets,                    type: Integer
  field :reversed,                type: Boolean,  default: false
  field :reversed_area,           type: String,   default: ''
  field :ee,                      type: Boolean,  default: false
  field :surroundings,            type: Array,    default: []
  field :spoken_languages,        type: Array,    default: []

  def add_location(location)
    locations.create(
      destination: location[:name] ,
      country_code: location[:country_code],
      location: [location[:lat], location[:lng]],
      ne_lat: location[:ne_lat],
      ne_lng: location[:ne_lng],
      sw_lat: location[:sw_lat],
      sw_lng: location[:sw_lng]
    )
  end

  def remove_location(location)
    locations.delete_all(conditions: { id: location})
  end

  def set_filters(params)
    self.house_filters         = params[:house_filters]         || []
    self.house_type_filters    = params[:house_type_filters]    || []
    self.exchange_type_filters = params[:exchange_type_filters] || []
    self.environment_filters   = params[:environment_filters]   || []

    self.capacity = params[:capacity]
    self.adults   = params[:adults]
    self.children = params[:children]

    self.earliest_date = params[:earliest_date].blank? ? nil : params[:earliest_date]
    self.latest_date   = params[:latest_date].blank? ? nil : params[:latest_date]

    self.reversed = !!params[:reversed]
    self.hotlist  = !!params[:hotlist]

    self.surroundings = params[:surroundings].nil? ? [] : params[:surroundings]

    self.reversed_area    = params[:reversed_area]
    self.pets             = params[:pets]
    self.min_duration     = params[:min_duration]
    self.ee               = params[:ee]
    self.spoken_languages = ["spoken_languages"].blank? ? []  : params["spoken_languages"]
  end

  def clear_filters
    # set_filters has to deal properly with the case of nil and empty
    # properties, so sending an object as parameters will reset it
    set_filters({})
  end

  def activate
    update_attribute(:active, true)
  end

  def disable
    update_attribute(:active, false)
  end
end
