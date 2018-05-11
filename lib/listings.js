function set_searchable(){
  var now = new Date();
  var criteria = {active: true, account_expires_at: {$gte: now}, account_terminated: false, "exchange_dates.earliest_date" : {$exists:1}, "listing_images.main_photo":true};
  var count = 0;
  db.listings.find(criteria).forEach( function(listing){
    db.listings.update({_id:listing._id},{$set: {searchable:true}});
    count += 1;
  });
  print(count);
}

function add_searchable(){
  var count = 0;
  db.listings.find({searchable: {$exists:false}}).forEach( function(listing){
    db.listings.update({_id:listing._id},{$set: {searchable:false}});
    count += 1;
  });
  print(count);
}

//set_searchable();
//add_searchable();


function set_expires_at(){
  var count = 0;
  db.listings.find().forEach( function(listing){
    if(listing.account_id !== undefined) {
      var account = db.accounts.findOne({_id:listing.account_id});
      if(account !== undefined) {
        if(account.subscriptions !== undefined) {
          account.subscriptions.forEach(function(sub){
            if(sub.active == true){
              print(sub.expires_at);
              db.accounts.update({_id: account._id}, {$set: {current_expires_at: sub.expires_at}});
              db.listings.update({_id:listing._id}, {$set : {account_expires_at: sub.expires_at}});
            }
          });
        }
      }
    }
  });
}

//set_expires_at();

function set_listing_defaults(){
    var criteria = {$or: [{headline: ''}, {description: ''}, {property_type: ''}, {environment: ''}, {sleeping_capacity: 0}, {property_details: {$size: 0}}] };
    var count = 0;

    db.listings.find(criteria).forEach( function(listing){

        var account = db.accounts.findOne({_id: listing.account_id});
        var country = db.countries.findOne({short: account.country_short});
        var country_translation = db.translations.findOne({msgid: country.msgid, locale: 'en'});
        var country_value = country_translation.value.slice(1, country_translation.value.length-1);
        var headline = "Home in " + account.contact.postal_town + " " + country_value;

        if(listing.headline === '') {
            listing.headline = headline;
        }

        if(listing.description === '') {
            listing.description = headline;
        }

        if(listing.property_type === '') {
            listing.property_type = 'housetype.house';
        }

        if(listing.environment === '') {
            listing.environment = 'environment.in_the_city';
        }

        if(listing.sleeping_capacity === 0) {
            listing.sleeping_capacity = 1;
        }


        if(listing.property_details.length == 0) {
            listing.property_details = [
                'tag.no_pets',
                'tag.children_welcome'
            ];
        }

        db.listings.save(listing);
        count += 1;
    });
    print(count);
}


function set_listing_property_defaults(){
    var criteria = {$or: [{headline: ''}, {description: ''}, {property_type: ''}, {environment: ''}, {sleeping_capacity: 0}, {property_details: {$size: 0}}] };
    var count = 0;

    db.listings.find(criteria).forEach( function(listing){
        if(listing.listing_number == "IS1004561"){
            print("ICELAND");
            printjson(listing);

            var account = db.accounts.findOne({_id: listing.account_id});
            var country = db.countries.findOne({short: account.country_short});
            var country_translation = db.translations.findOne({msgid: country.msgid, locale: 'en'});
            var country_value = country_translation.value.slice(1, country_translation.value.length-1);
            var headline = "Home in " + account.contact.postal_town + " " + country_value;

            if(listing.headline === '') {
                listing.headline = headline;
            }

            if(listing.description === '') {
                listing.description = headline;
            }

            if(listing.property_type === '') {
                listing.property_type = 'housetype.house';
            }

            if(listing.environment === '') {
                listing.environment = 'environment.in_the_city';
            }

            if(listing.sleeping_capacity === 0) {
                listing.sleeping_capacity = 1;
            }


            if(listing.property_details.length == 0) {
                listing.property_details = [
                    'tag.no_pets',
                    'tag.children_welcome'
                ];
            }

            db.listings.save(listing);
            count += 1;
            printjson(listing);
        }
    });
    print(count);
}

set_listing_property_defaults();