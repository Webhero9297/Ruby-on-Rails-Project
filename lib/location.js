function change_location(){
  var counter = 0;
  db.listings.find({}).forEach(function(listing) {
     db.listings.update({'_id': listing._id}, {$set: {location_reversed: listing.location.reverse()}});
  });

  counter  = counter + 1;
  print(counter);  
}

function set_map_visibility(){
  var counter = 0;
  db.listings.find({}).forEach(function(listing) {
     db.listings.update({'_id': listing._id}, {$set: {map_visibility: 'guests'}});
  });

  counter  = counter + 1;
  print(counter);  
}

set_map_visibility();