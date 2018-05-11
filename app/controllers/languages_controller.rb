# encoding: UTF-8
class LanguagesController < ApplicationController
  include GeoAndLocaleSettings

  def change
    return_url = request.env["HTTP_REFERER"]
    if return_url.blank?
      return_url = root_url
    end

    unless session[:redirect_url].blank?
      return_url = session[:redirect_url]
      session[:redirect_url] = nil
    end

    locale = params[:locale]

    uuid = cookies[:intervac_user]
    CookieJar.where(uuid: uuid).first.update_attribute(:locale, locale)

    I18n.locale = ensure_correct_format(locale)

    respond_to do |format|
      format.html { redirect_to(return_url) }
    end
  end

  private

  def ensure_correct_format(locale)
    return 'en_GB' if locale.blank?
    l = locale.partition('_')
    l.last.upcase!
    l.join
  end
end
