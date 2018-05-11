# encoding: UTF-8
class Countries::PaymentOptionsController < ApplicationController
  layout "management"

  def overview
    @countries = Country.all if admin_session?
    @countries = current_user.agent_profile.get_assigned_countries if agent_session?

    respond_to do |format|
      format.html
    end
  end

  def edit
    @country = Country.find(params[:country_id])
    @countries = current_user.agent_profile.get_assigned_countries if agent_session?

    respond_to do |format|
      format.html {  }
    end
  end

  def update
    @country = Country.find(params[:country_id])
    @country.update_attributes(payment_options_params)

    respond_to do |format|
      flash[:success] = "Payment option updated"
      format.html { redirect_to(edit_country_payment_options_path(@country)) }
    end
  end

  private

  def payment_options_params
    params.permit(
      :accept_paypal,
      :accept_paypal_text,
      :accept_invoice,
      :accept_invoice_text,
      :accept_sage_pay,
      :accept_sage_pay_text,
      :accept_av_solutions,
      :accept_av_solutions_text,
      :accept_generic_offline,
      :accept_generic_offline_text,
      :accept_generic_offline_button_text,
      :accept_generic_offline_payment_info
    )
  end
end
