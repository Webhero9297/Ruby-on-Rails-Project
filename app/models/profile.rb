# encoding: utf-8
class Profile
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :account, :class_name => "Account"
  
  embeds_many :profile_images, :class_name => "ProfileImage"
  embeds_many :wish_list_destinations, :class_name => "WishList"
  embeds_many :children, :class_name => "Person"
  embeds_many :adults, :class_name => "Adult"
  embeds_many :pets, :class_name => "Pet"
  
  embeds_one :presentation, :class_name => "Description"
  embeds_one :lifestyle, :class_name => "Description"
  
  accepts_nested_attributes_for :lifestyle, :presentation, :profile_images
  
  field :spoken_languages,          type: Array,    default: []
  field :open_for_all_destinations, type: Boolean,  default: false
  field :number_of_adults,          type: Integer, default: 1
  
  #validates :spoken_languages, :presence => {:message => 'You must select at least one language'}

  def add_wish_list_destination(params)
    
    destination = self.wish_list_destinations.create!(
      location: [params[:lat].to_f, params[:lng].to_f],
      ne_lng: params[:ne_lng].to_f,
      ne_lat: params[:ne_lat].to_f,
      sw_lng: params[:sw_lng].to_f,
      sw_lat: params[:sw_lat].to_f,
      destination: params[:name],
      country_code: params[:country_code]
    )
    
    return destination
    
  end

  def set_wishlist_on_listings
    # Set up wishlist
    wish_lists = []
    self.wish_list_destinations.each do |wl|
      wish_lists.push({'location'=> wl.location, 'ne_lat' => wl.ne_lat, 'ne_lng' => wl.ne_lng, 'sw_lat' => wl.sw_lat, 'sw_lng' => wl.sw_lng, 'country_code' => wl.country_code, 'destination' => wl.destination})
    end
    self.account.listings.each do |listing|
      listing.set(:account_wish_lists, wish_lists)
    end
  end
  
  
  def get_images_by_category(category_name)
    
    return self.profile_images.where(:category.in => category_name)
  end
  
  
  def set_spoken_languages(params)
    
    if params.nil?
      return false
    end

    # Make sure we only have uniq entries
    return self.set(:spoken_languages, params.uniq)
    
  end

  def update_number_of_adults(adults)
    return self.set(:number_of_adults, adults)
  end
  
  def propagate_number_of_adults
    self.account.listings.each do |listing|
      listing.set(:account_adults, self.number_of_adults)
    end
  end

  def propagate_number_of_children
    self.account.listings.each do |listing|
      listing.set(:account_children, number_of_children())
    end
  end

  def propagate_number_of_pets
    self.account.listings.each do |listing|
      listing.set(:account_pets, number_of_pets())
    end
  end
  
  def number_of_children
    self.children.count
  end

  def number_of_pets
    self.pets.count
  end

  
end