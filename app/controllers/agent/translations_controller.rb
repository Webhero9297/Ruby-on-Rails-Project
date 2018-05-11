class Agent::TranslationsController < ApplicationController
  filter_access_to :all
  layout "management"
  
  
  def index
    
    @locales = current_user.agent_profile.locales
    @locale_stats = []
    for locale in @locales
      stats = Translations.get_statistics_for_locale(locale)
      next if stats.nil?
      @locale_stats.push(stats)
    end
  end

  def get_translations_by_locale
    @locale = params[:locale]
    categories = Translations.get_categories
    @stats = []
    categories.each do |c|
      @stats.push( Translations.get_statistics_for_locale_and_category(@locale, c) )
    end
    @is_cloned = Translations.is_cloned?(@locale)
    render :show_locale
  end
  
  def show_missing
    @locale = params[:locale]
    @translations = Translations.get_missing_translations_for_locale(@locale)
    @category = "All missing translations"
    @default_translations = Translations.get_default_translations
    render :edit_missing
  end


  def show_changed
    @locale = params[:locale]
    @translations = Translations.get_changed_translations_for_locale(@locale)
    @category = "All changed translations"
    @default_translations = Translations.get_default_translations
    render :edit_changed
  end
  
  def get_translations_by_category_and_locale
    @category = params[:category]
    @locale = params[:locale]
    @translations = Translations.get_translations_for_locale_and_category(@locale, @category)
    @default_translations = Translations.get_default_translations
    render :edit
  end
  
  def search
    term = params[:term]
    locale = params[:locale]
    missing = params[:missing]
    @translations = Translations.search(term, locale, missing)
    @default_translations = Translations.get_default_translations
    @locale = locale
    respond_to do |format|
      #format.html render :search_results
      format.js
    end
    
  end
  
  
  def new_locale
    @locales = Translations.available_locales
    @countries = current_user.agent_profile.agent_for
  end
  
  def clone_locale
    from_locale = params[:from_locale]
    for_country = params[:for_country]
    lang = from_locale.sub(/_.*/,'')
    to_locale = "#{lang}_#{for_country}"
    Translations.clone_locale(from_locale, to_locale)
    country = Country.get_by_short(for_country)
    msgid = Country.get_msgid_for_locale(from_locale)
    country.add_locale(to_locale, msgid)
    User.reload_agent_locales
    redirect_to :action=>:index
  end
  
  def update_cloned_locale
    locale = params[:locale]
    Translations.update_cloned_locale(locale)
    respond_to do |format|
      flash[:notice] = "Translations has been updated from original language"
      format.html {redirect_to :action=>:get_translations_by_locale}
      format.js {render(:nothing)}
    end
  end
  
  def edit
    @translation = Translations.find(params[:id])
    @locale = @translation.locale
    @categories = Translations.get_categories
    @default_translations = Translations.get_default_translations
    render :edit_single
  end

  def edit_on_page
    cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])

    @is_public = false
    if params[:public]
      @is_public = true
    end
    
    @translation = Translations.where(:msgid => params[:msgid], :locale => cookie_jar.locale).first
    respond_to do |format|
      if @translation.nil?
        format.js {render :nothing => true}
      else
        @locale = @translation.locale
        @categories = Translations.get_categories
        @default_translations = Translations.get_default_translations
        format.js
      end
    end
  end

  def update
    t = Translations.find(params[:id])
    t.update_translation(params[:value])
    flash.now[:success] = t('admin.info.text.translation_updated')
    respond_to do |format|
      format.html {redirect_to(request.referer)}
      format.js
    end
    
  end

  def destroy
  end

end