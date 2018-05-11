# encoding: UTF-8
class MessageTemplatesController < ApplicationController
  filter_access_to :all
  layout 'dashboard'

  def index
    @message_templates = current_user.account.message_templates
    @unread_messages = Conversation.select_member_conversation_filter(params, current_user).not_in(read_by: [current_user.account.id]).count

    @agent_unread_messages = Conversation.get_agent_conversations(params, current_user).not_in(read_by: [current_user.account.id])
    if current_user.is_agent
      @agent_unread_messages = @agent_unread_messages.where(started_by: current_user.account.id)
    end
    @agent_unread_messages = @agent_unread_messages.count

    respond_to do |format|
      format.html
    end
  end

  def new
    @message_template = current_user.account.message_templates.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @message_template = current_user.account.message_templates.new(
      name: params[:message_template][:name],
      subject: params[:message_template][:subject],
      body: params[:message_template][:body]
    )

    respond_to do |format|
      if @message_template.save
        current_user.account.reload
        format.html {redirect_to(message_templates_path, notice: t('alert.message_template_created'))}
      else
        format.html {render(action: 'new')}
      end
    end
  end

  def edit
    @message_template = current_user.account.message_templates.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @message_template = current_user.account.message_templates.find(params[:id])
    @message_template.update_attributes(
      name: params[:message_template][:name],
      subject: params[:message_template][:subject],
      body: params[:message_template][:body]
    )

    respond_to do |format|
      if @message_template.save
        current_user.reload
        format.html {redirect_to(message_templates_path, notice: t('alert.message_template_updated'))}
      else
        format.html {render(action: 'edit')}
      end
    end
  end

  def destroy
    @message_template = current_user.account.message_templates.find(params[:id])
    @message_template.destroy

    respond_to do |format|
      format.html { redirect_to(message_templates_path, notice: t('alert.message_template_deleted')) }
    end
  end

  def fetch_template
    account = Account.find(current_user.account.id)

    begin
      @message_template = account.message_templates.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @message_template = ''
    end

    @message_template = '' if @message_template.blank?

    respond_to do |format|
      format.js
    end
  end
end
