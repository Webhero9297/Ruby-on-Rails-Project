# encoding: utf-8
namespace :statistics do
  
  desc "Calculate agent statistics"
  task :active_members_per_agent => :environment do
    agents = User.where(roles: 'agent')
    agents.each do |agent|
      active_members = agent.agent_profile.calculate_total_active_members
      agent.agent_profile.active_members = active_members
      agent.save
    end
  end

  desc "Calculate agent statistics"
  task :calculate_country_statistics => :environment do
    countries = Country.all()
    countries.each do |country|
      country.total_members = country.members_count
      country.active_members = country.members_active_count
      country.trial_members = country.members_trial_count
      country.save
    end
  end
 
end


