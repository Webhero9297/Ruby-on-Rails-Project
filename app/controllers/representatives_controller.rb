# encoding: utf-8
class RepresentativesController < ApplicationController
  filter_access_to :all
  layout 'application'

  def index
    @countries = Country.all.to_a.sort_by{ |country| t(country['msgid']) }
    @agents = User.where(roles: 'agent')
    @country_agents = Country.countries_with_agents
  end

  def show
    # show should not be used.
    # As there are some requests to it, we will redirect to to index
    # to prevent rollbar errors
    redirect_to representatives_path
  end
end
