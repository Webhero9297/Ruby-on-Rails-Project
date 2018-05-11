function add_location_pins_to_map(map, pins, property_position){
    var marker;
    var icons = {
        'golfing':'/assets/golfing.png',
        'shopping': '/assets/shopping.png',
        'forest':'/assets/forest.png',
        'river':'/assets/river.png',
        'boating':'/assets/boating.png',
        'sea':'/assets/sea.png',
        'beach':'/assets/beach.png',
        'lake':'/assets/lake.png',
        'mountains':'/assets/mountains.png'
    };

    var markerBounds = new google.maps.LatLngBounds();
    markerBounds.extend(property_position);

    pins.each(function(index){
        $this = $(this);
        type = $this.data('id');
        lat = $this.data('lat');
        lng = $this.data('lng');
        latlng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));

        var options = {custom_icon: true, id: type, animation: google.maps.Animation.DROP}
        options.marker_image = new google.maps.MarkerImage(icons[type], new google.maps.Size(32, 37, 'px', 'px'));
        marker = map.add_marker(latlng, options);

        markerBounds.extend(latlng);
    });
}

function initialize_location_map() {
    var map_canvas = $('#surrounding-map');
    var map = Object.create(GOOGLE_MAP);
    var map_settings = {map_canvas: 'surrounding-map', zoom: 14};
    var property_position;

    map.draggable_markers = false;
    map.create(map_settings);
    property_position = new google.maps.LatLng(parseFloat(map_canvas.attr('data-lat')), parseFloat(map_canvas.attr('data-lng')));
    map.add_marker(property_position, {custom_icon:true})
    map.map.setCenter(property_position);

    return {'map' : map, 'property_position' : property_position};
}
