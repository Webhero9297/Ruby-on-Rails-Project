function set_last_login_at(){
  var counter = 0;
  db.users.find({}).forEach(function(user) {
      if(user.account_id !== undefined) {
          var account = db.accounts.findOne({_id:user.account_id});
          if(account !== undefined) {
            if(account.last_login_at === undefined || account.last_login_at < user.last_sign_in_at){
              db.accounts.update({'_id': account._id}, {$set: {last_login_at: user.last_sign_in_at}});
            }
          }
      }
  });

  counter  = counter + 1;
  print(counter);  
}



function sorry(){
  var now = new Date();
  var criteria = {active: true, account_expires_at: {$gte: now}, account_terminated: false, "exchange_dates.earliest_date" : {$exists:1}};
  db.listings.find(criteria).forEach( function(x){
    var account = db.accounts.findOne({_id:x.account_id});
    db.sorry.insert({account_id:x.account_id, sent: false, country_code: account.country_short});
  });
}


function set_postal_code(){
  db.accounts_listings.find({}).forEach(function(al) {
      if(al.account_id !== undefined) {
          var account = db.accounts.findOne({_id:al.account_id});
          if(account !== undefined && account != null && account.contact !== undefined) {
            //print(account.contact.postal_code);
            db.accounts_listings.update({'_id': al._id}, {$set: {contact_postal_code: account.contact.postal_code}});
          }
      }
  });  
}


function count_children(){
  db.listings.find({}).forEach( function(x){
    var account = db.accounts.findOne({_id:x.account_id});
    var adults = 0;
    var children = 0;
    if(account.profile.children !== undefined) {
        children = account.profile.children.length;
    }
    if(account.profile.adults !== undefined) {
        adults = account.profile.adults.length;
    }
    if(adults > 0 || children > 0){
      db.listings.update({_id:x._id}, {$set : {account_adults: adults, account_children: children}});
    }
  });
}


function country_short(){
  var criteria = {account_country_short: ""};
  db.listings.find(criteria).forEach( function(listing){
    var account = db.accounts.findOne({_id:listing.account_id});
    db.listings.update({_id:listing._id}, {$set : {account_country_short: account.country_short}});
  });
}


function set_awaiting(){
  db.accounts_listings.find({}).forEach(function(al) {
      if(al.account_id !== undefined) {
          var account = db.accounts.findOne({_id:al.account_id});
          if(account !== undefined && account != null) {
            db.accounts_listings.update({'_id': al._id}, {$set: {awaiting_access: account.awaiting_access}});
          }
      }
  });  
}


function set_match_alert(){
  alert_json = {
        "active" : false,
        "adults" : null,
        "capacity" : null,
        "children" : null,
        "earliest_date" : null,
        "environment_filters" : [],
        "exchange_type_filters" : [],
        "hotlist" : false,
        "house_filters" : [],
        "house_type_filters" : [],
        "latest_date" : null,
        "locations" : [],
        "reversed" : false,
        "surroundings" : []
    };

  db.accounts.find({}).forEach(function(al) {
      alert_json["_id"] = ObjectId();
      db.accounts.update({'_id': al._id}, {$set: {match_alert: alert_json}});
  });  
}

function set_mail_sent(){
  db.orders.find({}).forEach(function(order) {
    db.orders.update({'_id': order._id}, {$set: {mail_sent: true}});
  });  
}


function set_listing_numbers(){
  var counter = 0;
  db.accounts.find({}).forEach(function(account) {
    var has_hidden_listing = false;
    var listing_numbers = [];
    db.listings.find({account_id:account._id}).forEach(function(listing){
      if(!listing.searchable){
          db.listings.update({'_id': listing._id}, {$set: {open_for_exchange: false}});
      }
      listing_numbers.push(listing.listing_number);
    });

    db.accounts.update({'_id': account._id}, {$set: {listing_numbers: listing_numbers, has_hidden_listing: has_hidden_listing}});
    counter += 1;
    print(counter);
  });  
}

function set_current_expire(){
  db.accounts.find({}).forEach(function(al) {

    if(al.subscriptions !== undefined) {
        al.subscriptions.forEach(function(sub){
          if(sub.active == true){
            print(sub.expires_at);
            db.accounts.update({'_id': al._id}, {$set: {current_expires_at: sub.expires_at}});      
          }
          
        });
    }
  });  
}

function set_accessed_at(){
    var counter = 0;
    var now = new Date();
    //db.accounts.find({}).forEach(function(account) {
    //  db.accounts.update({'_id': account._id}, {$set: {accessed_at:now}});
    //});

    db.accounts.update({}, {$set: {accessed_at:now}}, {multi: true});

    counter  = counter + 1;
    print(counter);
}

function count_adults(){
    var count = 0;
    db.accounts.find({}).forEach( function(account){
        var adults = 1;
        if(account.profile.adults !== undefined) {
            if( account.profile.adults.length > 1){
                return;
            }
            count += 1;
            adults = account.profile.adults.length;

        }
        db.accounts.update({_id:account._id}, {$set : {"profile.number_of_adults": NumberInt(adults)}});
    });
    print(count);
}



function upgrade_searches(){


    db.accounts.find({searches: {$exists: true, $not: {$size: 0}} }).forEach(function(account) {
        if(account.searches !== undefined) {
            account.searches.forEach(function(search) {
                params = {};
                params["destination_form"] = search.q;
                params["filter_name"] = search.name;
                params["lat"] = search.lat;
                params["lng"] = search.lng;
                params["ne_lat"] = search.ne_lat;
                params["ne_lng"] = search.ne_lng;
                params["sw_lat"] = search.sw_lat;
                params["sw_lng"] = search.sw_lng;
                params["zoom"] = search.zoom;
                if(search.environment){
                    params["environment_filters"] = [search.environment];
                }
                if(search.sleeping_capacity){
                    params["capacity"] = search.sleeping_capacity;
                }
                params["earliest_date"] = search.earliest_date ? search.earliest_date.toISOString().substring(0,10) : "";
                params["latest_date"] = search.latest_date ? search.latest_date.toISOString().substring(0,10) : "";
                params["country_short"] = search.country_code ? search.country_code : "";
                search["params"] = params;
            });
        }
        
        db.accounts.save(account);
    });
}

upgrade_searches();





















