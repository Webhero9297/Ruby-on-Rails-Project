
function add_pin(event){
  event.preventDefault();
  $this = $(this);
  if($this.hasClass('added'))
    return;// Already added so return
  
  var type = this.id;
  latlng = surround_map.map.getCenter();
  marker = add_marker_to_map(surround_map, type, latlng);
  // Calculate initial distance from the property
  calculate_route(property_position, marker.position, marker.id);
  var tr = create_tr(type);
  $('table#added-pins tbody').append(tr)
  $this.addClass('added');
  PINS.add_item(type, tr, marker);
}

function add_existing_pins(pins){
  
  var markerBounds = new google.maps.LatLngBounds();
  markerBounds.extend(property_position);

  pins.each(function(index){
    $this = $(this);
    type = $this.find('input.type').data('id');
    lat = $this.find('input.lat').val();
    lng = $this.find('input.lng').val();
    latlng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));

    marker = add_marker_to_map(surround_map, type, latlng);
    PINS.add_item(type, $this, marker);

    $('a#'+type).addClass('added');
    markerBounds.extend(latlng);
  });

  surround_map.map.fitBounds(markerBounds);
}

function remove_pin(event){
  event.preventDefault();
  $this = $(this);
  var type = $this.attr('href');
  $this.closest('tr').remove();
  $('#'+type).removeClass('added');
  
  pin = PINS.get_item(type)
  pin['marker'].setMap(null);
  
}


function add_property_location(map, coordinates) {
    var map_settings, lat, lng, latlng
    lat = coordinates.lat;
    lng = coordinates.lng;
    
    map_settings = {map_canvas: "surrounding-map", zoom: 16, lat: lat, lng: lng};
    
    map.draggable_markers = true;
    map.create(map_settings);
    
    latlng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));
    map.add_marker(latlng, {custom_icon: true, draggable: false})
    return latlng
}



function add_marker_to_map(map, type, latlng){
  
  var options = {custom_icon: true, id: type, animation: google.maps.Animation.DROP}
  options.marker_image = new google.maps.MarkerImage(icons[type], new google.maps.Size(32, 37, 'px', 'px'));
  marker = map.add_marker(latlng, options);
  google.maps.event.addListener(marker, 'dragend', function() {
      distance = calculate_route(property_position, this.position, this.id);
  });
  
  return marker
}

function calculate_route(org, dest, id) {

  var request = {
    origin: org,
    destination: dest,
    travelMode: google.maps.DirectionsTravelMode.DRIVING
  };
  var directionsService = new google.maps.DirectionsService();
  directionsService.route(request, function(result, status) {
    if (status == google.maps.DirectionsStatus.OK) {
      var dist = get_total_distance(result);
      PINS.set_distance(id, dist);
      PINS.set_position(id, dest);
      return result;
    }
    var dist = google.maps.geometry.spherical.computeDistanceBetween(org, dest);
    PINS.set_distance(id, make_km(dist));
    PINS.set_position(id, dest);
  });
}

// return total distance in km
function get_total_distance(result) {
    var meters = 0;
    var route = result.routes[0];
    for (ii = 0; ii < route.legs.length; ii++) {
        // Google stores distance value in meters
        meters += route.legs[ii].distance.value;
    }
    //Make it km with 1 decimal
    km = make_km(meters);
    return km;
}

function make_km(meters){
 //Make it km with 1 decimal
    km = meters/1000
    var num = new Number(km);
    var n=num.toFixed(1);
    return n; 
}


function create_tr(type){
  return $('<tr>\
  <td><img src="'+icons[type]+'"/></td>\
  <td>\
    <input type="text" class="input-xlarge" name="pins['+type+'][name]" placeholder="Give me a name"/>\
    <input type="hidden" name="pins['+type+'][distance]" class="distance"/>\
    <input type="hidden" name="pins['+type+'][lat]" class="lat"/>\
    <input type="hidden" name="pins['+type+'][lng]" class="lng"/>\
  </td>\
  <td class="distance"></td>\
  <td><a class="btn btn-small delete" href="'+type+'"><i class="icon-trash"></i></a></td></tr>');
}