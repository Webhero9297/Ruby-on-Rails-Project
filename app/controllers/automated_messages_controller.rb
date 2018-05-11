# encoding: UTF-8
class AutomatedMessagesController < ApplicationController
  filter_access_to :all
  layout 'management'

  ##
  # Shows all the automated messages for a single country
  def for_country
    @country = Country.find(params[:country_id])
    @messages = AutomatedMessage.where(:countries.in => [@country.short]).order_by(:name, :asc)

    respond_to do |format|
      format.html
    end
  end

  ##
  # Edits a single message displayed based on a country
  def edit_for_country
    @automated_message = AutomatedMessage.find(params[:id])
    @message_types = AutomatedMessage.get_message_kinds()
    @country = Country.find(params[:country_id])
    @countries = Country.only(:msgid, :short).collect {|c| [ t(c['msgid']), c['short'] ] }.sort
    @placeholders = AutomatedMessage.get_placeholders_for_message(@automated_message.kind)

    respond_to do |format|
      format.html
    end
  end

  def update_for_country
    @country = Country.find(params[:country_id])
    @automated_message = AutomatedMessage.find(params[:id])
    @automated_message.update_message(params[:automated_message], current_user.id)

    respond_to do |format|
      if @automated_message.save
        format.html {redirect_to(for_country_automated_messages_path(@country))}
      else
        @placeholders = AutomatedMessage.get_placeholders_for_message(params[:automated_message][:kind])
        @message_types = AutomatedMessage.get_message_kinds()
        @countries = Country.only(:msgid, :short).collect {|c| [ t(c['msgid']), c['short'] ] }.sort
        format.html {render(action: 'edit_for_country')}
      end
    end
  end

  def destroy_for_country
    @country = Country.find(params[:country_id])
    @automated_message = AutomatedMessage.find(params[:id])
    @automated_message.delete

    respond_to do |format|
      format.html {redirect_to(for_country_automated_messages_path(@country))}
    end
  end

  def index
    @messages = AutomatedMessage.where(:countries.in => current_user.agent_profile.get_assigned_countries_short_codes).order_by(:name, :asc)

    respond_to do |format|
      format.html
    end
  end

  def new
    @automated_message = AutomatedMessage.new
    @message_types = AutomatedMessage.get_message_kinds()
    @countries = current_user.agent_profile.agent_for.collect {|c| [ t(c['msgid']), c['short'] ] }.sort
    @placeholders = 'Choose a message kind'

    respond_to do |format|
      format.html
    end
  end

  ##
  # Lists all the default messages
  def show_default
    @automated_messages = AutomatedMessage.where(:countries.in => ['default'])
    respond_to do |format|
      format.html
    end
  end

  ##
  # Edit a single default message
  def edit_default
    @automated_message = AutomatedMessage.find(params[:id])
    @message_types = AutomatedMessage.get_message_kinds()
    @placeholders = AutomatedMessage.get_placeholders_for_message(@automated_message.kind)

    respond_to do |format|
      format.html
    end
  end

  def update_default
    @automated_message = AutomatedMessage.find(params[:id])
    @automated_message.update_message(params[:automated_message], current_user.id)

    respond_to do |format|
      if @automated_message.save
        format.html {redirect_to(action: 'show_default')}
      else
        @placeholders = AutomatedMessage.get_placeholders_for_message(params[:automated_message][:kind])
        @message_types = AutomatedMessage.get_message_kinds()
        format.html {render(action: 'edit_default')}
      end
    end
  end

  def create
    @automated_message = AutomatedMessage.new(
      name: AutomatedMessage.get_message_name(params[:automated_message][:kind]),
      kind: params[:automated_message][:kind],
      subject: params[:automated_message][:subject],
      message: params[:automated_message][:message],
      days: params[:automated_message][:days],
      countries: params[:automated_message][:countries],
      created_by: current_user.id,
      send_copy_to_agent: params[:automated_message][:send_copy_to_agent]
    )

    respond_to do |format|
      if @automated_message.save
        format.html {redirect_to(automated_messages_path)}
      else
        @message_types = AutomatedMessage.get_message_kinds()
        @countries = current_user.agent_profile.agent_for.collect {|c| [ t(c['msgid']), c['short'] ] }.sort
        @placeholders = AutomatedMessage.get_placeholders_for_message(params[:automated_message][:kind])
        if @automated_message.countries.nil?
          @automated_message.countries = []
        end
        format.html { render(action: 'new') }
      end
    end
  end

  def edit
    @automated_message = AutomatedMessage.find(params[:id])
    @message_types = AutomatedMessage.get_message_kinds()
    @countries = current_user.agent_profile.agent_for.collect {|c| [ t(c['msgid']), c['short'] ] }.sort
    @placeholders = AutomatedMessage.get_placeholders_for_message(@automated_message.kind)

    respond_to do |format|
      format.html
    end
  end

  def update
    @automated_message = AutomatedMessage.find(params[:id])
    @automated_message.update_message(params[:automated_message], current_user.id)

    respond_to do |format|
      if @automated_message.save
        format.html {redirect_to(action: 'index')}
      else
        @placeholders = AutomatedMessage.get_placeholders_for_message(params[:automated_message][:kind])
        @message_types = AutomatedMessage.get_message_kinds()
        @countries = current_user.agent_profile.agent_for.collect {|c| [ t(c['msgid']), c['short'] ] }.sort
        format.html {render(action: 'edit')}
      end
    end
  end

  def destroy
    @automated_message = AutomatedMessage.find(params[:id])
    @automated_message.delete

    respond_to do |format|
      format.html { redirect_to(action: 'index') }
    end
  end

  ##
  # Used by the drop-down selector to update the available placeholders for the specific message type
  def update_meta_data
    message = params[:selected]
    @placeholders = AutomatedMessage.get_placeholders_for_message(message)
    @days = AutomatedMessage.get_days_for_message(message)

    respond_to do |format|
      format.js
    end
  end

  def preview
    @placeholders = {}
    @placeholders[:MEMBER_NAME] = "INTERVAC USER (Decprecated use FAMILY_NAME instead)"
    @placeholders[:FAMILY_NAME] = "INTERVAC USER"
    @placeholders[:FAMILY_ID] = 123456
    @placeholders[:COUNTRY] = "SE"
    @placeholders[:LOGIN] = "user@domain.com"
    @placeholders[:EXPIRE_DAYS] = "5"
    @placeholders[:DEACTIVATION_DATE] = Date.today.strftime("%F")

    @placeholders[:SUBSCRIPTION_LINK] = upgrade_subscriptions_url
    @placeholders[:FEEDBACK_LINK] = ActionController::Base.helpers.link_to('Home exchange feedback', exchange_feedbacks_url)
    @placeholders[:NUMBER] = '14'
    @placeholders[:LAST_LOGIN_IN_DAYS] = ((Time.now.utc - current_user.account.accessed_at.utc).to_i / 3600 / 24)

    @agent_placeholders = {}
    @agent_placeholders[:MY_NAME] = "AGENT NAME"
    @agent_placeholders[:MY_EMAIL] = "AGENT E-MAIL"
    @agent_placeholders[:MY_PHONE] = "AGENT PHONE"
    @agent_placeholders[:MY_FAX] = "AGENT FAX"
    @agent_placeholders[:MY_URL] = "AGENT WEBSITE"
    @agent_placeholders[:MY_COUNTRY] = "AGENT COUNTRY"
    @agent_placeholders[:LISTING_ID] = "LISTING NUMBER"

    @placeholders.merge!(@agent_placeholders)

    @preview_message = {
      subject: params[:automated_message][:subject],
      body: params[:automated_message][:message]
    }

    respond_to do |format|
      format.js
    end
  end
end
