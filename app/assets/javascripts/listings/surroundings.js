function surroundings_map() {
    var location_map_canvas = $('#surrounding-map');    
    var location_map = Object.create(GOOGLE_MAP);
    var map_settings = {map_canvas: 'surrounding-map', zoom: 14};

    location_map.draggable_markers = false;

    location_map.create(map_settings);
    property_position = new google.maps.LatLng(parseFloat(location_map_canvas.attr('data-lat')), parseFloat(location_map_canvas.attr('data-lng')));
    location_map.add_marker(property_position, {custom_icon:true})
    location_map.map.setCenter(property_position);

    // Add any saved pins to the map
    var pins = $('span.pin');
    if(pins.length > 0) {
        add_pins(location_map, pins);    
    }
    
    $('img.legend').tooltip();

    return {'location_map' : location_map, 'property_position' : property_position};
}