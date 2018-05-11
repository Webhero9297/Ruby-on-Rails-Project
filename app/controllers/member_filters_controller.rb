# encoding: UTF-8
class MemberFiltersController < ApplicationController
  filter_access_to :all
  layout 'management'

  # Consolidate the methods below to one single method
  def index
    session[:management_user_id] = current_user.id

    if admin_session?
      session[:management_dashboard] = 'admin'
    else
      session[:management_dashboard] = 'agent'
    end

    @user = current_user
    @sort_on = 'name'
    @filter = 'all'
    @direction = "asc"
    @current_direction = @direction
    @page = 1
    @query = nil

    if admin_session?
      @country_codes = []
      @dropdown_countries = Country.only(:short, :msgid).order_by(:msgid, :asc)
    else
      @country_codes = @user.agent_profile.get_assigned_countries_short_codes
      if @country_codes.empty?
        flash[:notice] = 'You do not have access to any countries'
        redirect_to(management_agent_dashboard_path)
        return
      end
      @dropdown_countries = Country.only(:short, :msgid).where(:short.in => @country_codes).order_by(:msgid, :asc)
    end

    
    params = {filter: @filter, country_codes: @country_codes, direction: @direction, sort: @sort_on, page: @page, query: @query}
    
    @accounts = Account.sort_and_filter_members_by_params(params).page(params[:page]).per(20)
    @clear_url = sort_member_filters_path

    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def sort

    if params[:country_codes] and params[:country_codes][0] == 'all'
      redirect_to(member_filters_path)
      return
    end

    @filter = params[:filter]
    @country_codes = params[:country_codes]
    @direction = params[:direction]
    @current_direction = @direction
    @sort_on = params[:sort]
    @page = params[:page]
    @query = params[:query]

    @accounts = Account.sort_and_filter_members_by_params(params).page(params[:page]).per(20)

    if params[:change_order] == 'yes'
      if @direction == "asc"
        @direction = "desc"
      else
        @direction = "asc"
      end
    end
    
    respond_to do |format|
      format.js
    end
  end


  def search
    
    for_user = current_user
    if session[:dashboard] == 'admin'
      for_user = nil
    end

    @filter = params[:filter]
    @country_codes = params[:country_codes]
    @direction = params[:direction]
    @current_direction = @direction
    @sort_on = params[:sort]
    @page = params[:page]
    @query = params[:query]

    @accounts = Account.unscoped.sort_and_filter_members_by_params(params).page(params[:page]).per(20)

    respond_to do |format|
      format.json
      format.js
    end
  end

  def download
    filename = params[:filename]
    respond_to do |format|
      format.csv { send_file "#{Rails.root}/public/exports/#{filename}.csv"}
    end
  end

end
