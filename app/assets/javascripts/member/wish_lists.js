

function setup_wish_list_destination_form() {
    var google_map, autocomplete;
    
    $('#wish-list-form').submit(function() {
        return false;
    });
    
    google_map = GOOGLE_MAP;
    google_map.autocomplete('wish-list-destination');
    autocomplete = google_map.autocompleter;
    
    google.maps.event.addListener(autocomplete, 'place_changed', function() {
        var place = autocomplete.getPlace();
        save_wish_list_destination(place);
    });
    
}

function save_wish_list_destination(place) {
    var the_form, form_data;
    
    set_wish_list_values(place);
    the_form = $('form#wish-list-form');
    form_data = the_form.serialize();
    
    $.post('/member/wish-list.js', form_data, function(data) {
        reset_form_and_update_list(data);
    }, 'html');
    
}

function set_wish_list_values(place) {
    $('input#lat').val(place.geometry.location.lat());
    $('input#lng').val(place.geometry.location.lng());
    
    if(place.geometry.viewport){
        var ne_lat = place.geometry.viewport.getNorthEast().lat();
        var ne_lng = place.geometry.viewport.getNorthEast().lng();
        var sw_lat = place.geometry.viewport.getSouthWest().lat();
        var sw_lng = place.geometry.viewport.getSouthWest().lng();
        $('input#ne_lat').val(ne_lat);
        $('input#ne_lng').val(ne_lng);
        $('input#sw_lat').val(sw_lat);
        $('input#sw_lng').val(sw_lng);
    }
    $('input#destination').val(place.formatted_address);

    var country_short = GOOGLE_MAP.get_address_components(place.address_components, 'country', 'short');
    $('input#country-code').val(country_short);
    
}

function reset_form_and_update_list(data) {
    $('section#wish-list').html(data);
    $('input#wish-list-destination').val('');
}