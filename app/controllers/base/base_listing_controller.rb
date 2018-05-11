# encoding: UTF-8
class Base::BaseListingController < ApplicationController
  #filter_access_to :all
  def index
    #puts "=============INDEX================"
    total_start_time = Time.now
    ## How many is my country
    # Getting user country
    if current_user and current_user.account.has_listing?
      
      my_listing = current_user.account.listings.first
      my_lat = my_listing[:lat]
      my_lng = my_listing[:lng]

      country = my_listing.get_country()
      @country_code = country.short
      country_msgid = country[:msgid]

    else
      cookie = CookieJar.get_cookie(cookies[:intervac_user])
      country = Country.get_by_short_code(cookie.country_short)
      country_msgid = country[:msgid]
      #choice = {'short' => country.short, 'msgid' => "Where I am (#{t(country_msgid)})", 'active'=>false, 'count'=>1}
      #@destination_text = _("My location") + " (" + t(country_msgid)+")"
    end

    @destination_text = t(country_msgid)
    
    #@destinations = [{'short' => 'any', 'msgid' => 'country.any', 'active'=>true, 'count'=>''}, choice]
    
    @listings = Listing.searchable.only_international(current_user).order_by([:updated_at, :desc])
    
    # Setting up valid search tags
    @valid_tags = { 'accessible' => 'tag.suitable_for_disabled_people','baby_equipment'=>'tag.baby_equipment', 
                    'balcony' => 'tag.balcony', 'garden' => 'tag.garden', 'pool' => 'tag.private_swimming_pool', 
                    'no_children' => 'tag.no_small_children', 'children_welcome' => 'tag.children_welcome', 'no_pets'=>'tag.no_pets',
                    'pets_welcome'=>'tag.pets_welcome', 'no_smoking'=> 'tag.non_smoking', 'use_exchange_of_car' => 'tag.use_exchange_of_car'
                  }
    
    #@features = [{'short' => 'any', 'msgid' => 'tag.any', 'active'=>true, 'count'=>@listings.count}]
    @features = []
    @valid_tags.each do |short, msgid|
      feature =  {'short' => short, 'msgid' => msgid, 'active'=> false, 'count' => 0}
      @features.push(feature)
    end
    # Adding hotlist "filter" to features list
    @features.push({'short' => 'hotlist', 'msgid' => 'tag.hotlist', 'active' => false, 'count'=> 0})
    
    @exchange_types = []
    ExchangeType.selectable.each do |exchange_type|
      et =  {'short' => exchange_type.short, 'msgid' => exchange_type.msgid, 'active'=> false, 'count' => 0}
      @exchange_types.push(et)
    end
        
    count = 5#@listings.any_in(:account_id => account_ids).count
     
    #total_end_time = Time.now
    #puts "Time elapsed #{(total_end_time - total_start_time)*1000} milliseconds"
    
    @beds = []
    (1..5).each do |i|
      count = 5#@listings.where(:sleeping_capacity.gte => i).count
      item = {'short' => i, 'msgid' => "#{i} #{t('global.or_more')}", 'active'=>false, 'count'=>count}
      @beds.push(item)
    end
    #puts "Beds"
    total_end_time = Time.now
    #puts "Time elapsed #{(total_end_time - total_start_time)*1000} milliseconds"
    
    environments = Environment.all
    @environments = [{'short' => 'any', 'msgid' => 'environment.any', 'active'=>true, 'count'=>0}]
    environments.each do |e|
      count = 5#@listings.where(:environment => e['msgid']).count
      @environments.push({'short' => e['short'], 'msgid' => e['msgid'], 'active'=> false, 'count' => count})
    end
    
    # TODO when the model is updated
    @children = []
    @pets = []
    #@count =  @listings.count
    # Index is always more than 1000
    @count = '1000+'
    #if @count > 1000 then
    #  @count = '1000+'
    #end

    @listings = @listings.page(params[:page]).per(12)
    
    #total_end_time = Time.now
    #puts "Time elapsed #{(total_end_time - total_start_time)*1000} milliseconds"

    

  end
  
  
  def show
    @property_details = PropertyDetail.limit(100)
    @listing = Listing.find(params[:id])
    @related_listings = Listing.searchable.only_international(current_user).related(@listing).limit(4)
    @listing.create_statistics(request)
    
    respond_to do |format|
      format.html
    end
  end
  
  def search
    #puts "================ SEARCH===================="
    #puts params.inspect
    total_start_time = Time.now
    @q = params[:q]
    @lat = params[:lat].to_f unless params[:lat].blank?
    @lng = params[:lng].to_f unless params[:lng].blank?
    @ne_lat = params[:ne_lat].to_f unless params[:ne_lat].blank?
    @ne_lng = params[:ne_lng].to_f unless params[:ne_lng].blank?
    @sw_lat = params[:sw_lat].to_f unless params[:sw_lat].blank?
    @sw_lng = params[:sw_lng].to_f unless params[:sw_lng].blank?


    if @lat
      @lat = 90 if @lat > 90
      @lat = -90 if @lat < -90
    end
    
    if @lng
      @lng = 180 if @lng > 180
      @lng = -180 if @lng < -180
    end


    
    @earliest_date = params[:earliest_date_form]
    @latest_date = params[:latest_date_form]
    
    
    @listings = Listing.searchable.only_international(current_user)
    
    hotlist_active = false
    if params[:hotlist]
      @listings = @listings.in_hot_list
      # Used when pushing to features further down
      hotlist_active = true
    end
    
    map = false
    if not params[:ne_lat].blank? then 
      box = [[@ne_lng, @ne_lat], [@sw_lng, @sw_lat]]
      # We are gonna test using near with a custom within query like wishlist
      @listings = @listings.within_bounds(@ne_lat, @ne_lng, @sw_lat, @sw_lng)
      #puts "WITHIN #{@listings.count}"
      map = true
    end
    
    
    ## Date check
    if not @earliest_date.blank? then
      begin
        earliest_date_utc = DateTime.parse(@earliest_date).to_time.utc
        @listings = @listings.where(:"exchange_dates.latest_date".gte => earliest_date_utc)
      rescue Exception => e
        # Log this somewhere
        begin
          #ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
        rescue
        end
      end
    end
    
    
    if not @latest_date.blank? then
      begin
        latest_date_utc = DateTime.parse(@latest_date).to_time.utc
        @listings = @listings.where(:"exchange_dates.earliest_date".lte => latest_date_utc)
      rescue Exception => e
        # Log this somewhere
        begin
          #ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
        rescue
        end
      end
    end
    
    ## How many is my country
    # Getting user country
    
    if current_user and current_user.account.has_listing?

      my_listing = current_user.account.listings.first
      my_lat = my_listing[:lat]
      my_lng = my_listing[:lng]

      country = my_listing.get_country()
      @country_code = country.short
      country_msgid = country[:msgid]
    else
      cookie = CookieJar.get_cookie(cookies[:intervac_user])
      country = Country.get_by_short_code(cookie.country_short)
      @country_code = country.short
      country_msgid = country[:msgid]
      msgid = country[:msgid]
      my_lat = country[:lat]
      my_lng = country[:lng]
      
      #choice = {'short' => country.short, 'msgid' => "Where I am (#{t(country_msgid)})", 'active'=>false, 'count'=>1}
      #@destination_text = _("My location") + " (" + t(country_msgid)+")"
    end

    @destination_text = t(country_msgid)
    
    #@destinations = [{'short' => 'any', 'msgid' => 'country.any', 'active'=>true, 'count'=>''}, choice]
    if params[:destination] then
      #@destinations[0]['active'] = false
      #@destinations[1]['active'] = true
      #@listings = @listings.get_by_wish_list(my_lat, my_lng)
      @listings = @listings.get_by_wish_list_code(@country_code)

      #puts "DESTINATION #{@listings.count}"
    end
    
    
    sleeping_capacity = 1
    if not params[:sleeping_capacity].blank? then
      sleeping_capacity = params[:sleeping_capacity]
      @listings = @listings.where(:sleeping_capacity.gte => sleeping_capacity)
    end
    
    
    if not params[:environment].blank? then
      environment = params[:environment]
      @listings = @listings.where(:environment => environment)
    end
    
    active_tags = []
    if params[:filters] then
      active_tags = params[:filters]
      @listings = @listings.all_in(property_details: active_tags)
    end

    exchange_types = []
    if params[:exchange_types] then
      exchange_types = params[:exchange_types]
      @listings = @listings.any_in(exchange_types: exchange_types)
    end
    
    # Setting up valid search tags
    @valid_tags = {'accessible' => 'tag.suitable_for_disabled_people','baby_equipment'=>'tag.baby_equipment', 'balcony' => 'tag.balcony', 
      'garden' => 'tag.garden', 'pool' => 'tag.private_swimming_pool', 'no_children' => 'tag.no_small_children', 'children_welcome' => 'tag.children_welcome', 
      'no_pets'=>'tag.no_pets', 'pets_welcome'=>'tag.pets_welcome', 'no_smoking'=> 'tag.non_smoking', 'use_exchange_of_car' => 'tag.use_exchange_of_car'}
    @features = []
    @valid_tags.each do |short, msgid|
      feature =  {'short' => short, 'msgid' => msgid, 'active'=> false, 'count' => 0}
      if active_tags.include?(msgid) then
        feature['active'] = true
      end
      @features.push(feature)
    end
    @features.push({'short' => 'hotlist', 'msgid' => 'tag.hotlist', 'active' => hotlist_active, 'count'=> 0})
    
    
    @exchange_types = []
    ExchangeType.selectable.each do |exchange_type|
      et =  {'short' => exchange_type.short, 'msgid' => exchange_type.msgid, 'active'=> false, 'count' => 0}
      if exchange_types.include?(exchange_type.msgid) then
        et['active'] = true
      end
      @exchange_types.push(et)
    end

    count = 5 #listings.any_in(:account_id => account_ids).count
    #@destinations[1]['count'] = count
    @beds = []
    (1..5).each do |i|
      count = 5#@listings.where(:sleeping_capacity.gte => i).count
      item = {'short' => i, 'msgid' => "#{i} or more", 'active'=>false, 'count'=>count}
      if sleeping_capacity.to_i == i then
        item['active'] = true
      end
      @beds.push(item)
    end
    
    environments = Environment.all
    @environments = [{'short' => 'any', 'msgid' => 'environment.any', 'active'=>true, 'count'=>0}]
    environments.each do |e|
      count = 5#@listings.where(:environment => e['msgid']).count
      if environment == e['msgid'] then
        @environments[0]['active'] = false
        @environments.push({'short' => e['short'], 'msgid' => e['msgid'], 'active'=> true, 'count' => count})
        next
      end
      @environments.push({'short' => e['short'], 'msgid' => e['msgid'], 'active'=> false, 'count' => count})
    end
    
    # TODO when the model is updated
    @children = []
    @pets = []
    @count =  @listings.count
    if @count > 1000 then
      @count = '1000+'
    end

    if not @lat.blank? and @lat > 0 then
      @listings = @listings.where(:location_reversed => {
          "$near" => {"$geometry" => {"type" => "Point", "coordinates" => [@lng, @lat]}}
        })
    else
      @listings = @listings.order_by([:updated_at, :desc])
    end

    # This code can sort a listing after a list of country codes
    #target = ["SE", "NO"]
    #@listings = @listings.group_by(&lambda{ |x| x["country_code"] }).values_at(*target).flatten(1)
    ## NEED TO LOOK AT WHAT WE DO IF WE DO NET GET ANY MATCHES
    
    
    @listings = @listings.page(params[:page]).per(12)
    
    @params = params
    
    #total_end_time = Time.now
    #puts "Time elapsed #{(total_end_time - total_start_time)*1000} milliseconds"
    #puts "FINISHED #{@count}"
    
    ## Set filter name if this is a saved seaarch
    @filter_name = params[:filter_name]
    
  end
  
  def find
    listing_number = params[:listing_number].upcase
    @listing = Listing.where(listing_number: listing_number).only_international(current_user).first
  end
  
  
  def get_listings
    q = params[:q]
    q = q.gsub(/[^0-9a-z ]/i, '')
    @listings = Listing.searchable.where(:listing_number => /^#{q}/i).only_international(current_user).only(:listing_number).limit(200)
  end

  ##
  # Where Agents and Admins lands when wanting to delete a listing. A confirmation page warns them about the fact that when a listing is deleted nothing can be restored.
  def confirm_destroy
    @listing = Listing.has_permission(current_user).find(params[:management_listing_id])
    @confirm_destroy = true
    respond_to do |format|
      format.html { render(layout: 'management') }
    end    
  end

  ##
  # Deletes a listing used by Agents and Admins that get redirected back to the account membership overview
  def destroy
    @listing = Listing.has_permission(current_user).find(params[:id])
    account_id = @listing.account_id
    @listing.destroy

    respond_to do |format|
      format.html { redirect_to account_path(account_id) }
    end
  end

  
  
end
