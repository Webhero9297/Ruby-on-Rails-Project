# encoding: UTF-8
class Payment::PromotionCodesController < ApplicationController
  
  filter_access_to :all
  layout 'management'
  
  def new
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])
    @promotion_code = PromotionCode.new

    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def create
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])

    params[:promotion_code][:code] = params[:promotion_code][:code].strip
    @promotion_code = @price_plan.promotion_codes.new(promotion_code_params)

    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end
    
    respond_to do |format|
      if @promotion_code.save
        format.html {redirect_to( country_price_plans_url(@country) )}
      else
        format.html {render( action: 'new' )}
      end
    end
  end
  
  
  def show
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])
    @promotion_code = @price_plan.promotion_codes.find(params[:id])

    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def edit
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])
    @promotion_code = @price_plan.promotion_codes.find(params[:id])

    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def update
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])
    @promotion_code = @price_plan.promotion_codes.find(params[:id])

    if agent_session?
      @countries = current_user.agent_profile.get_assigned_countries
    end
    
    params[:promotion_code][:code] = params[:promotion_code][:code].strip
    respond_to do |format|
      if @promotion_code.update_attributes(promotion_code_params)
        format.html {redirect_to( country_price_plans_url(@country) )}
      else
        format.html {render( action: 'edit' )}
      end
    end
  end
  
  
  def destroy
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])
    @promotion_code = @price_plan.promotion_codes.find(params[:id])
    
    respond_to do |format|
      if @promotion_code.delete
        format.html { redirect_to(country_price_plans_url(@country), notice: 'The promotion code has been deleted' )}
      else
        format.html { render( action: 'edit' ) }
      end
    end
  end
  
  
  def archive
    
    @country = Country.find(params[:country_id])
    @price_plan = @country.price_plans.find(params[:price_plan_id])
    @promotion_code = @price_plan.promotion_codes.find(params[:id])
    @promotion_code.archive()
    
    respond_to do |format|
      format.html { redirect_to(country_price_plans_url(@country), notice: 'The promotion code has been archived' )}
    end
  end
  
  
private
  
  def promotion_code_params
    params.require(:promotion_code).permit(:code, :discounted_price, :limit, :end_date, :description)
  end
  
end