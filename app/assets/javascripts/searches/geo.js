function init_destination_autocomplete() {
    var google_map;
    google_map = GOOGLE_MAP;
    google_map.autocomplete('destination');
    autocomplete = google_map.autocompleter;
    google.maps.event.addListener(autocomplete, 'place_changed', function () {
        var place = autocomplete.getPlace();

        if (typeof place.geometry === 'undefined') {
            //User just pressed enter so do a geocode lookup
            geocode_and_submit_manual_address(place.name);
            return;
        }
        // Sometimes viewport is missing so do a manual lookup
        if( typeof place.geometry.viewport === 'undefined') {
            geocode_and_submit_manual_address(place.formatted_address);
            return;
        }
        set_form_geo_values(place)
        $('#search-form').submit();
    });
}

function show_markers(fit_bounds, coords) {
    var position;
    var markerBounds = new google.maps.LatLngBounds();
    var infowindow = setup_infowindow();

    google.maps.event.addListener(google_map.map, 'click', function () {
        infowindow.close();
    });

    google.maps.event.addListener(infowindow, 'domready', function () {
        // Make all links in infowindow to use ajax.
        $('.info-window').on('click', 'a.bookmark, a.bookmarked', function (event) {
            var $this = $(this);
            var method = 'GET';
            if ($this.data('method')) {
                method = 'DELETE';
            }
            event.preventDefault();
            event.stopPropagation();
            $.ajax({
                method: method,
                url: this.href,
                dataType: 'script'
            });
        });
        $('.info-window .bookmark, .info-window .bookmarked').tooltip();
    });

    if (typeof coords == 'undefined') return;
    var total_count = coords.length;
    if (total_count > 0) {
        for (var index = 0; total_count > index; index = index + 1) {
            position = new google.maps.LatLng(coords[index].coord[0], coords[index].coord[1]);
            var marker = google_map.add_marker(position, {
                custom_icon: true,
                clickable: true,
                title: coords[index].number
            });
            google.maps.event.addListener(marker, 'click', function () {
                infowindow.close();
                var this_marker = this;
                $.ajax({
                    'url': '/search/listing-info/' + this_marker.title,
                    'dataType': 'json',
                    'success': function (data) {
                        infowindow.setContent(data.html);
                        infowindow.open(google_map.map, this_marker);
                    }
                });
            });
            markerBounds.extend(position);
        }

        google_map.make_cluster(google_map.map);

        if (fit_bounds && total_count > 1) {
            google_map.map.fitBounds(markerBounds);
            return;
        }

        if (total_count == 1) {// When only one listing set zoom to 13
            google_map.map.setCenter(position);
            google_map.map.setZoom(13);
        }
    }
}

function setup_infowindow() {
    var myOptions = {
        content: ""
        , disableAutoPan: false
        , maxWidth: 0
        , pixelOffset: new google.maps.Size(-100, 0)
        , zIndex: null
        , boxStyle: {
            background: "url('http://google-maps-utility-library-v3.googlecode.com/svn/trunk/infobox/examples/tipbox.gif') no-repeat -39px 0",
            opacity: 1,
            width: "200px"
        }
        , closeBoxMargin: "10px 2px 2px 2px"
        , closeBoxURL: "http://www.google.com/intl/en_us/mapfiles/close.gif"
        , infoBoxClearance: new google.maps.Size(1, 1)
        , isHidden: false
        , pane: "floatPane"
        , enableEventPropagation: true
    }
    return new InfoBox(myOptions);
}

function init_google_map(map, settings) {
    map.draggable_markers = false;
    map.create(settings);
}

function init_map_autocomplete(input) {
    google_map.map.controls[google.maps.ControlPosition.TOP_LEFT].push(input);

    var autocomplete = new google.maps.places.Autocomplete(input);
    autocomplete.bindTo('bounds', google_map.map);

    google.maps.event.addListener(autocomplete, 'place_changed', function () {
        var place = autocomplete.getPlace();
        if (!place.geometry) {
            //User used Enter key so try a geocode (asynchronos)
            geocode_address(place.name, function (result) {
                if (result.geometry.viewport) {
                    google_map.map.fitBounds(result.geometry.viewport);
                }
                return
            });
            return;
        }
        // If the place has a geometry, then present it on a map.
        if (place.geometry.viewport) {
            google_map.map.fitBounds(place.geometry.viewport);
        } else {
            google_map.map.setCenter(place.geometry.location);
            google_map.map.setZoom(17);  // Why 17? Because it looks good.
        }
    });
}


function set_form_viewport_values(map) {
    var center = google_map.map.getCenter();
    var zoom = google_map.map.getZoom();
    $('#lat').val(center.lat());
    $('#lng').val(center.lng());
    $('#zoom').val(zoom);
    //This block manupulates brwoser history when zooming and paning
    var state = History.getState();
    var current_url = state.hash
    var new_url = removeURLParam(current_url, 'zoom');
    new_url = removeURLParam(new_url, 'lat');
    new_url = removeURLParam(new_url, 'lng');
    new_url = new_url + (new_url.search("&") == -1 ? "?" : "&") + "zoom=" + zoom + "&lat=" + center.lat() + "&lng=" + center.lng();
    history.replaceState(null, null, new_url);
}

function removeURLParam(url, param) {
    var urlparts = url.split('?');

    if (urlparts.length >= 2) {
        var prefix = encodeURIComponent(param) + '=';
        var pars = urlparts[1].split(/[&;]/g);
        for (var i = pars.length; i-- > 0;)
            if (pars[i].indexOf(prefix, 0) == 0)
                pars.splice(i, 1);
        if (pars.length > 0)
            return urlparts[0] + '?' + pars.join('&');
        else
            return urlparts[0];
    } else {
        return url;
    }
}

function geocode_and_submit_manual_address(address) {
    if(address) {
        var geocoder = new google.maps.Geocoder();
         geocoder.geocode({"address": address}, function (results, status) {
            if (status == google.maps.GeocoderStatus.OK && results.length > 0) {
                var place = results[0];
                set_form_geo_values(place);
                $('#search-form').submit();
            } else {
                if (address) {
                    alert("Sorry but we could not find any listing matching your destination");
                    return;
                }
                 clear_form_geo_values();
            }
        });
    }
    $('#search-form').submit();
}

geocode_address = function (address, f) {
    var geocoder = new google.maps.Geocoder();
    geocoder.geocode({"address": address}, function (results, status) {
        if (status == google.maps.GeocoderStatus.OK && results.length > 0) {
            var result = results[0];
            f(result)
        }
    });
}

function set_form_geo_values(place) {
    if (place.geometry.viewport) {
        var ne = place.geometry.viewport.getNorthEast();
        var sw = place.geometry.viewport.getSouthWest();
        var zoom = getBoundsZoomLevel(place.geometry.viewport, {height: 600, width: 1000});

        $('#ne_lat').val(ne.lat());
        $('#ne_lng').val(ne.lng());
        $('#sw_lat').val(sw.lat());
        $('#sw_lng').val(sw.lng());
        $('#zoom').val(zoom);
    } else {
        $('#ne_lat').val('');
        $('#ne_lng').val('');
        $('#sw_lat').val('');
        $('#sw_lng').val('');
        $('#zoom').val(17);
    }

    $('#lat').val(place.geometry.location.lat());
    $('#lng').val(place.geometry.location.lng());
    var country_short = GOOGLE_MAP.get_address_components(place.address_components, 'country', 'short');
    $('#destination_form').val(place.formatted_address);
    $('#country_short').val(country_short);
}

function clear_form_geo_values() {
    $('#destination_form').val('');
    $('#ne_lat').val('');
    $('#ne_lng').val('');
    $('#sw_lat').val('');
    $('#sw_lng').val('');
    $('#zoom').val('');
}

function getBoundsZoomLevel(bounds, mapDim) {
    var WORLD_DIM = {height: 256, width: 256};
    var ZOOM_MAX = 21;

    function latRad(lat) {
        var sin = Math.sin(lat * Math.PI / 180);
        var radX2 = Math.log((1 + sin) / (1 - sin)) / 2;
        return Math.max(Math.min(radX2, Math.PI), -Math.PI) / 2;
    }

    function zoom(mapPx, worldPx, fraction) {
        return Math.floor(Math.log(mapPx / worldPx / fraction) / Math.LN2);
    }

    var ne = bounds.getNorthEast();
    var sw = bounds.getSouthWest();

    var latFraction = (latRad(ne.lat()) - latRad(sw.lat())) / Math.PI;

    var lngDiff = ne.lng() - sw.lng();
    var lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360;

    var latZoom = zoom(mapDim.height, WORLD_DIM.height, latFraction);
    var lngZoom = zoom(mapDim.width, WORLD_DIM.width, lngFraction);

    return Math.min(latZoom, lngZoom, ZOOM_MAX);
}
