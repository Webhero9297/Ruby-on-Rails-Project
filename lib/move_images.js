
function move_images(){
  var counter = 0;
  db.listings.find({}).forEach(function(listing) {
    if(listing.listing_images !== undefined) {
        listing.listing_images.forEach(function(image_obj){
            if(image_obj.category != 'home'){
              
            print("Moving: " + image_obj.image);
            db.accounts.update({'_id': listing.account_id}, {$addToSet: {'profile.profile_images': image_obj}});


            db.listings.update({'_id': listing._id}, {$pull: {'listing_images': {'_id': image_obj._id}}});

            }

        });
    }
    counter  = counter + 1;
    print(counter);  
  });

}
move_images();
