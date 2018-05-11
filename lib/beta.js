/**
 * Created by henke on 2014-10-17.
 */

// Account data sync current_expires_at and listing_nubmers
function set_listing_numbers_and_expires_at(){
    var counter = 0;
    db.accounts.find({}).forEach(function(account) {
        var has_hidden_listing = false;
        var listing_numbers = [];

        db.listings.find({account_id:account._id}).forEach(function(listing){
            if(!listing.searchable){
                has_hidden_listing = true;
                db.listings.update({'_id': listing._id}, {$set: {open_for_exchange: false}});
            }
            listing_numbers.push(listing.listing_number);
        });

        var data = {
            listing_numbers: listing_numbers,
            has_hidden_listing: has_hidden_listing
        };

        if(account.subscriptions !== undefined) {
            account.subscriptions.forEach(function(subscription){
                if(subscription.active == true){
                    current_expires_at = subscription.expires_at;
                    data['current_expires_at'] = current_expires_at;
                }
            });
        }

        db.accounts.update({'_id': account._id}, {$set: data });
        counter += 1;
        print(counter);
    });
}

// Images
function move_main_photo(){
    var counter = 0;
    db.listings.find({listing_images:{$exists:true}, main_photo:{$exists:false}}).forEach(function(listing) {
        if(listing.listing_images !== undefined) {
            listing.listing_images.forEach(function(image_obj){
                if(image_obj !== undefined){
                    try{
                        if(image_obj.main_photo){
                            print("Main photo");
                            db.listings.update({'_id': listing._id}, {$set: {'main_photo': image_obj.image, 'main_photo_path': image_obj.path, 'main_photo_caption':image_obj.caption}});
                        }
                    }catch(e){
                        print(e);
                    }
                }
            });
        }
        counter  = counter + 1;
        print(counter);
    });
}

/* Listings need to sync
:account_expires_at
:account_country_short
:account_terminated
:account_open_for_all_destinations
:account_children
:account_adults
:account_pets

:account_wish_lists

*/

function set_account_data_on_listings(){
    var criteria = {};
    db.listings.find(criteria).forEach( function(listing){
        var account = db.accounts.findOne({_id:listing.account_id});

        var adults = NumberInt(1);
        var children = NumberInt(0);
        var pets = NumberInt(0);

        if(account.profile.children !== undefined) {
            children = NumberInt(account.profile.children.length);
        }
        if(account.profile.number_of_adults !== undefined) {
            adults = NumberInt(account.profile.number_of_adults);
        }
        if(account.profile.pets !== undefined) {
            pets = NumberInt(account.profile.pets.length);
        }


        var data = {
            account_expires_at: account.current_expires_at,
            account_country_short: account.country_short,
            account_terminated: account.terminated,
            account_open_for_all_destinations: account.profile.open_for_all_destinations,
            account_adults: adults,
            account_children: children,
            account_pets: pets
        };


        db.listings.update({_id:listing._id}, {$set : data});
    });
}


function set_wishlists_on_listing(){
    var counter = 0;
    db.accounts.find({'profile.wish_list_destinations': {$not: {$size : 0}}}).forEach(function(account) {
        if(account.profile !== undefined && account.profile.wish_list_destinations !== undefined) {

            var lists = [];
            account.profile.wish_list_destinations.forEach(function(wish){
                var foo = {'location': wish.location, 'ne_lat' : wish.ne_lat, 'ne_lng' : wish.ne_lng, 'sw_lat' : wish.sw_lat, 'sw_lng' : wish.sw_lng, 'country_code' : wish.country_code};
                lists.push(foo);

            });

            db.listings.find({account_id:account._id}).forEach(function(listing) {
                db.listings.update({'_id': listing._id}, {$set: {'account_wish_lists': lists}});

            });

        }
        counter  = counter + 1;
        print(counter);
    });

}


print("Set listing data on account");
set_listing_numbers_and_expires_at();

print("Set account data on listings");
set_account_data_on_listings();

print("Set wishlists on listings");
set_wishlists_on_listing();

print("Moving main photos");
move_main_photo();