# encoding: UTF-8
class Payment::PricePlansController < ApplicationController
  filter_access_to :all
  layout "management"

  def index
    @country = Country.find(params[:country_id])
    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end

    respond_to do |format|
      format.html
    end
  end

  def new
    @price_plan = PricePlan.new
    @country = Country.find(params[:country_id])
    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end

    respond_to do |format|
      format.html
    end
  end

  def create
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.new(price_plan_params)
    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end

    respond_to do |format|
      if @price_plan.save
        format.html {redirect_to( action: 'index')}
      else
        format.html {render( action: 'new' )}
      end
    end
  end

  def edit
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:id])
    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end

    respond_to do |format|
      format.html
    end
  end

  def update
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:id])
    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end

    respond_to do |format|
      if @price_plan.update_attributes(price_plan_params)
        PricePlan.update_shared_plans(@price_plan)
        format.html {redirect_to( action: 'index')}
      else
        format.html {render( action: 'edit' )}
      end
    end
  end

  def destroy
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.delete_all(conditions: { id: params[:id] })

    respond_to do |format|
      format.html {redirect_to( action: 'index')}
    end
  end

  def set_as_active_inactive
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:id])

    if @price_plan.active == true then
      @price_plan.set(:active, false)
    else
      @price_plan.set(:active, true)
    end

    # If the plan is shared, all shared plans are set to active or inactive
    unless @price_plan.shared_id.nil?
      current_user.agent_profile.get_assigned_countries.each do |country|
        if country.id != @country.id
          country.price_plans.where(shared_id: @price_plan.shared_id).each do |country_price_plan|
            bool = country_price_plan.active == true
            country_price_plan.set(:active, bool)
          end
        end
      end
    end

    respond_to do |format|
      format.html {redirect_to( action: 'index')}
    end
  end

  def set_as_default
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:id])

    @country.price_plans.each do |price_plan|
      price_plan.set(:default, false)
    end

    @price_plan.set(:default, true)

    # If the plan is shared, all shared plans are set to default and all other plans for the country is set to default false.
    unless @price_plan.shared_id.nil?
      current_user.agent_profile.get_assigned_countries.each do |country|
        country.price_plans.each do |country_price_plan|
          country_price_plan.set(:default, false)
        end

        shared = country.price_plans.where(shared_id: @price_plan.shared_id).first
        shared.set(:default, true) if shared
      end
    end

    respond_to do |format|
      format.html { redirect_to(action: 'index') }
    end
  end

  def country_assignment
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:id])

    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end

    if admin_session?
      @countries = Country.all
    end

    respond_to do |format|
      format.html
    end
  end

  def assign_countries
    marked_countries = params[:countries]

    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:id])

    PricePlan.set_as_shared(@price_plan, marked_countries)

    respond_to do |format|
      format.html {redirect_to(country_price_plans_url(@country))}
    end
  end

  private

  def price_plan_params
    params.require(:price_plan).permit(:name, :base_price, :renewal_price, :duration, :periodicity, :kind, :free, :ref_id)
  end
end
