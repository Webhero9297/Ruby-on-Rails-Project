function place_new(google_map) {
    var map_settings, google_map, location, marker;
    map_settings = {map_canvas: "map-canvas"};
    
    google_map.create(map_settings);
    google_map.autocomplete('location-address-field');
    
    location = LOCATION;
    marker = location.listner_place_changed(google_map);
    location.listner_dragend(marker);
}

function place_edit(coordinates) {
    var map_settings, google_map, location, lat, lng, latlng;
    lat = coordinates.lat;
    lng = coordinates.lng;
    
    map_settings = {map_canvas: "map-canvas", zoom: 16, lat: lat, lng: lng};
    
    google_map = GOOGLE_MAP;
    google_map.create(map_settings);
    google_map.autocomplete('location-address-field');
    location = LOCATION;
    
    latlng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));
    marker = google_map.add_marker(latlng, {});
    location.listner_dragend(marker);
    
    marker = location.listner_place_changed(google_map);
    location.listner_dragend(marker);
}


function place_show(coordinates) {
    var map_settings, google_map, location, latlng, lat, lng;
    
    lat = coordinates.lat;
    lng = coordinates.lng;
    
    map_settings = {map_canvas: "map-canvas", zoom: 16, lat: lat, lng: lng};
    google_map = GOOGLE_MAP;
    google_map.create(map_settings);
            
    location = LOCATION;
    latlng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng));
    marker = google_map.add_marker(latlng, {});    
}

function get_coordinates() {
    var latlng, lat, lng;
    
    lat = $('input#listing-location-lat').val();
    lng = $('input#listing-location-lng').val();
    latlng = {
        lat: lat,
        lng: lng
    };
    
    return latlng
}

function match_alert_buttons(){
  $('div.match-alert').each(function(index){
    var value = $(this).data('value');
    $(this).find('button').removeClass('active');
    if(value == true){
      $(this).find('button:nth-child(1)').addClass('active');
      return;
    }
    $(this).find('button:nth-child(2)').addClass('active');
  });
}

function activate_saved_filters_events(){
  $('form#save-filter-form').on('submit', function(event){
    event.preventDefault();
    filter_form_data = build_filter_form(false);
    this_form = $(this).serialize();
    this_form = this_form +'&'+ filter_form_data
    $.post('/member/searches/save.js', this_form, function(data){
    });
  });

  $('div.match-alert').popover({'title':'Match alert', 'content':'Match alert will notify you instantly when a new match is available.', 'trigger':'hover'});
  
  $('button.match-alert').click(function(event){
    $this = $(this);
    $.get($this.attr('data-href'), function(data){
    });

  });
  
  
}


LOCATION = {
    marker : {},
    listner_place_changed: function(google_map) {
        var that, autocomplete;
        
        that = this;
        
        autocomplete = google_map.autocompleter;
        marker_image = new google.maps.MarkerImage('/assets/marker.png', new google.maps.Size(41, 41, 'px', 'px'));
        this.marker = new google.maps.Marker({map: google_map.map, draggable: true, clickable: false, icon: marker_image});
        
        google.maps.event.addListener(autocomplete, 'place_changed', function() {
            
            var place = autocomplete.getPlace();
            if (typeof place.geometry === 'undefined'){
                return;
            }
            if (place.geometry.viewport) {
                google_map.map.fitBounds(place.geometry.viewport);
                that.set_form_values(place);
            } else {
                google_map.map.setCenter(place.geometry.location);
                google_map.map.setZoom(17);
                that.set_form_values(place);
            }
            
            google_map.clear_markers_from_map();
            that.marker.setPosition(place.geometry.location);
            
        });
        
        return this.marker;
    },
    
    listner_dragend: function(new_marker) {
        var that;
        that = this;
        marker = new_marker;
        google.maps.event.addListener(marker, 'dragend', function() {
            that.update_location(this.position);
        });
        
    },
    
    update_location: function(position) {
        var that, geocoder, latlng;
        that = this;
        geocoder = new google.maps.Geocoder();
        latlng = new google.maps.LatLng(parseFloat(position.lat()), parseFloat(position.lng()));
        geocoder.geocode( { 'latLng': latlng}, function(results, status) {
            that.set_form_values(results[0]);
        });
        
    },
    
    set_form_values: function(place) {
        var postal_town = GOOGLE_MAP.get_address_components(place.address_components, 'postal_town');
        
        if(postal_town === '') {
            postal_town = GOOGLE_MAP.get_address_components(place.address_components, 'locality');
        }
        
        if(postal_town === '') {
            postal_town = GOOGLE_MAP.get_address_components(place.address_components, 'administrative_area_level_1');
        }

        if(postal_town === '') {
            postal_town = GOOGLE_MAP.get_address_components(place.address_components, 'administrative_area_level_3');
        }

        var route = GOOGLE_MAP.get_address_components(place.address_components, 'route');
        var street_number = GOOGLE_MAP.get_address_components(place.address_components, 'street_number');
        
        if(route.length > 0){
            var street = route + ' ' + street_number;
        }
        
        if( street === undefined ){
            var street = GOOGLE_MAP.get_address_components(place.address_components, 'sublocality');   
        }

        
        var country_short = GOOGLE_MAP.get_address_components(place.address_components, 'country', 'short');
        var state = '';
        var state_long = '';
        if( country_short == 'US'){
            state = GOOGLE_MAP.get_address_components(place.address_components, 'administrative_area_level_1', 'short');
            state_long = GOOGLE_MAP.get_address_components(place.address_components, 'administrative_area_level_1');
        }

        var country = GOOGLE_MAP.get_address_components(place.address_components, 'country');

        $('input#listing-location-lat').val(place.geometry.location.lat());
        $('input#listing-location-lng').val(place.geometry.location.lng());
        $('input#listing-street').val(street);
        $('input#listing-postal-town').val(postal_town);
        $('input#listing-postal-code').val(GOOGLE_MAP.get_address_components(place.address_components, 'postal_code'));
        $('input#listing-state').val(state);
        $('input#listing-state-long').val(state_long);
        $('input#listing-country').val(country);
        $('input#listing-country-code').val(country_short);
        $('input#listing-formatted-address').val(place.formatted_address);
        
        if( $('input#listing-postal-town').val().length < 2 || $('input#listing-street').val() < 2){
            $('.inline-notification').hide();
            $('#address-warning').show();
        }else{
            $('.inline-notification').hide();
            $('#address-success').show();
            $('#btn-primary-listing').show();
            $('#postal-town-country').text($('input#listing-postal-town').val());
        }
    },
    
}

function main_photo_upload(element) {

    var button = $(element);

    var uploader = new plupload.Uploader({
      runtimes : 'html5,flash,html4',
      browse_button : button.attr('id'),
      max_file_size : '10mb',
      url : button.attr('data-url'),
      multipart: true,
      multipart_params: {
        "authenticity_token" : button.attr('data-token'),
        "category" : button.attr('data-category'),
        "format" : 'js'
      },
      flash_swf_url: "/assets/plupload/plupload.flash.swf"
    });

    uploader.bind('Error', function(up, error) {
        if(error.code == -600){
            alert("File size is too big. Please upload files less than 10MB.");
        }
    });

    uploader.bind('FilesAdded', function(up, files) {
      up.refresh();
      button.siblings('img.upload-pointer:first').attr('src','/assets/spinner.gif');
      setTimeout( function(){
        uploader.start();
      }, 500);
    });

    uploader.bind('Init', function(up, params) {
    });

    uploader.bind('FileUploaded', function(up, file, response) {
      if($('#image-message').length > 0) {
        $('#image-message').remove();
      }
      var json_response = $.parseJSON(response.response);
      if(json_response.error) {
        button.parent().parent().prepend('<div id="image-message" class="alert alert-danger">'+json_response.image+'</div>');
        button.siblings('img.upload-pointer:first').attr('src','/assets/upload-pointer.png');
        return;
      }
      button.parent().html(json_response.html);
      $('#main-photo-field').val(true);

    });

    uploader.init();

  }
