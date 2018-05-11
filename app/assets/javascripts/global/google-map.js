if (!Object.create) {
    Object.create = (function(){
        function F(){}

        return function(o){
            if (arguments.length != 1) {
                throw new Error('Object.create implementation only accepts one parameter.');
            }
            F.prototype = o
            return new F()
        }
    })()
}

GOOGLE_MAP = {
    map: {},
    autocompleter: {},
    markers: [],
    cluster: {},
    draggable_markers: true,
    idle_listener: {},
    bounds_listener: {},

    create: function(map_settings) {
        var that, latlng, map_options;
        map_settings.map_canvas = map_settings.map_canvas || 'map-canvas';
        map_settings.lat = map_settings.lat || '14.75';
        map_settings.lng = map_settings.lng || '-17.333333';
        map_settings.zoom = map_settings.zoom || 1;

        that = this;
        latlng = new google.maps.LatLng(parseFloat(map_settings.lat), parseFloat(map_settings.lng));
        map_options = {
            zoom: map_settings.zoom,
            center: latlng,
            scrollwheel: false,
            streetViewControl: false,
            maxZoom: 19,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        };

        this.map = new google.maps.Map(document.getElementById(map_settings.map_canvas), map_options);
    },

    autocomplete: function(input_field) {
        var that = this;
        var world_map = new google.maps.LatLng(-180, 180);
        var default_bounds = new google.maps.LatLngBounds(world_map, world_map);
        var input_field = document.getElementById(input_field);
        var autocomplete_options = {
            bounds: default_bounds,
            types: ['geocode']
        };

        this.autocompleter = new google.maps.places.Autocomplete(input_field, autocomplete_options);
    },

    get_address_components: function(address_components, component_to_find, name_type) {
        if(name_type === undefined) {
            name_type = 'long'
        }

        var i = 0;
        var l = address_components.length;
        var component = '';

        for(i; i < l; i = i + 1) {
            if(address_components[i].types[0] === component_to_find) {
                if(name_type == 'long') {
                    component = address_components[i].long_name;
                } else {
                    component = address_components[i].short_name;
                }

            }
        }

        return component;
    },

    add_marker: function(location, options) {
        var settings = {};

        settings.map = this.map;
        settings.id = options.id || null;
        settings.animation = options.animation || null;
        (options.draggable === undefined) ? settings.draggable = this.draggable_markers : settings.draggable = options.draggable;
        (options.clickable === undefined) ? settings.clickable = false : settings.clickable = options.clickable;
        (options.title === undefined) ? settings.title = "" : settings.title = options.title;

        if(options.custom_icon){
            settings.icon = options.marker_image || new google.maps.MarkerImage('/assets/marker.png', new google.maps.Size(41, 41, 'px', 'px'));
        }

        marker = new google.maps.Marker(settings, options);
        if (options.marker_image === undefined) {
            marker.setZIndex(google.maps.Marker.MAX_ZINDEX + 1);
        }

        marker.setPosition(location);
        this.markers.push(marker);
        return marker;
    },

    clear_markers_from_map: function() {
        var i = 0;
        var l = this.markers.length;

        for(i; i < l; i = i + 1) {
            this.markers[i].setMap(null);
        }

        this.markers = [];
    },

    make_cluster: function(){
        // Styles for the marker cluster
        styles = [{
            url: '/assets/cluster.png',
            height: 54,
            width: 54,
            anchor: [12, 0],
            textColor: '#ffffff',
            textSize: 12
        }];

        this.cluster = new MarkerClusterer(this.map, this.markers,{ styles: styles, gridSize: 80, maxZoom: 14});
    },

    clear_cluster: function(){
        try{
            this.cluster.clearMarkers();
            this.markers = [];
        } catch(err){
            //console.log(err);
        }
    },

    reset_map: function(property_position) {
        google.maps.event.trigger(this.map, 'resize');
        this.map.setCenter(property_position);
    }
};
