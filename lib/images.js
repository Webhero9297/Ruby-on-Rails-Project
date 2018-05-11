
function remove_dup_images(){
  var counter = 0;
  db.listings.find({}).forEach(function(listing) {
      var images = [];

      if(listing.listing_images !== undefined) {

          listing.listing_images.forEach(function(image_obj){
              if(images.indexOf(image_obj.image) >= 0){
                db.listings.update({'_id': listing._id}, {$pull: {'listing_images': {'_id': image_obj._id}}});

              }else{
              images.push(image_obj.image);
            }
            });
      }
  counter  = counter + 1;
  print(counter);  
  });

}




function empty_images(){
  var counter = 0;
  db.listings.find({listing_images:{$exists:1}}).forEach(function(listing) {

      if(listing.listing_images !== undefined) {

          listing.listing_images.forEach(function(image_obj){
            if(!image_obj.image){
              print(image_obj.image);
              print("Listing number: "+listing.listing_number)

            }
            });
      }
  counter  = counter + 1;
  print(counter);  
  });

}


function set_path(){
  var counter = 0;
  db.listings.find({}).forEach(function(listing) {
      if(listing.listing_images !== undefined) {

          listing.listing_images.forEach(function(image_obj){
              var path = listing.country_code.toLowerCase() + "/" + listing.listing_number.toLowerCase();
              print(path);
              db.listings.update({'_id': listing._id, 'listing_images._id':image_obj._id}, {$set: {'listing_images.$.path': path}});
          });
      }
  counter  = counter + 1;
  print(counter);  
  });

}





function move_main_photo(){
  var counter = 0;

  db.listings.find({listing_images:{$exists:true}}).forEach(function(listing) {
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



function set_category(){
    var categories = ['home', 'surroundings'];
    var counter = 0;
    db.listings.find({listing_images:{$exists:true}, listing_images: {$elemMatch: {category: {$nin: categories}}}}).forEach(function(listing) {
        if(listing.listing_images.length > 0) {
            listing.listing_images.forEach(function(image_obj){

                if(image_obj === 'undefined' || image_obj == null){
                    return;
                }

                if( categories.indexOf(image_obj.category) == -1){
                    print("Listing number: "+listing.listing_number);

                    db.listings.update({'_id': listing._id, 'listing_images._id':image_obj._id}, {$set: {'listing_images.$.category': 'home'}});

                }
            });
            counter  = counter + 1;
        }
    });
    print(counter);

}

set_category();


















