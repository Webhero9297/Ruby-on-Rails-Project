# encoding: utf-8
class Base::BaseFeedbackController < ApplicationController
  filter_access_to :all

  def index
    @feedbacks = Feedback.all.order_by(:created_at, :desc)
  end

  def show
    @feedback = Feedback.find(params[:id])
    @feedback.mark_as_read(current_user.id)
    @conversation = Conversation.new
  end

  def new
    session[:cancel_url] = request.env["HTTP_REFERER"]
    @feedback = Feedback.new
    @countries = Country.sorted_by_language
    @cancel_url = session[:cancel_url]
    @url = feedbacks_url
  end

  def create
    @countries = Country.sorted_by_language
    @cancel_url = session[:cancel_url]
    @url = feedbacks_url
    @feedback = Feedback.build_new_feedback(params[:feedback], request.env['HTTP_USER_AGENT'])
  end

  def thank_you
    @feedback = Feedback.find(params[:id])
    @cancel_url = session[:cancel_url]
  end

  def destroy
  end
end
