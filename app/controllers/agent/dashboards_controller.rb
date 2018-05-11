# encoding: UTF-8
# retired
class Agent::DashboardsController < ApplicationController
  
  filter_access_to :all
  before_filter { |c| c.set_dashboard_scope 'agent' }
  layout "dashboard"
  
  def index
    @locales = current_user.agent_profile.locales
    @locale_stats = []
    for locale in @locales
      stats = Translations.get_statistics_for_locale(locale)
      next if stats.nil?
      @locale_stats.push(stats)
    end
    @countries = current_user.agent_profile.get_assigned_countries

    @feedbacks_url = agent_feedbacks_url
    @unread_messages = Conversation.where(:kind.in => ['member_to_agent', 'agent_to_member']).where(participants: current_user.account.id).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).count
    
  end
  
  def stats
    for_countries = current_user.agent_profile.get_assigned_countries_short_codes
    stats = {}
    stats['activated'] = Account.stats_activated(for_countries)
    stats['expires'] = Account.stats_expires(for_countries)
    
    respond_to do |format|
      format.json {render :json => stats}
    end
    
    
  end
  
end
