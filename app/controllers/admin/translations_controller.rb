class Admin::TranslationsController < ApplicationController
  filter_access_to :all
  layout "management"
  
  # Overriding autocomplete method in order to scope
  def get_autocomplete_items
    results = Translations.msgid_search(params[:term], 'en')
    results_array = []
    results.each do |r|
      results_array.push(r.msgid)
    end
    respond_to do |format|
      format.json {render(:json => results_array)}
    end
  end
  
  def index
    @locales = Translations.available_locales
    @locale_stats = []
    for locale in @locales
      @locale_stats.push(Translations.get_statistics_for_locale(locale))
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
  
  def show_gettexts
    @gettexts = Igettext.all
    render :show_gettexts
  end
  
  def show_missing
    @locale = params[:locale]
    @translations = Translations.get_missing_translations_for_locale(@locale)
    @category = "All missing translations"
    @default_translations = Translations.get_default_translations
    render :edit_missing
  end
  
  def get_translations_by_category_and_locale
    @category = params[:category]
    @locale = params[:locale]
    @translations = Translations.get_translations_for_locale_and_category(@locale, @category)
    @default_translations = Translations.get_default_translations
    @categories = Translations.get_categories
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
      format.html
      format.js
    end
    
  end
  
  def new
    @locale = 'en'
    @translations = Translations.new
    @categories = Translations.get_categories
  end
  
  def new_from_gettext
    @gettext = Igettext.find(params[:msgid])
    @locale = 'en'
    @translations = Translations.new
    @categories = Translations.get_categories
  end
  
  def delete_locale
    Translations.delete_locale(params[:locale])
    Country.remove_locale(params[:locale])
    User.reload_agent_locales
    
    flash[:notice] = "Locale has been deleted"
    redirect_to :action=>:index
  end
  
  def create
    locale = params[:translations][:locale]
    msgid = params[:translations][:msgid]
    value = params[:translations][:value]
    category = params[:translations][:category]
    field_codes = params[:translations][:field_codes]
    
    t = Translations.new(new_translation_params)
    respond_to do |format|
      if t.valid?
        Translations.add_default_translation(locale, msgid, value, category)
        if params[:gettext_id]
          ig = Igettext.find(params[:gettext_id])
          ig.delete unless ig.nil?
        end
        flash[:notice] = 'Translation has been added.'
        format.html { redirect_to :action => :show_gettexts }
      else
        if params[:gettext_id]
          @gettext = Igettext.find(params[:gettext_id])
          @locale = 'en'
          @translations = t
          @categories = Translations.get_categories
          format.html {render :action => :new_from_gettext}
        else
          format.html {render :action => :new}
        end
      end
    end
  end
  
  def delete_igettext
    ig = Igettext.find(params[:id])
    ig.delete unless ig.nil?
    flash[:notice] = 'Translation has been deleted.'
    redirect_to request.referer
  end
  
  def edit
    @translation = Translations.find(params[:id])
    @locale = @translation.locale
    @categories = Translations.get_categories
    @default_translations = Translations.get_default_translations
    render :edit_single
  end

  def update
    t = Translations.find(params[:id])
    t.update_translation(params[:value])
    t.update_category(params[:category]) unless params[:category].nil?
    t.update_field_codes(params[:field_codes]) unless params[:field_codes].nil?
    flash.now[:success] = t('admin.info.text.translation_updated')
    respond_to do |format|
      format.js
      #redirect_to :action=>:index
    end
    
  end
  
  def new_locale
    @locales = Translations.available_locales
    @countries = Country.where(:kind => 'vip').order_by([:msgid, :asc]).all
    @all_countries = Country.all.order_by([:msgid, :asc]).all
  end

  def create_locale
    new_locale = params[:new_locale]
    new_locale_msgid = params[:new_locale_msgid]
    new_locale_short = params[:new_locale_short]
    new_locale_name = params[:new_locale_name]
    for_country = params[:for_country]
    Translations.create_locale(new_locale)
    Language.create(:msgid => new_locale_msgid, :short => new_locale_short)
    
    Translations.add_default_translation('en', new_locale_msgid, new_locale_name, category = 'languages', field_codes = '')
    country = Country.get_by_short(for_country)
    country.add_locale(new_locale, new_locale_msgid)
    User.reload_agent_locales
    redirect_to :action=>:index
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

  def destroy
  end

  
  def toggle_translation
    toggle_translating_session()

    respond_to do |format|
      format.html {redirect_to(request.referer)}
    end
  end

  
private
  
  def new_translation_params
    params.require(:translations).permit(:translations, :value, :category, :field_codes, :locale, :msgid)
  end
  
end