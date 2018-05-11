# encoding: UTF-8
module ApplicationHelper
  include Rack::Recaptcha::Helpers

  ##
  # Used for inserting a correct value for radio button tags based on bool values and should not have a default selection
  # Returns true, false or nil
  def radio_button_tag_value(tag_value, matching_value)
    return if tag_value.nil?
    tag_value == matching_value
  end

  ##
  # Used in email templates to prevent BETA and EDGE users to have other members land on BETA or EDGE when they don't have access
  # Takes a path as an argument for example cancel_path. Url helpers should not be used for example cancel_url
  def external_domain_link(path)
    if path.to_s.starts_with?('http://')
      raise "Wrong String Format URI should use _path not _url"
    end

    "http://#{Rails.application.config.external_domain}#{path}"
  end

  def markdown(text)
    MY_MARKDOWN.render(text).html_safe
  end

  def markdown_strip_tags(text, valid_tags = %w(p a br strong em))
    begin
      sanitize(
        MY_MARKDOWN.render(text),
        :tags => valid_tags, :attributes => %w(class href title)
      ).html_safe
    rescue
      text = MY_MARKDOWN.render(text).
        force_encoding('UTF-8').
        encode('UTF-16', :invalid => :replace, :replace => '').
        encode('UTF-8')

      sanitize(text, :tags => valid_tags, :attributes => %w(class href title)).html_safe
    end
  end

  def markdown_strip_p(text)
    markdown_strip_tags(text, %w(a br strong em))
  end

  def markdown_strip_all(text)
    begin
      strip_tags( MY_MARKDOWN.render(text)).strip.html_safe
    rescue
      text = MY_MARKDOWN.render(text).
        force_encoding('UTF-8').
        encode('UTF-16', :invalid => :replace, :replace => '').
        encode('UTF-8')

      strip_tags(text).strip.html_safe
    end
  end

  def title(page_title)
    content_for(:title) { page_title }
  end

  def meta_description(meta_description)
    content_for(:meta_description) { meta_description }
  end

  # Sets a "active" class to the the current route / view in the sub menu.
  class CurrentPageDecorator
    def initialize(helper,options)
      @helper = helper
      @html_class = options[:class] || 'active'
    end

    def link_to(*args,&blk)
      name = args.first
      options = args.second || { }
      html_options = args.third || { }
      html_options[:class] = @html_class if @helper.current_page?(options)
      @helper.link_to(name,options,html_options,blk)
    end

    def li_link_to(*args,&blk)
      name = args.first
      options = args.second || { }
      html_options = args.third || { }
      html_options[:class] = @html_class if @helper.current_page?(options)
      @helper.content_tag(:li, :class => @helper.current_page?(options) ? 'active' : '') do
        @helper.link_to(name,options,html_options,blk)
      end
    end
  end

  def highlight_current_link(options = { },&blk)
    raise ArgumentError unless block_given?
    yield CurrentPageDecorator.new(self,options)
  end

  def local_date(date, format = 'long')
    l(date.to_date, format: format.to_sym)
  end

  def standard_date(msg_date, format="%B %d, %Y")
    return if msg_date.nil?
    msg_date.strftime(format)
  end

  def standard_date_short(msg_date)
    return if msg_date.nil?
    msg_date.strftime("%b %d, %Y")
  end

  def standard_date_time(msg_date, time_zone = nil, format="%B %d, %Y - %H:%M")
    return if msg_date.nil?

    zone = ActiveSupport::TimeZone.new(time_zone || "UTC")
    msg_date.in_time_zone(zone).strftime(format)
  end

  ##
  # Returns the session time zone of the user. The session is set in the application controller
  def get_session_time_zone
    session[:time_zone]
  end

  def intervac_base_url
    'www.intervac-homeexchange.com'
  end

  def total_number_of_members
    '30,000'
  end

  def annual_number_of_exchanges
    '5000'
  end

  def minimum_monthly_price
    '6 EURO'
  end

  def length_of_trial_membership
    '20'
  end

  def number_of_agent_countries
    #Agent.all.length
    '99'
  end

  # Visitors Information
  def number_of_years_in_business
    Date.today.year - 1953
  end

  # TODO move to its own helper

  # When testing in a ruby console
  # do not forget to "include TranslationsHelper"
  # Otherwise the methods are unknown
  def download_po(file)
    link_to "#{file}.po", send_po_file_agent_translation_path(file), :method => :put
  end

  ##
  # Checks the session to see if the user is translating
  def user_can_translate?
    session[:can_translate] == true
  end

  ##
  # Checks the session to see if the user is translating
  def is_translating?
    if session[:is_translating] == true
      return true
    end
    return false
  end

  ##
  # Toggles the translation session
  def toggle_translating_session
    if session[:is_translating] == true
      session[:is_translating] = false
    else
      session[:is_translating] = true
    end
  end

  # Handle convenient links in translations
  # A translation can include link areas like this:
  #   "I am <link>a boy>/link> and I am <link>14</link>."
  # The link list contains two links which will be replaced
  # within the translation.
  # Or use a hash a argument to have a link title, e.g.
  #   {:url => search_index_path, :title => t('index.search_our_database')}
  def link_in_translation(translation, *link_list)
    return translation if link_list.size != translation.scan('<link>').size and link_list.size != translation.scan('</link>').size
    # find all <link></link> pairs
    parts = translation.split(/<link>|<\/link>/)
    rest = parts.pop if parts.size.modulo(2) == 1
    retstr = ''
    parts.each_with_index do |sub, i|
      if i.modulo(2) == 0
        obj = link_list.shift
        if obj.is_a?(Hash)
          url, title = obj[:url], obj[:title]
        else
          url = obj
        end
        retstr += sub + "<a href=\"#{url}\" title=\"#{title}\">"
      else
        retstr += sub + '</a>'
      end
    end
    retstr += rest unless rest.nil?
    retstr.empty? ? translation : retstr
  end

  # Handle span tags in translations
  # A msg_str/translation like "<big>Hello</big> <middle>new</middle> <small>world</small>"
  #   should be translated to "<big>Hello</big> <span class="middle">new</span> <small>world</small>"
  # with a call span_in_translation(translation, :middle => 'middle').
  # --- EXAMPLES FOR THE MAUS ---
  # <h1>span_in_translation(t('homepage.badges.middle.intervac_headline'), :highlight => 'blue')</h1>
  # -- OR - If you want to map 1-1 the class name with the translation tag
  # <h1>span_in_translation(t('homepage.badges.middle.intervac_headline'), 'blue')</h1>
  # --OR - If you want more than one class in the span...
  # <h1>span_in_translation(t('homepage.badges.middle.intervac_headline'), :blue => 'blue bold')</h1>
  def span_in_translation(translation, *span_list)
    span = span_list.size > 1 ? span_list : span_list.shift
    if span.is_a?(Hash)
      span.each do |tag, class_value|
        translation.gsub!("<#{tag}>", "<span class=\"#{class_value}\">")
        translation.gsub!("</#{tag}>", "</span>")
      end
    elsif span.is_a?(Array)
      span.each do |tag|
        translation.gsub!("<#{tag}>", "<span class=\"#{tag}\">")
        translation.gsub!("</#{tag}>", "</span>")
      end
    end
    translation
  end

  # Translation helper that simplifies variable substitution for Gettext
  def _(text, args = {})
    text = text % args
    return text.html_safe
  end

  # Overrides the normal t method in order to make it html_safe
  def t(text, args = {})
    begin
      if user_can_translate? and is_translating? and Translations.exists(text)
        begin
          text_icon = I18n.t(text, args)+" <i class='icon-edit translations-edit' data-msgid='#{text}'></i>"
          return text_icon.html_safe
        rescue
          text_icon = I18n.t(text)+" <i class='icon-warning-sign translations-edit' data-msgid='#{text}'></i>"
          return text_icon.html_safe
        end
      end
      return if text.blank?
      return I18n.t(text, args).html_safe
    rescue Exception => e
      begin
        return I18n.t(text, args).html_safe
      rescue Exception => e
        return text
      end
    end
  end

  # Uses textilize to render formatting.
  def rt(text, args = {})
    begin
      if user_can_translate? and is_translating? and Translations.exists(text)
        begin
          text_icon = textilize_without_paragraph(I18n.t(text, args))+" <i class='icon-edit translations-edit' data-msgid='#{text}'></i>"
          return text_icon.html_safe
        rescue
          text_icon = textilize_without_paragraph(I18n.t(text))+" <i class='icon-warning-sign translations-edit' data-msgid='#{text}'></i>"
          return text_icon.html_safe
        end
      end
      return if text.blank?
      return textilize_without_paragraph(I18n.t(text, args)).html_safe
    rescue
      return textilize_without_paragraph(I18n.t(text)).html_safe
    end
  end

  # Uses textilize to render formatting and also wraps the text in  <p> tags
  def rt_p(text, args = {})
    begin
      if user_can_translate? and is_translating? and Translations.exists(text)
        begin
          text_icon = textilize(I18n.t(text, args))+" <i class='icon-edit translations-edit' data-msgid='#{text}'></i>"
          return text_icon.html_safe
        rescue
          text_icon = textilize(I18n.t(text))+" <i class='icon-warning-sign translations-edit' data-msgid='#{text}'></i>"
          return text_icon.html_safe
        end
      end
      return if text.blank?
      return textilize(I18n.t(text, args)).html_safe
    rescue
      return textilize(I18n.t(text)).html_safe
    end
  end

  ##
  # Turns boolean values of true or false into Yes or No.
  def bool_to_word(bool)
    if bool == false then
      return t('global.no')
    end

    return t('sitewide.opinion.yes')
  end

  def text_if_missing(attribute)
    if attribute.blank? then
      return content_tag('span', t('profiles.helper.missing'), class: 'missing')
    end

    attribute
  end

  def if_empty_term(term, missing_text=t('exchange_agreement.empty_term'))
    if term.blank? then
      return content_tag('span', missing_text, class: 'missing')
    end

    term
  end

  def text_if_nil(attribute)
    if attribute.nil?
      return content_tag('span', t('profiles.helper.missing'), class: 'missing')
    end
    attribute
  end

  def link_to_listing(account_id)
    account = Account.find(account_id)
    span = "<span>"
    account.listings.each do |listing|
      span += '<a href="'+listing_url(listing)+'" title="Go to '+listing.listing_number+'">'+listing.listing_number+'</a>'
    end
    span += "</span>"
    return span.html_safe
  end

  ##
  # Makes sure there is two zeros after amount, should only be used in string print outs
  def format_currency(amount)
    "%.2f" % amount
  end

  ##
  # Checks if current session is admin
  def admin_session?
    session[:dashboard] == 'admin'
  end

  ##
  # Checks if current session is agent
  def agent_session?
    session[:dashboard] == 'agent'
  end

  ##
  # Checks for a specified dashboard
  def dashboard_is?(dashboard)
    session[:dashboard] == dashboard
  end

  def get_current_dashboard
    session[:dashboard] || "member"
  end

  def show_menu?
    !(user_signed_in? && session['dashboard'] == 'member')
  end

  def competition_email_address
    'thats-home-exchange@intervac.com'
  end

  ##
  # Used for sending odd or very difficult to detect patterns and errors inside a view file.
  def send_oddity(message)
    NotificationMailer.oddity(message).deliver rescue nil
  end

  ##
  # Used for hiding elements from a user if the content belongs to the user themselves or the account
  def show_for_member(account_id, user_account_id)
    account_id.to_s != user_account_id.to_s
  end

  # Contact is only possible if neighter listing or the current user
  # are expired
  def can_contact(current_user, listing)
    !(has_expired(current_user.account) || listing.is_expired)
  end

  def has_expired(account)
    return unless account

    subscription = account.current_subscription
    subscription.expires_at < Time.now.utc
  end
end
