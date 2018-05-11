Intervac::Application.routes.draw do
  # Custom error pages handled through the erros controller
  match '/404' => 'errors#not_found'
  match '/422' => 'errors#server_error'
  match '/500' => 'errors#server_error'

  # Namespaces and scopes to consolidate back office features
  namespace :management do
    get '/admin/dashboard', to: 'dashboards#admin'
    get '/agent/dashboard', to: 'dashboards#agent'
  end

  scope 'management' do
    # Agent management routes for both agents and admins
    resources :agents do
      get 'fetch_user', on: :collection
      member do
        post 'create_profile_image'
        delete 'destroy_profile_image'
        put 'add_agent_to_country', path: 'add-to-country'
        delete 'remove_agent_from_country', path: 'remove-from-country/:country_short'
        get 'remove_as_agent_confirm', path: 'remove-as-agent-confirm'
        get 'remove_as_agent', path: 'remove-as-agent'
      end
    end

    resources :accounts, module: 'accounts' do
      member do
        put 'set_nr_of_exchanges', path: 'set-nr-of-exchanges'
        put 'update_nr_of_allowed_listings', path: 'update-nr-of-allowed-listings'
        put 'set_joined_at', path: 'set_joined_at'
        put 'set_as_ambassador', path: 'set_as_ambassador'
        get 'confirm_termination', path: 'confirm/termination'
        get 'terminate'
      end
      get 'termination_confirmed', :on => :collection, :path => 'termination/confirmed'
    end

    resources :accounts, only: :none do
      get 'new_listing_as_agent' => 'listings', path: 'new/listing', as: 'new_listing'
      post 'create_listing_as_agent' => 'listings', path: 'create/listing', as: 'create_listing'

      resources :subscriptions, module: 'payment', only: :none do
        collection do
          get 'upgrade_account_as_agent', path: 'upgrade', as: 'upgrade'
          get 'renew_account_as_agent', path: 'renew', as: 'renew'
          post 'do_upgrade_or_renewal_as_agent', path: 'do-upgrade', as: 'do_upgrade'
          get 'account_upgraded_or_renewed_as_agent', path: 'upgraded', as: 'upgraded'
        end

        get 'full_details', on: :member, path: 'full-details', as: 'full_details'
      end
    end

    resources :base_listing, module: 'base', only: [:confirm_destroy, :destroy, :update_listing_number], as: 'management_listing', path: 'listings' do
      get 'confirm_destroy', path: 'confirm-destroy'
    end

    resources :listing_numbers, module: 'listings', only: [:edit, :update], as: 'management_listing_numbers', path: 'listing-numbers'
    resources :custom_city_and_country_headlines, module: 'listings', only: [:edit, :update], as: 'management_custom_city_and_country_headlines', path: 'customize-headline'

    match 'account/transfer/:account_id' => 'accounts/accounts#transfer_account', as: 'management_transfer', :via => :put
    match 'account/set-beta-access/:account_id/:access' => 'accounts/accounts#set_beta_access', as: 'set_beta_access', :via => :get

    resources :users, module: 'users', only: :none do
      member do
        get 'change_password_by_admin', path: 'change-password'
        put 'save_password_by_admin', path: 'save-password'
      end
    end

  end

  match '/translations/toggle' => 'admin/translations#toggle_translation', :via => :get, :as => 'toggle_translation'

  scope :module => "registration" do
    resources :price_plans, :path => 'price-plans' do
      get 'options', :on => :collection
      post 'promotion_code', :on => :collection, :path => 'promotion/code'
    end
  end

  match 'switch_user' => 'switch_user#set_current_user'
  match '/country-of-residence/(:country_short)' => 'registration/price_plans#country_of_residence', :via => [:get, :post], :as => 'country_of_residence'

  devise_scope :user do
    get "/logout" => "users/sessions#destroy", :path => 'service/logout'
    get "/login" => "users/sessions#new", :path => 'service/login'
    get "/resend_confirmation" => "users/registrations#resend_confirmation", :path => 'resend-confirmation'
    match '/signup/plan/:id/(:promotion_code)(.:format)' => 'users/registrations#new', :via => [:get, :post], :as => 'signup_plan'
    match '/signup/paid-plan/confirmation' => 'users/registrations#signup_confirmation_paid_plans', :via => :get, :as => 'paid_plan_confirmation'
    match '/signup/free-plan/confirmation' => 'users/registrations#signup_confirmation_free_plan', :via => :get, :as => 'free_plan_confirmation'
    match '/signup/paid-plan/cancel/:id' => 'users/registrations#cancel_signup', :via => :get, :as => 'cancel_signup'
    match '/signup/cancelled' => 'users/registrations#signup_cancelled', :via => :get, :as => 'signup_cancelled'
    match '/signup/skip-to-dashboard' => 'users/registrations#skip_to_dashboard', :via => :get, :as => 'skip_to_dashboard'
  end

  devise_for :users, :controllers => {:registrations => "users/registrations", :sessions => "users/sessions", :omniauth_callbacks => "users/omniauth_callbacks", :passwords => "users/passwords", :invitations => 'users/invitations'}

  match 'dashboard/overview' => 'dashboards#index', :via => :get, :as => 'member_dashboard'
  match 'dashboard/find-member-by-name' => 'dashboards#find_member_by_name', :via => :get, :as => 'find_member_by_name'
  match 'dashboard/find-member-by-number' => 'dashboards#find_member_by_number', :via => :get, :as => 'find_member_by_number'
  match 'guide/profile/address' => 'dashboards#profile_address', :via => :get, :as => 'guide_profile_address'
  match 'guide/profile/save/address' => 'dashboards#save_profile_address', :via => :post, :as => 'save_guide_profile_address'
  match '/dashboard/member/management' => 'dashboards#member_dashboard_for_management', via: :get, as: 'management_member_dashboard'
  match '/dashboard/information' => 'dashboards#information_page', via: :get, as: 'information_page'
  match '/dashboard/information/search' => 'dashboards#information_search', via: :get, as: 'information_search'

  scope :module => "users" do
    resource :user, :only => [:show, :edit_password, :save_password, :edit_email, :save_email] do
      member do
        get 'edit_password', :path => 'password/edit'
        put 'save_password', :path => 'password/save'
        get 'edit_primary_email', :path => 'email/edit/primary'
        put 'save_primary_email', :path => 'email/save/primary'
        get 'edit_secondary_email', :path => 'email/edit/secondary'
        delete 'delete_secondary_email', :path => 'email/delete/secondary'
        put 'save_secondary_email', :path => 'email/save/secondary'
        get 'edit_full_name', :path => 'full-name/edit'
        put 'save_full_name', :path => 'full-name/save'
        get 'connect_facebook', :path => 'connect-facebook'
      end
    end

    resource :facebook_graph, :path => 'facebook' do
      member do
        get 'connect'
        get 'link_account'
        get 'user_denied'
      end
    end
  end

  match '/accounts-listings/build' => 'accounts_listings#build', :via => :get, :as => 'build_accounts_listings'

  match '/missing-photos' => 'listings/missing_photos#index',  :via => :get, :as => 'missing_photos'
  match '/missing-photos/update' => 'listings/missing_photos#update',  :via => :post, :as => 'missing_photos_update'

  # Searching
  match '/search' => 'searches#index', :via => :get, :as => 'searches_index'
  match '/search/search' => 'searches#search', :via => :get, :as => 'searches_search'
  match '/search/map' => 'searches#map', :via => :get, :as => 'searches_map'
  match '/search/map-search' => 'searches#map_search', :via => :get, :as => 'searches_map_search'
  match '/search/listing-info/:listing_number' => 'searches#listing_info', :via => :get, :as => 'listing_info'
  match '/search/mapview-coords' => 'searches#mapview_coords', :via => :get
  match '/search/go-to-listing' => 'searches#go_to_listing', :via => :get, :as => 'searches_go_to_listing'
  match '/search/:id/find' => 'searches#do_saved_search', :via => :get, :as => 'do_saved_search'
  match '/search/save' => 'searches#save_search', :via => :post, :as => 'save_search'
  match '/search/delete' => 'searches#delete_saved_search', :via => :post, :as => 'delete_saved_search'

  # Listing routes
  resources :listings do
    collection do
      post 'find', :path => 'find'
      post 'get_listings', :path => 'get/listings'
    end

    member do
      get 'overview'
      get 'preview', as: 'preview'
      get 'enable'
      get 'disable'
      get 'exchange_settings', path: 'exchange-settings'
    end

    match '/set-availability/:availability' => "listings#set_availability_for_exchange", :via => :get, :as => 'set_availability'
    match '/set-availability-with-hotlist/:availability' => "listings#set_availability_with_hotlist", :via => :get, :as => 'set_availability_with_hotlist'

    # All listings resources should be moved and mapped in to this scope
    scope :module => "listings" do
      resource :presentations, only: [:show, :edit, :update] do
        get 'cancel', :on => :collection
      end

      resource :main_photos, only: [:show, :edit, :update] do
        post 'upload'
        get 'edit_caption'
        put 'update_caption'
        get 'cancel_caption'
      end

      resource :headlines, only: [:edit, :update] do
        get 'cancel'
      end
    end

    scope :module => "listing" do
      resource :location, :only => [:edit, :update] do
        get 'cancel', :on => :collection
      end
      match '/location/update-visibility/:status' => "locations#update_visibility", :via => :get, :as => 'update_visibility'

      resource :description, :only => [:edit, :update, :cancel] do
        get 'cancel', :on => :collection
      end

      resource :rule, :only => [:edit, :update, :cancel] do
        get 'cancel', :on => :collection
      end

      resource :property_setting, path: "property-settings", :only => [:edit, :update, :cancel] do
        get 'cancel', :on => :collection
      end

      resource :property_detail, path: "property-details", :only => [:edit, :update, :cancel] do
        get 'cancel', :on => :collection
      end

      resource :facility, :only => [:edit, :update]
      resource :surrounding, :only => [:show, :edit, :update] do
        get 'cancel', :on => :collection
        get 'edit_airport', :on => :member, path: 'edit-airport'
        get 'edit_description', :on => :member, path: 'edit-description'
        put 'update_airport', :on => :member, path: 'update-airport'
        get 'cancel_airport', :on => :member, path: 'cancel-airport'
        put 'update_description', :on => :member, path: 'update-description'
        get 'cancel_description', :on => :member, path: 'cancel-description'
      end

      resource :exchange_type, path: "exchange/types", :only => [:edit, :update, :cancel] do
        get 'cancel', :on => :collection
        get 'edit_duration', :on => :member, path: 'edit-duration'
        put 'update_duration', :on => :member, path: 'update-duration'
        get 'cancel_duration', :on => :member, path: 'cancel-duration'
      end

      resources :exchange_dates, path: "exchange/dates" do
        get 'cancel', :on => :collection
      end

      resources :images do
        member do
          # FIXME: a lot of wrong routes here... All of these *get*
          # should be *put* Just added `rotate_right` and
          # `rotate_left` following the same wrong pattern and
          # "guideline" but it must be fixed.

          get 'set_as_main', :path => 'set-as-main'
          get 'set_public', :path => 'set-public'
          get 'set_private', :path => 'set-private'
          get 'edit_caption', :path => 'edit-caption'
          put 'update_caption', :path => 'update-caption'
          get 'cancel_caption', :path => 'cancel-caption'
          get 'rotate_left'
          get 'rotate_right'
        end


        collection do
          post 'set_order', :path => 'set-order'
          post 'upload_main_photo', :path => 'main-photo'
          get 'rotate_main_photo_left'
          get 'rotate_main_photo_right'
          post 'upload_photo', :path => 'upload-photo'
          get 'get_images', :path => 'get/:size/:category', :as => 'get'
        end
      end
    end

    match 'guide/overview' => 'listings#guide_overview', :via => :get, :as => 'guide_overview'
    match 'guide/overview/save' => 'listings#save_guide_overview', :via => :post, :as => 'save_guide_overview'
    match 'number/(:listing_number)' => 'listings#show', :via => [:get, :post], :as => 'get_by_number', :on => :collection
  end

  namespace :member do
    resources :listings

    resources :feedbacks do
      get 'thank_you', :on => :member, :path => 'thank-you'
    end

    resources :exchange_agreements, :path => 'exchange/agreements' do
      post 'start', :on => :collection
      get 'add_participant', :on => :collection, :path => 'participant/add'
      delete 'remove_participant', :on => :collection, :path => 'participant/remove'
      get 'cancel', :on => :member
      get 'past', :on => :collection
      get 'references', :on => :collection
      post 'update_reference', :on => :collection
      post 'create_reference', :on => :collection
      get 'future', :on => :collection
      get 'cancelled', :on => :collection
      get 'send_to_partner', :on => :member
      get 'view_partner_terms', :on => :member
      get 'read_only_partner_terms', :on => :member
      get 'read_only_my_terms', :on => :member
      post 'handle_term', :on => :member
      get 'sign', :on => :member
      get 'review_done', :on => :member
      get 'show_and_sign', :on => :member
      get 'overview', :on => :member
    end
    match 'exchange/documents' => 'exchange_agreements#documents'
    match 'exchange/find-partner-by-number' => 'exchange_agreements#find_partner_by_number', :via => :get, :as => 'find_partner_by_number'

    resource :hot_list, :path => 'hot-list' do
      get 'overview', :on => :member
      match 'add/:listing_id' => 'hot_lists#add', :via => :get, :as => 'add'
      match 'remove/:listing_id' => 'hot_lists#remove', :via => :get, :as => 'remove'
    end

    resources :payments, path: 'payment', :only => [:index, :show]

    resources :searches
    match '/searches/:id/set-match-alert/:status' => "searches#set_match_alert", :via => :get, :as => 'set_match_alert'
  end

  scope "favorites" do
    match 'add/:listing_id' => 'favorites#add', :via => :get, :as => 'add_as_favorite'
    match 'selected/remove' => 'favorites#remove_favorites', :via => :post, :as => 'remove_favorites'
    match 'remove/:listing_id' => 'favorites#remove', :via => :delete, :as => 'remove_favorite'
  end

  resources :favorites, :only => [:index, :list, :add, :remove, :create, :update, :destroy] do
    get 'list', :on => :collection, path: 'multiple/contact'
    get 'conversation', :on => :collection, path: 'conversations/favorites'
  end

  resource :hot_list, :path => 'hot-list'

  match 'messages/:account_id/new' => 'conversations#new', :via => :get, :as => 'new_message'
  resources :conversations do
    get 'archive', :on => :member
    get 'show_agent_conversation', :on => :member
    collection do
      get 'member_agent_conversations_index'
      get 'archive_index', :path => 'archive/overview'
      post 'new_multi', :path => 'multi/message/new'
      post 'create_multi', :path => 'multi/message'
      post 'set_multiple_as_archived', :path => 'archive/messages'
      post 'set_multiple_as_deleted', :path => 'delete/messages'
    end
    match '/maybe-interested/:listing_owner' => "conversations#maybe_interested", :via => :get, :as => 'maybe_interested', :on => :member
    match '/not-interested/:listing_owner' => "conversations#not_interested", :via => :get, :as => 'not_interested', :on => :member
    match '/lets-talk/:listing_owner' => "conversations#lets_talk", :via => :get, :as => 'lets_talk', :on => :member

    match '/maybe-interested-no-user/:listing_owner' => "conversations#maybe_interested_no_user", :via => :get, :as => 'maybe_interested_no_user', :on => :member
    match '/not-interested-no-user/:listing_owner' => "conversations#not_interested_no_user", :via => :get, :as => 'not_interested_no_user', :on => :member
    match '/lets-talk-no-user/:listing_owner' => "conversations#lets_talk_no_user", :via => :get, :as => 'lets_talk_no_user', :on => :member

    match '/hide-past-listing/:listing_owner' => "conversations#hide_past_listing", :via => :get, :as => 'hide_listing', :on => :member
  end

  resources :message_templates, path: '/member/message/templates'
  match '/get-message-template/:id/(:kind)' => "message_templates#fetch_template", :via => :get, :as => 'fetch_message_template'

  match 'exchange/request/:account_id/new/:listing_id' => 'exchange_requests#new', :via => :get, :as => 'new_exchange_request'
  match 'exchange/request' => 'exchange_requests#create', :via => :post, :as => 'exchange_request'
  match 'exchange/request/cancel/:listing_id' => 'exchange_requests#cancel', :via => :get, :as => 'cancel_exchange_request'

  match 'member/message/:account_id/new/:listing_id' => 'member_messages#new', :via => :get, :as => 'new_member_message'
  match 'member/message' => 'member_messages#create', :via => :post, :as => 'member_message'
  match 'member/:listing_id/message/cancel' => 'member_messages#cancel', :via => :get, :as => 'cancel_member_message'

  # Contact multiple members
  match 'member/message/multiple' => 'member_messages#multi_message', :via => :post, :as => 'multi_member_message'
  match 'member/message/add-recipient/:listing_id' => 'member_messages#add_recipient_to_multi_list', :via => :get, :as => 'member_message_add_recipient'
  match 'member/message/remove-recipient/:listing_id' => 'member_messages#remove_recipient_from_multi_list', :via => :get, :as => 'member_message_remove_recipient'

  namespace :agent do
    match '/stats' => 'dashboards#stats', :via => :get
    resources :conversations do
      collection do
        get 'archive_index', :path => 'archive/overview'
        post 'set_multiple_as_archived', :path => 'archive/messages'
        post 'set_multiple_as_deleted', :path => 'delete/messages'
      end
    end
    resources :feedbacks
    resources :contact_messages, :path => 'contact/message'
    resources :exchange_agreements, :path => 'exchange/agreements', only: [:index, :show, :destroy] do
      get 'search', as: 'search', on: :collection
    end

    match '/translations/show-gettexts' => 'translations#show_gettexts', :as => 'translations_show_gettexts'
    match '/translations/new-from-gettext/:msgid' => 'translations#new_from_gettext', :via  => :get, :as => 'translations_new_from_gettext'
    match '/translations/delete-locale/:locale' => 'translations#delete_locale', :via => :get, :as => 'translations_delete_locale'
    match '/translations/get-by-locale/:locale' => 'translations#get_translations_by_locale', :as => 'translations_locale'
    match '/translations/get-by-category/:category' => 'translations#get_translations_by_category', :as => 'translations_category'
    match '/translations/get-by-category-and-locale/:category/:locale' => 'translations#get_translations_by_category_and_locale', :as => 'translations_category_and_locale'
    match '/translations/get-missing-by-locale/:locale' => 'translations#show_missing', :as => 'translations_missing'
    match '/translations/get-changed-by-locale/:locale' => 'translations#show_changed', :as => 'translations_changed'
    match '/translations/new-locale/' => 'translations#new_locale', :as => 'new_locale'
    match '/translations/clone-locale/' => 'translations#clone_locale', :as => 'clone_locale', :via => :post
    match '/translations/update-cloned-locale/:locale' => 'translations#update_cloned_locale', :as => 'update_cloned_locale', :via => :get
    match '/translations/search/' => 'translations#search', :as => 'translations_search'
    match '/translations/edit-on-page/:msgid/(:public)' => 'translations#edit_on_page', :as => 'translations_edit_on_page', :via => :get, :constraints => { :msgid => /[^\/]+/ }

    resources :translations, :constraints => { :id => /.*/ }
  end

  resources :automated_messages, path: '/automated/messages' do
    collection do
      get 'for_country', path: 'for-country/:country_id'
      get 'show_default', path: 'default-messages'
    end

    member do
      get 'edit_for_country', path: 'edit-for-country/:country_id'
      put 'update_for_country', path: 'update-for-country/:country_id'
      delete 'destroy_for_country', path: 'destroy-for-country/:country_id'
      get 'edit_default', path: 'edit-default-message'
      put 'update_default', path: 'update-default-message'
    end
  end
  match '/automated/messages/placeholders' => 'automated_messages#update_meta_data', :via => :post, :as => 'automated_messages_meta_data'
  match '/automated/messages/preview' => 'automated_messages#preview', :via => :post, :as => 'automated_messages_preview'

  namespace :admin do
    match '/dashboard' => 'dashboards#index', :via => :get
    resources :statistics do
      get 'system', on: :collection
    end
    resources :conversations
    resources :feedbacks
    resources :contact_messages, :path => 'contact/message'

    match '/translations/show-gettexts' => 'translations#show_gettexts', :as => 'translations_show_gettexts'
    match '/translations/new-from-gettext/:msgid' => 'translations#new_from_gettext', :via  => :get, :as => 'translations_new_from_gettext'
    match '/translations/delete-locale/:locale' => 'translations#delete_locale', :via => :get, :as => 'translations_delete_locale'

    match '/translations/get-by-locale/:locale' => 'translations#get_translations_by_locale', :as => 'translations_locale'
    match '/translations/get-by-category/:category' => 'translations#get_translations_by_category', :as => 'translations_category'
    match '/translations/get-by-category-and-locale/:category/:locale' => 'translations#get_translations_by_category_and_locale', :as => 'translations_category_and_locale'
    match '/translations/get-missing-by-locale/:locale' => 'translations#show_missing', :as => 'translations_missing'
    match '/translations/search/' => 'translations#search', :as => 'translations_search'
    match '/translations/delete-igettext/:id' => 'translations#delete_igettext', :as => 'translations_delete_igettext'
    match '/translations/new-locale/' => 'translations#new_locale', :as => 'new_locale'
    match '/translations/clone-locale/' => 'translations#clone_locale', :as => 'clone_locale', :via => :post
    match '/translations/create-locale/' => 'translations#create_locale', :as => 'create_locale', :via => :post
    match '/translations/update-cloned-locale/:locale' => 'translations#update_cloned_locale', :as => 'update_cloned_locale', :via => :get

    match '/translations/get-autocomplete-items' => 'translations#get_autocomplete_items', :via => :get,  :as => 'autocomplete_translations_msgid_admin_translations'

    resources :translations, :constraints => {:id => /.*/ }

    resources :newsletters do
      get 'download', :on => :collection
    end

    resources :paypal_ipns, :only => [:index, :show, :download], :path => 'paypal-ipns' do
      get 'download', :on => :collection
    end

    resources :orders, :only => [:index, :show, :download] do
      get 'download', :on => :collection
    end
  end

  resources :member_filters, :only => [:index], :path => 'member-filters' do
    collection do
      get 'sort'
      get 'search'
    end
  end

  # Shared account information between listings
  resources :listings, module: 'accounts', :only => [:none] do
    resource :lifestyles, :only => [:show, :edit, :update, :cancel], path: 'lifestyle-presentation' do
      get 'cancel', :on => :collection
    end
    resource :families, :only => [:show, :edit, :update, :cancel], path: 'family-presentation' do
      get 'cancel', :on => :collection
    end
  end

  match 'member-filters/download/:filename' => 'member_filters#download', :via => :get, :as => 'download_members'

  resources :accounts, only: :none do
    resource :time_zone, :only => [:show, :update], path: 'time-zone'
  end

  resources :accounts, :module => 'accounts' do
    get 'search', :on => :collection
    get 'filter', :on => :collection
    get 'download', :on => :collection, :path => 'members/download', :as => 'download_as_csv'

    resource :contacts, :only => [:show, :edit, :update] do
      get 'cancel', :on => :collection
    end

    resource :contact_restrictions, :only => [:show, :edit, :update, :create] do
      get 'cancel', :on => :collection
    end

    resource :profiles, :only => [:show, :incomplete, :unconfirmed] do
      member do
        get 'overview'
        get 'incomplete'
        get 'unconfirmed'
        put 'update_number_of_adults'
      end

      resources :adults, :module => 'profiles' do
        get 'cancel', :on => :collection
      end

      resources :children, :module => 'profiles' do
        get 'cancel', :on => :member
      end

      resources :pets, :module => 'profiles' do
        get 'cancel', :on => :member
      end

      resources :profile_images, path: 'photos', :as => 'images' do
        member do
          # FIXME: Yet another bad use of REST...
          get 'set_public', :path => 'set-public'
          get 'set_private', :path => 'set-private'
          get 'edit_caption', :path => 'edit-caption'
          put 'update_caption', :path => 'update-caption'
          get 'cancel_caption', :path => 'cancel-caption'
          get 'rotate_left'
          get 'rotate_right'
        end

        collection do
          post 'set_order', :path => 'set-order'
          get 'get_images', :path => 'get/:size/:category', :as => 'get'
        end
      end
    end

    resource :spoken_languages, path: 'spoken-languages', :only => [:edit, :update, :cancel] do
      get 'cancel', :on => :collection
    end

    resources :wish_lists, path: 'wish-list', :only => [:index, :create, :destroy, :cancel] do
      get 'cancel', :on => :collection
    end

    resources :match_alerts, path: 'match-alerts', :only => [:index, :create, :destroy, :cancel] do
      collection do
        get 'activate'
        get 'cancel'
        get 'disable'
        get 'remove_location', :path => 'remove_location/:location'

        post 'add_location'
        post 'add_filters'

        delete 'clear_filters'
      end
    end

    resources :co_members, path: 'co-members', :only => [:index, :new, :edit, :update, :create, :destroy, :cancel] do
      get 'cancel', :on => :collection
    end

    resources :payments, path: 'payment'
    resources :listings, path: 'listings', :only => [:index, :show, :statistics] do
      get 'statistics', :on => :collection
    end
    resources :subscriptions, :only => [:edit, :update]
    resources :favorites, :only => [:index]
  end

  match '/accounts/profile/set-open-for-all-destinations' => 'accounts/profiles#set_open_for_all_destinations', :via => :post, :as => 'set_open_for_all_destinations'

  # Lists all the assigned countries to the agent where the agent can edit the payment options per country
  match '/payment/country-payment-options-overview' => 'countries/payment_options#overview', :as => 'payment_options_overview', :via => :get

  resources :countries do
    # Country payment options
    scope :module => "countries" do
      resource :payment_options, :path => 'payment-options', :only => [:edit, :update]
    end

    scope :module => "payment" do
      resources :price_plans, :path => 'price-plans', except: [:show] do
        get 'set_as_active_inactive', :on => :member, :path => 'activate-deactivate'
        get 'set_as_default', :on => :member, :path => 'set-as-default'
        get 'country_assignment', :on => :member, :path => 'country-assignment'
        post 'assign_countries', :on => :member, :path => 'assign-countries'
        resources :promotion_codes, :path => 'promotion-codes', :as => 'promotion_codes' do
          get 'archive', :on => :member
        end
      end
    end

    scope :module => 'countries' do
      resource :merchant_information
    end

    get 'edit_currency', :on => :member, :path => 'edit-currency'
    put 'save_currency', :on => :member, :path => 'save-currency'
    get 'edit_default_locale', :on => :member, :path => 'edit-default-locale'
    put 'save_default_locale', :on => :member, :path => 'save-default-locale'
    get 'edit_kind', :on => :member, :path => 'edit-kind'
    put 'save_kind', :on => :member, :path => 'save-kind'
    put 'save_available_locales', :on => :member, :path => 'save-available-locales'
    get 'awaiting_access', on: :member, path: 'awaiting-access'
  end

  scope :module => "payment" do
    match 'renew-or-upgrade-membership-by-agent' => 'subscriptions#upgrade_or_renew_account_by_agent', :via => :post, :as => 'upgrade_or_renew_account_by_agent'
    match 'renew-or-upgrade-membership-information/:account_id' => 'subscriptions#upgrade_or_renewal_information', :via => :get, :as => 'upgrade_or_renewal_information'
    match 'order/cancelled/:order_id' => 'subscriptions#cancelled', :via => :get, :as => 'cancelled_order'
    match 'order/payment/option/:order_id' => 'subscriptions#payment_options', :via => :get, :as => 'payment_options'
    resources :subscriptions do
      collection do
        post 'special_renewal', to: "subscriptions#activate_special_renewal"
        get 'special_renewal'
        match 'receive_special_renewal_token/:id', to: "subscriptions#receive_special_renewal_token", via: [:get, :post], as: :receive_special_renewal_token
        get 'upgrade'
        get 'renew'
        post 'promotion_code'
        post 'setup_order'
      end
    end

    resources :orders, :path => 'orders', :as => 'orders' do
      member do
        get 'express'
        get 'success'
        get 'failure'
        get 'set_as_restricted'
        get 'invoice'
        post 'save_invoice'
        get 'french_payment_setup', :path => 'fr/payment/details'
        post 'french_payment_confirmation', :path => 'fr/payment/confirmation'
        get 'sage_pay_setup', :path => 'uk/payment/details'
        post 'sage_pay_confirmation', :path => 'uk/payment/confirmation'
        get 'sage_pay_notification', :path => 'uk/payment/notification'
        get 'generic_offline_payment_confirmation', :paty => 'offline/payment-confirmation'
      end
      post 'paypal_ipn', :on => :collection
    end
    match 'orders/fr/payment/notification' => 'orders#french_payment_notification', :via => [:post], :as => 'french_payment_notification'

    resource :information_text, :path => 'payment/information/text'
    resource :activation, :path => 'payment/automatic-activation', :as => 'automatic_activation', :only => ['show', 'update']
    resource :activation, :path => 'payment/account-activation', :as => 'account_activation', :only => ['awaiting', 'grant'] do
      get 'awaiting'
      put 'grant'
    end
  end

  match '/country/price-plans' => 'countries#price_plans', :via => :get, :as => 'price_plans_country'
  match '/newsletter/activation/:activation_code' => 'newsletters#activation', :via => :get, :as => 'newsletter_activation'
  resources :newsletters

  resources :exchange_feedbacks, :path => 'exchange-feedbacks' do
    collection do
      get 'positive_index', path: 'postive', as: 'positive'
      get 'negative_index', path: 'negative', as: 'negative'
      get 'thank_you', path: 'thank-you'
    end
  end

  resources :listing_statistics, :path => 'listing/statistics'
  match '/listing/stats/:listing_id' => 'listing_statistics#stats', :via => :get, :as => 'listing_stats'

  resources :feedbacks do
    get 'thank_you', :on => :member, :path => 'thank-you'
  end

  resources :representatives

  resources :mailing do
    collection do
      get 'send_test_message'
      get 'send_test_html_message'
      post 'receive_message'
      get 'receive_status'
      post 'receive_status'
    end
  end

  scope "country" do
    match 'choose' => 'countries#choose', :via => :get, :as => 'choose_country'
    match 'change/:short' => 'countries#change', :via => :get, :as => 'change_country'
  end

  match '/language/change/:locale' => 'languages#change', :as => 'change_language', :via => :get

  # What is home exchange  pages
  match '/homeexchange' => 'pages#what_is_home_exchange', :as => 'what_is_home_exchange', :via => :get
  match '/homeexchange/benefits' => 'pages#benefits_of_home_exchange', :as => 'benefits_of_home_exchange', :via => :get
  match '/homeexchange/with-intervac' => 'pages#home_exchange_with_intervac', :as => 'home_exchange_with_intervac', :via => :get
  match '/homeexchange/thinking-about' => 'pages#what_to_think_about', :as => 'what_to_think_about', :via => :get
  match '/homeexchange/checklist' => 'pages#home_exchange_checklist', :as => 'home_exchange_checklist', :via => :get
  match '/homeexchange/tips' => 'pages#exchange_tips', :as => 'exchange_tips', :via => :get

  # About intervac pages
  match '/facts-about-intervac' => 'pages#facts_about_intervac', :as => 'facts_about_intervac', :via => :get
  match '/membership-with-intervac' => 'pages#membership_with_intervac', :as => 'membership_with_intervac', :via => :get
  match '/local-representatives' => 'pages#local_representatives', :as => 'local_representatives', :via => :get
  match '/secure-exchanges' => 'pages#secure_exchanges', :as => 'secure_exchanges', :via => :get
  match '/words-from-our-members' => 'pages#words_from_our_members', :as => 'words_from_our_members', :via => :get
  match '/exchange-guarantee' => 'pages#our_guarantee', :as => 'our_guarantee', :via => :get
  match '/said-about-intervac-in-the-press' => 'pages#press_coverage', :as => 'press_coverage', :via => :get

  # Legal information pages
  match '/terms-of-use' => 'pages#terms_of_use', :as => 'terms_of_use', :via => :get
  match '/privacy-policy' => 'pages#privacy_policy', :as => 'privacy_policy', :via => :get

  # Cookie information
  match '/cookie-information' => 'pages#cookie_information', :as => 'cookie_information', :via => :get
  match '/accept-cookie' => 'cookie_information_bars#accept_cookies', :as => 'accept_cookies', :via => :get

  match '/you-have-been-logged-out' => 'pages#logged_out', :as => 'logged_out', :via => :get
  match '/signed-up-thank-you' => 'pages#signed_up', :as => 'signed_up', :via => :get
  match '/no-access' => 'pages#no_access', :as => 'no_access', :via => :get
  match '/facebook-login-information' => 'pages#facebook_login_information', :as => 'facebook_login_information', :via => :get
  match '/channel' => 'pages#channel', :as => 'channel', :via => :get # Used by the facebook JavaScript API
  match '/facebook-competitions' => 'pages#facebook_competition', :as => 'facebook_competition', :via => :get

  namespace :mobile do
    # Mobile dashboards controller
    match '/' => 'dashboards#start', :as => 'start', :via => :get
    match '/guest' => 'dashboards#guest', :as => 'guest', :via => :get

    # Mobile settings controller
    match '/settings' => 'settings#index', :as => 'settings', :via => :get
    match '/device/set-token/:device_token' => 'settings#set_device_token'
    match '/device/android/set-token/:device_token' => 'settings#set_android_device_token', :via => :get
    match '/device/destroy-token' => 'settings#destroy_device_token'

    # Mobile listings controller
    resources :listings, :only => [:index, :show] do
      get 'gallery', :on => :member
    end

    # Mobile messages
    match 'messages/unread' => 'messages#unread_messages', :as => 'unread_messages'
    resources :messages
    match 'messages/:listing_id/new' => 'messages#new', :via => :get, :as => 'new_message'

    # Mobile favorites
    match 'favorites' => 'favorites#index', :via => :get, :as => 'favorites'
    match 'favorites/:listing_id' => 'favorites#show', :via => :get, :as => 'favorite'
    match 'favorites/add/:listing_id' => 'favorites#add', :via => :get, :as => 'add_as_favorite'
    match 'favorites/remove/:listing_id' => 'favorites#remove', :via => :get, :as => 'remove_as_favorite'

    # Mobile search
    match 'search' => 'searches#find', :via => :get, :as => 'search'

    # Custom devise routes for mobile
    devise_scope :user do
      match "logout" => "sessions#destroy", :as => 'logout', :via => :get
      match "login" => "sessions#new", :as => 'login', :via => :get
    end
  end

  match 'faq' => 'faq#index', :as => 'faq', :via => :get
  match 'home-exchange-free-trial' => 'pages#landing', :as => 'landing', :via => :get

  # Root / index page for the site and application
  root :to => 'pages#index'
end
