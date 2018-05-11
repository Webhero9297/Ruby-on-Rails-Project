function trim1 (str) {
    return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
}

function add_listings_info() {
  
  db.accounts_listings.drop();

  db.listings.find({}).forEach(function(listing) {

      if(listing.exchange_dates !== undefined) {
        last_date = new Date();
        listing.exchange_dates.forEach(function(ed){
          if(ed.latest_date > last_date){
            last_date = ed.latest_date;
          }
        });
      }

    var values = {
      account_id: listing.account_id,
      listing_id: listing._id,
      listing_number: listing.listing_number,
      listing_street: listing.street,
      listing_postal_town: listing.postal_town,
      listing_postal_code: listing.postal_code,
      listing_country: listing.country,
      listing_country_code: listing.country_code,
      listing_google_formatted_address: listing.google_formatted_address,
      listing_updated_at: listing.updated_at,
      listing_active: listing.active,
      exchange_dates_latest_date: last_date
    }

    db.accounts_listings.insert(values);
  });

}

function add_accounts_info() {
  var accounts_ids = [];
  var children = 0;
  var adults = 0;
  var kind = null;
  var subscription = {"kind" : null, "expires_at" : null, "created_at" : null, "renewal" : null};

  db.accounts_listings.find({}).forEach(function(account_listing) {
    accounts_ids.push(account_listing.account_id);
  });
  
  db.accounts.find({"_id": {$in: accounts_ids}}).forEach(function(account) {

    if(account.profile.children !== undefined) {
        children = account.profile.children.length;
    }

    if(account.profile.adults !== undefined) {
        adults = account.profile.adults.length;
    }

    if(account.subscriptions !== undefined) {
        var sub_len = account.subscriptions.length;
        subscription = account.subscriptions[sub_len - 1];
    }
    print(account.account_number);
    try{
    db.accounts_listings.update({"account_id" : account._id}, {$set: {
      account_number:             account.account_number,
      account_joined_at:          account.joined_at,
      account_activated_at:       account.activated_at,
      account_newsletter:         account.newsletter,
      account_exchanges_made:     account.exchanges_made,
      account_terminated:         account.terminated,
      account_comment:            account.agent_comment,
      account_country_short:      account.country_short,
      account_owner:              account.account_owner,

      contact_name:               trim1(account.contact.name),
      contact_email:              account.contact.email,
      contact_mobile:             account.contact.mobile,
      contact_telephone:          account.contact.telephone,
      contact_address:            account.contact.address,
      contact_city:               account.contact.postal_town,
      contact_postal_code:        account.contact.postal_code,
      contact_state:              account.contact.county,
      contact_country:            account.country_short,
      contact_fax:                account.contact.fax,

      profile_adults:             adults,
      profile_children:           children,

      subscription_active:        subscription.active,
      subscription_kind:          subscription.kind,
      subscription_renewal:       subscription.renewal,
      subscription_upgrade:       subscription.upgrade,
      subscription_expires_at:    subscription.expires_at,
      subscription_created_at:    subscription.created_at
    }});
    } catch(e){
      print(e);
    };
  });

}

function add_account_with_no_listings() {

  var accounts_ids = [];
  var children = 0;
  var adults = 0;
  var kind = null;
  var subscription = {"kind" : null, "expires_at" : null, "created_at" : null, "renewal" : null};

  db.accounts_listings.find({}).forEach(function(account_listing) {
    accounts_ids.push(account_listing.account_id);
  });
  
  print(db.accounts.find({"_id": {$nin: accounts_ids}}).count());

  db.accounts.find({"_id": {$nin: accounts_ids}}).forEach(function(account) {

    if(account.profile.children !== undefined) {
        children = account.profile.children.length;
    }

    if(account.profile.adults !== undefined) {
        adults = account.profile.adults.length;
    }

    if(account.subscriptions !== undefined) {
        var sub_len = account.subscriptions.length;
        subscription = account.subscriptions[sub_len - 1];
    }
    try{
    db.accounts_listings.insert({
      account_id:                 account._id,
      account_number:             account.account_number,
      account_joined_at:          account.joined_at,
      account_activated_at:       account.activated_at,
      account_newsletter:         account.newsletter,
      account_exchanges_made:     account.exchanges_made,
      account_terminated:         account.terminated,
      account_comment:            account.agent_comment,
      account_country_short:      account.country_short,
      account_owner:              account.account_owner,

      contact_name:               trim1(account.contact.name),
      contact_email:              account.contact.email,
      contact_mobile:             account.contact.mobile,
      contact_telephone:          account.contact.telephone,
      contact_address:            account.contact.address,
      contact_city:               account.contact.postal_town,
      contact_postal_code:        account.contact.postal_code,
      contact_state:              account.contact.county,
      contact_country:            account.country_short,
      contact_fax:                account.contact.fax,

      profile_adults:             adults,
      profile_children:           children,

      subscription_active:        subscription.active,
      subscription_kind:          subscription.kind,
      subscription_renewal:       subscription.renewal,
      subscription_upgrade:       subscription.upgrade,
      subscription_expires_at:    subscription.expires_at,
      subscription_created_at:    subscription.created_at
    });
    } catch(e){
      print(e);
    };
  });

}

function do_mapping() {
  add_listings_info();
  add_accounts_info();
  add_account_with_no_listings();
}

do_mapping();