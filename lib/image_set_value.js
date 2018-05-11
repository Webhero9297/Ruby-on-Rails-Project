
function set_public(){
  var counter = 0;
  db.listings.find({}).forEach(function(listing) {
      if(listing.listing_images !== undefined) {

          listing.listing_images.forEach(function(image_obj){
              if(image_obj.category == "home"){
                print("Setting value");
                db.listings.update({'_id': listing._id, 'listing_images._id':image_obj._id}, {$set: {'listing_images.$.publicly_visible': true}});
              }
          });
      }
  counter  = counter + 1;
  print(counter);  
  });

}




function set_home(){
  var counter = 0;
  db.listings.find({listing_images:{$exists : 1}}).forEach(function(listing) {
      if(listing.listing_images !== undefined) {

          listing.listing_images.forEach(function(image_obj){
              if(image_obj.category == "uncategorized"){
                print("Setting value");
                db.listings.update({'_id': listing._id, 'listing_images._id':image_obj._id}, {$set: {'listing_images.$.category': 'home'}});
              }
          });
      }
  counter  = counter + 1;
  print(counter);  
  });

}
set_home();
