# encoding: UTF-8
class AgentsController < ApplicationController
  #filter_access_to :all
  #before_filter { |c| c.set_dashboard_scope 'agent' }
  layout "management"
  respond_to :html
  
  ##
  # Only admins should be able to access this view
  def index
    @users = User.where(:roles => 'agent').order_by(:name, :asc)
  end
  
  
  def show
    @user = User.find(params[:id])
  end
  
  
  def new
    
  end
  
  
  def create
    
    user = User.find(params[:user_id])
    user.upgrade_to_agent
    
    respond_to do |format|
      format.html { redirect_to agents_path, notice: 'Agent has been added.' }
    end
  end
  
  
  def edit
    @user = User.find(params[:id])
    @agent_profile = @user.agent_profile
    @agent_image = AgentImage.new
    @countries = Country.sorted_by_language()
  end
  
  
  def update
    
    @user = User.find(params[:id])
    @agent_profile = @user.agent_profile.update_attributes!(agent_profile_params)
    
    if @agent_profile
      flash[:notice] = "Agent profile was successfully updated."
      respond_with(@user, location: edit_agent_path(@user))
    else
      render action: "edit"
    end
  end
  
  
  def destroy
    
  end
  
  
  # Fetches a user to be upgraded to agent
  def fetch_user
    
    @is_agent = false
    @user = User.first(conditions: {email: params[:email]})
    
    if not @user.nil? and @user.is_agent == false then
      @agent_profile = AgentProfile.new
    end
    
    respond_to do |format|
      format.js
    end
  end

  ##
  # Creates a agent profile image, if an image already exists it will be overwritten
  def create_profile_image
    @user = User.find(params[:id])
    @agent_profile = @user.agent_profile
    @agent_image = @agent_profile.build_profile_image(profile_image_params)
    
    respond_to do |format|
      if @agent_image.valid?
        @agent_image.save
        #format.html { redirect_to(agent_profile_image_url, {notice: 'The image was successfully uploaded.'}) }

        flash[:notice] = "Agent profile was successfully updated."
        format.html { redirect_to(edit_agent_path(@user), {notice: 'The image was successfully uploaded.'}) }
      else
        format.html { render(action: 'edit') }
      end
    end
  end
  
  ##
  # Destroys a agent profile image
  def destroy_profile_image
    @user = User.find(params[:id])
    @profile = @user.agent_profile
    @profile.image.destroy_all(conditions: { id: params[:id] })
    
    respond_to do |format|
      format.html { redirect_to(edit_agent_path(@user), {notice: 'The image was successfully deleted.'}) }
    end
  end

  ##
  # Assigns an agent to a country
  def add_agent_to_country
    
    @agent = User.find(params[:id])
    @country = Country.first(conditions: { short: params[:agent_profile][:agent_for] })
    @country_assigned = @agent.agent_profile.assign_country(@country)
    
    respond_to do |format|
      format.js
    end
  end
  

  ##
  # Removes an agent from a country
  def remove_agent_from_country
    
    User.collection.update({"_id" => BSON::ObjectId("#{params[:id]}")}, {'$pull' => {"agent_profile.agent_for" => {"short" => params[:country_short]}}})
    @country_table_id = "country-#{params[:country_short]}"
    
    respond_to do |format|
      format.js
    end
  end


  ##
  #
  def remove_as_agent_confirm
    @user = User.find(params[:id])
    @agent_profile = @user.agent_profile
    @agent_image = AgentImage.new
    @countries = Country.sorted_by_language()

    respond_to do |format|
      format.html
    end
  end


  ##
  #
  def remove_as_agent
    @user = User.find(params[:id])
    @user.agent_profile.agent_for = []
    @user.agent_profile.save!
    @user.pull(:roles, 'agent')

    respond_to do |format|
      format.html {redirect_to(agents_path, {notice: 'The user is no longer an agent and all information has been deleted'})}
    end
  end


  private
  
  def agent_profile_params
    params[:user][:agent_profile].permit(:name, :address, :postal_town, :postal_code, :country, :telephone, :mobile, :fax, :email, :website, :office_hours)
  end

  def profile_image_params
    params.require(:agent_image).permit(:image, :caption)
  end

end
