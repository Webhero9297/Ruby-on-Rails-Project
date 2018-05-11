# encoding: UTF-8
class Management::DashboardsController < ApplicationController
  layout "management"
  respond_to :html

  def admin
    if current_user
      set_dashboard_scope('admin')
    else
      redirect_to(login_path)
    end
  end

  def agent
    if current_user
      set_dashboard_scope('agent')
      @locales = current_user.agent_profile.locales

      @missing_locales = {}
      for locale in @locales
        missing = Translations.count_missing_translations(locale)
        if missing > 0
          @missing_locales[locale] = missing
        end
      end

      @countries       = current_user.agent_profile.get_assigned_countries
      @unread_messages = Conversation.where(:kind.in => ['member_to_agent', 'agent_to_member']).
                         where(participants: current_user.account.id).
                         not_in(archived: [current_user.account.id]).
                         not_in(read_by: [current_user.account.id]).
                         count
    else
      redirect_to(login_path)
    end
  end
end
