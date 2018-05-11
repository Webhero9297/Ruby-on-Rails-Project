authorization do
  role :guest do
    has_permission_on :hot_lists, :to => [:show]
    has_permission_on :listings, :to => [:index, :show, :search, :find, :get_listings]
    has_permission_on :feedbacks, :to => [:new, :create, :thank_you]
    has_permission_on :registration_price_plans, :to => [:index, :options, :promotion_code]
    has_permission_on :newsletters, :to => [:index, :new, :create, :activation]
    has_permission_on :mailing, :to => [:receive_message, :receive_status]
    has_permission_on :representatives, :to => [:index]
    has_permission_on :payment_orders, :to => [:paypal_ipn]
    has_permission_on :mobile_sessions, :to => [:new, :destroy]
    has_permission_on :mobile_listings, :to => [:index, :show, :gallery]
    has_permission_on :mobile_dashboards, :to => [:guest]
    has_permission_on :countries, :to => [:country_of_residence]
    has_permission_on :payment_subscriptions, :to => [:special_renewal,:activate_special_renewal,:receive_special_renewal_token]

    has_permission_on :conversations, :to => [:not_interested_no_user,:maybe_interested_no_user, :lets_talk_no_user, :hide_past_listing]
  end

  role :translator do
    includes :guest
  end

  role :restricted do
    includes :guest

    has_permission_on :dashboards, :to => [:index, :find_member_by_name, :find_member_by_number, :profile_address, :save_profile_address, :information_page, :information_search]
    has_permission_on :member_exchange_agreements, :to => [:index, :past, :future, :references, :update_reference, :create_reference, :cancelled, :documents, :overview]
    has_permission_on [:member_contacts, :member_spoken_languages], :to => [:edit, :update]
    has_permission_on [:member_adults, :member_children, :member_pets], :to => [:index, :create, :save, :destroy]
    has_permission_on :member_profile_images, :to => [:index, :edit, :create, :update, :destroy, :set_public, :set_private, :edit_caption, :update_caption, :cancel_caption]
    has_permission_on :member_wish_lists, :to => [:show, :update, :destroy]
    has_permission_on :member_family_members, :to => [:index, :new, :create, :destroy]
    has_permission_on :member_listings, :to => [:index, :show, :new, :create, :update, :destroy, :statistics]
    has_permission_on [
      :listing_descriptions,
      :listing_exchange_types,
      :listing_facilities,
      :listing_property_settings,
      :listing_property_details,
      :listing_rules,
      :listing_surroundings], :to => [:show, :edit, :update, :cancel, :edit_description,:edit_airport,:update_airport, :cancel_airport, :update_description, :cancel_description,:edit_duration,:update_duration,:cancel_duration]
    has_permission_on :listing_locations, :to => [:edit, :update, :cancel, :update_visibility]
    has_permission_on :listing_exchange_dates, :to => [:index, :show, :new, :edit, :create, :update, :destroy, :cancel]

    has_permission_on :listing_images, :to => [:index, :new, :show, :edit, :create, :update, :destroy, :set_public, :set_private, :edit_caption, :update_caption, :cancel_caption, :set_as_main, :upload_main_photo, :set_order, :missing_photos, :get_images, :rotate_left, :rotate_right, :rotate_main_photo_left, :rotate_main_photo_right]
    has_permission_on :conversations, :to => [:new, :create, :index, :member_agent_conversations_index, :show, :show_agent_conversation,  :archive, :archive_index]
    has_permission_on :mobile_messages, :to => [:index, :show, :unread_messages]
    has_permission_on :favorites, :to => [:index, :list, :conversation, :add, :remove, :remove_favorites, :create, :update, :destroy]
    has_permission_on :member_searches, :to => [:show, :set_match_alert]
    has_permission_on :member_feedbacks, :to => [:new, :create, :thank_you]

    has_permission_on :member_payments, :to => [:index, :show]
    has_permission_on :payment_subscriptions, :to => [:upgrade, :renew,:special_renewal,:activate_special_renewal,:receive_special_renewal_token, :promotion_code, :setup_order, :payment_options, :cancelled]
    has_permission_on :payment_orders, :to => [:express, :new, :create, :edit, :update, :success, :failure, :invoice, :save_invoice, :response_from_france, :sage_pay_setup, :sage_pay_confirmation, :sage_pay_notification, :french_payment_setup, :french_payment_confirmation, :generic_offline_payment_confirmation, :set_as_restricted]

    has_permission_on :listing_statistics, :to => [:index, :show, :stats]
    has_permission_on [:member_adults, :member_children, :member_pets], :to => [:new, :destroy]

    has_permission_on :agent_contact_messages, :to => [:new, :create]
    has_permission_on :exchange_feedbacks, :to => [:edit, :update, :thank_you]

    ## Account
    has_permission_on :accounts_profiles, :to => [:show, :incomplete, :unconfirmed, :set_open_for_all_destinations, :update_number_of_adults]
    has_permission_on [:accounts_profiles_pets, :accounts_profiles_adults, :accounts_profiles_children], :to => [:index, :new, :edit, :update, :cancel, :create, :destroy]
    has_permission_on :accounts_profile_images, :to => [:index, :edit, :create, :update, :destroy, :set_public, :set_private, :edit_caption, :update_caption, :cancel_caption, :set_order, :get_images, :rotate_left, :rotate_right]

    has_permission_on :accounts_spoken_languages, :to => [:edit, :update, :cancel]
    has_permission_on [:accounts_lifestyles, :accounts_families], :to => [:show, :edit, :update, :cancel]

    has_permission_on :accounts_wish_lists, :to => [:index, :create, :destroy, :cancel]
    has_permission_on :accounts_co_members, :to => [:index, :new, :edit, :update, :create, :destroy, :cancel]
    has_permission_on :accounts_payments, :to => [:index, :show]
    has_permission_on :accounts_contacts, :to => [:show, :edit, :update, :cancel]
    has_permission_on :accounts_contact_restrictions, :to => [:edit, :create, :update, :cancel]

    has_permission_on :listings, :to => [:overview, :preview, :exchange_settings, :destroy, :guide_overview, :save_guide_overview, :set_availability_for_exchange, :set_availability_with_hotlist]
    has_permission_on :listings_presentations, :to => [:show, :edit, :update, :cancel]

    # Mobile
    has_permission_on :mobile_dashboards, :to => [:start]
    has_permission_on :mobile_settings, :to => [:index, :set_device_token, :set_android_device_token, :destroy_device_token]
    has_permission_on :mobile_favorites, :to => [:index, :show, :add, :remove]

    # Users
    has_permission_on :users_users, :to => [:show, :edit_primary_email, :save_primary_email, :edit_secondary_email, :edit_full_name, :delete_secondary_email, :save_full_name, :save_secondary_email, :edit_password, :save_password, :connect_facebook]

    has_permission_on :message_templates, :to => [:index, :new, :create, :edit, :update, :destroy, :fetch_template]
    has_permission_on [:exchange_requests, :member_messages], :to => [:new, :create, :cancel, :add_recipient_to_multi_list, :remove_recipient_from_multi_list, :multi_message]

    has_permission_on :time_zones, :to => [:show, :update]
  end

  role :trial_member do
    includes :guest, :restricted

    has_permission_on :match_alerts, :to => [:index]
    has_permission_on :member_listings, :to => [:enable, :disable]
    has_permission_on :listing_listings, :to => [:enable, :disable]
    has_permission_on :member_hot_lists, :to => [:add, :remove]
    has_permission_on :users_facebook_graphs, :to => [:connect, :link_account]
    has_permission_on :listings, :to => [:show, :get_listings, :enable, :disable]
    has_permission_on :conversations, :to => [:index, :show, :archive, :archive_index, :new, :create, :new_multi, :create_multi, :update, :destroy, :not_interested,:maybe_interested, :lets_talk, :hide_past_listing, :get_message_template, :set_multiple_as_archived, :set_multiple_as_deleted]
    has_permission_on :mobile_messages, :to => [:new, :create, :update]
    has_permission_on :exchange_requests, :to => [:new, :create]
    has_permission_on :member_exchange_agreements, :to => [:start, :show, :new, :find_partner_by_number, :create, :edit, :update, :cancel, :add_participant, :remove_participant, :view_partner_terms, :handle_term, :sign, :send_to_partner, :review_done, :read_only_partner_terms, :read_only_my_terms, :show_and_sign]
  end

  role :member do
    includes :trial_member
  end

  role :contact_agent do
    includes :member
  end

  role :agent do
    includes :contact_agent

    has_permission_on :pages, :to => [:all]
    has_permission_on :dashboards, :to => [:member_dashboard_for_management]
    has_permission_on :base_base_listing, :to => [:confirm_destroy, :destroy]
    has_permission_on :agent_dashboards, :to => [:index, :stats]
    has_permission_on :agent_members, :to => [:index, :list, :show, :sort]

    has_permission_on :agent_profiles, :to => [:edit, :update]
    has_permission_on :agent_profile_images, :to => [:show, :create, :destroy]
    has_permission_on :agent_conversations, :to => [:index, :show, :new, :create, :archive, :archive_index, :update, :destroy]
    has_permission_on :agent_feedbacks, :to => [:index, :show]
    has_permission_on :agent_contact_messages, :to => [:new, :create]
    has_permission_on :agent_translations, :to => [
      :index,
      :get_translations_by_locale,
      :show_missing,
      :show_changed,
      :get_translations_by_category_and_locale,
      :edit,
      :update,
      :destroy,
      :clone_locale,
      :new_locale,
      :update_cloned_locale,
      :search,
      :edit_on_page,
      :want_to_translate
      ]
    has_permission_on :agent_exchange_agreements, :to => [:index, :show, :destroy, :search]

    has_permission_on :accounts_accounts, :to => [:index, :show, :search, :filter, :confirm_termination, :terminate, :set_joined_at,:set_as_ambassador, :termination_confirmed, :transfer_account, :set_nr_of_exchanges, :update_nr_of_allowed_listings]
    has_permission_on :accounts_listings, :to => [:show, :destroy, :enable, :disable]
    has_permission_on :member_filters, :to => [:index, :sort, :search, :download]

    has_permission_on [
      :accounts_listing_descriptions,
      :accounts_listing_facilities,
      :accounts_listing_property_settings,
      :accounts_listing_locations,
      :accounts_listing_surroundings,
      :accounts_listing_exchange_types
      ], :to => [:edit, :update]

      has_permission_on :accounts_listing_exchange_dates, :to => [:index, :show, :new, :edit, :create, :update, :destroy]
      has_permission_on :accounts_listing_photos, :to => [:index, :new, :show, :edit, :create, :update, :destroy, :set_public, :set_private, :edit_caption, :update_caption, :set_as_main]
      has_permission_on :accounts_favorites, :to => [:index]
      has_permission_on :countries, :to => [:index, :show, :price_plans, :awaiting_access]
      has_permission_on :accounts_subscriptions, :to => [:edit, :update]
      has_permission_on :payment_price_plans, :to => [:index, :show, :new, :create, :edit, :update, :set_as_active_inactive, :set_as_default, :destroy, :country_assignment, :assign_countries]
      has_permission_on :payment_promotion_codes, :to => [:new, :show, :create, :edit, :update, :destroy, :archive]
      has_permission_on :payment_subscriptions, :to => [:upgrade_account_as_agent, :renew_account_as_agent, :do_upgrade_or_renewal_as_agent, :account_upgraded_or_renewed_as_agent, :full_details]
      has_permission_on :exchange_feedbacks, :to => [:index, :show, :positive_index, :negative_index]
      has_permission_on :automated_messages, :to => [:index, :new, :show_default, :edit_default, :update_default, :create, :update, :edit, :destroy, :update_meta_data, :preview, :for_country, :edit_for_country, :update_for_country]
      has_permission_on :admin_translations, :to => [:toggle_translation]
      has_permission_on :listings, :to => [:new_listing_as_agent, :create_listing_as_agent]
      has_permission_on :dashboard_countries, :to =>[:index, :show]
      has_permission_on :accounts_accounts, :to => [:terminate, :termination_confirmed, :set_joined_at]
      has_permission_on :accounts_transfers, :to => [:new, :create]
      has_permission_on :users_users, :to => [:change_password_by_admin, :save_password_by_admin]
  end

  role :admin do
    includes :guest, :member, :agent

    has_permission_on :admin_dashboards, :to => [:index]
    has_permission_on :admin_agents, :to => [:index, :new, :show, :create, :edit, :update, :destroy, :fetch_user]
    has_permission_on :admin_agent_images, :to => [:index, :create, :destroy]
    has_permission_on :admin_country_assignments, :to => [:index, :add, :remove]
    has_permission_on :admin_statistics, :to => [:index]
    has_permission_on :admin_members, :to => [:index, :list]
    has_permission_on :admin_conversations, :to => [:index, :show, :new, :create, :archive, :archive_index, :update, :destroy]
    has_permission_on :admin_feedbacks, :to => [:index, :show]
    has_permission_on :admin_contact_messages, :to => [:new, :create]
    has_permission_on :admin_newsletters, :to => [:index, :download]
    has_permission_on :admin_statistics, :to => [:index, :system]
    has_permission_on :admin_translations, :to => [:index, :new, :create, :update, :edit, :get_translations_by_locale, :show_gettexts, :show_missing,
      :get_translations_by_category_and_locale, :new_from_gettext, :delete_locale, :search, :delete_igettext, :get_autocomplete_items,
      :autocomplete_translations_msgid, :clone_locale, :new_locale, :update_cloned_locale, :destroy, :want_to_translate, :create_locale]

    has_permission_on :payment_price_plans, :to => [:destroy]
    has_permission_on [:admin_orders, :admin_paypal_ipns], :to => [:index, :show, :download]
  end
end
