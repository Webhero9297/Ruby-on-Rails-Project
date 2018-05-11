/* Scripts for Match Alert */
function init_match_alert_destination_autocomplete(){
	google_map = GOOGLE_MAP;
	google_map.autocomplete('match-alert-destination');
	autocomplete = google_map.autocompleter;

	google.maps.event.addListener(autocomplete, 'place_changed', function() {
		var place = autocomplete.getPlace();
		if (typeof place.geometry === 'undefined'){
      		//User just pressed enter so do a geocode lookup
      		geocode_address_and_submit_form(place.name);
			return;
		}
		set_form_geo_values(place);
		$('#match-alert-form').submit();
	});	
}

function geocode_address_and_submit_form(address){
	var geocoder = new google.maps.Geocoder();
	geocoder.geocode({"address":address }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK && results.length > 0) {
			var place = results[0];
			set_form_geo_values(place);
			$('#match-alert-form').submit();
		}
	});
}

function set_form_geo_values(place){
    if(place.geometry.viewport){
        var ne = place.geometry.viewport.getNorthEast();
        var sw = place.geometry.viewport.getSouthWest();
        $('#ne_lat').val(ne.lat());
        $('#ne_lng').val(ne.lng());
        $('#sw_lat').val(sw.lat());
        $('#sw_lng').val(sw.lng());
 	}
 	$('input#lat').val(place.geometry.location.lat());
	$('input#lng').val(place.geometry.location.lng());
 	$('input#destination').val(place.formatted_address);
	var country_short = GOOGLE_MAP.get_address_components(place.address_components, 'country', 'short');
	$('input#country-code').val(country_short);
}
