# encoding: UTF-8
class Mobile::SettingsController < ApplicationController
  
  filter_access_to :all
  layout 'mobile'
  before_filter :set_as_mobile

  def index
    respond_to do |format|
      format.html
    end
  end


  def set_device_token

    begin
      current_user.update_attributes(android_device_token: params[:device_token], device_type: 'ios')
      status = "success"
    rescue
      status = "failure"
    end

    respond_to do |format|
      format.html { render :nothing => true, status: 200 }
      format.json { render :json =>  status }
    end
  end


  def set_android_device_token

    begin
      current_user.update_attributes(device_token: params[:device_token], device_type: 'android')
      status = "success"
    rescue
      status = "failure"
    end

    respond_to do |format|
      format.html { render :nothing => true, status: 200 }
      format.json { render :json =>  status }
    end
  end


  def destroy_device_token

    begin
      current_user.set(:device_token, nil)
      status = "success"
    rescue
      status = "failure"
    end

    respond_to do |format|
      format.html { render :nothing => true, status: 200 }
      format.json { render :json => status }
    end  
  end

end
