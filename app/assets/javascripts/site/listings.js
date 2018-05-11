var timestamps = [];

function pushStater(title, url, state_nmb){
    // Creating a unique timestamp that will be associated with the state.
    var t = new Date().getTime();
    timestamps[t] = t;
    //Adding to history
    History.pushState({
      state: state_nmb,
      timestamp: t
    }, title, url);
}

function activate_bookmarks(){
    $('.bookmark:not(#listing-modal .bookmark)').popover({"title": "Add as favorite", "content": "Click on the heart to add the listing as a favorite!", "placement": "left", "trigger":"hover"});
    $('.bookmarked:not(#listing-modal .bookmarked)').popover({"title": "Remove as favorite", "content": "Click on the heart to remove the listing from your favorites.", "placement": "left", "trigger":"hover"});
    $('.bookmark').click(function(event) {
        $(this).removeClass("bookmark").addClass("bookmarked");
        if(!$(this).closest("#listing-modal").length) {
          $(this).popover('hide');
        }
    });
    $('.bookmarked').click(function(event) {
        if(!$(this).closest("#listing-modal").length) {
          $(this).popover('hide');
        }
    });
}

function add_pins(map, pins){
  var icons = { 'golfing':'/assets/golfing.png',
                'shopping': '/assets/shopping.png',
                'forest':'/assets/forest.png',
                'river':'/assets/river.png',
                'boating':'/assets/boating.png',
                'sea':'/assets/sea.png',
                'beach':'/assets/beach.png',
                'lake':'/assets/lake.png',
                'mountains':'/assets/mountains.png'
                }

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

  map.map.fitBounds(markerBounds);
}


function submit_form(){
  var address = $('input#address-field').val();
  var geocoder = new google.maps.Geocoder();
  var zoom = $('#zoom').val();

  if(address && !filter_name_check){
    geocoder.geocode({"address":address }, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK && results.length > 0) {
        var place = results[0];
        if(place.geometry.viewport){
          var ne_lat = place.geometry.viewport.getNorthEast().lat();
          var ne_lng = place.geometry.viewport.getNorthEast().lng();
          var sw_lat = place.geometry.viewport.getSouthWest().lat();
          var sw_lng = place.geometry.viewport.getSouthWest().lng();
          $('#ne_lat').val(ne_lat);
          $('#ne_lng').val(ne_lng);
          $('#sw_lat').val(sw_lat);
          $('#sw_lng').val(sw_lng);
        }else{
          $('#ne_lat').val('');
          $('#ne_lng').val('');
          $('#sw_lat').val('');
          $('#sw_lng').val('');
        }
        var lat = place.geometry.location.lat();
        var lng = place.geometry.location.lng();
        $('#lat').val(lat);
        $('#lng').val(lng);
        $('#search-flag').val(1);

        google_map.map.fitBounds(place.geometry.viewport);
        //Need to wait before we add the events when page loads.
        google_map.idle_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
          add_idle_events();
        });
        return

      } else if( $('#ne_lat').val().length > 0 ){
        //When executing a saved search with only coords we need to fix the map
        var ne = new google.maps.LatLng($('#ne_lat').val(), $('#ne_lng').val());
        var sw = new google.maps.LatLng($('#sw_lat').val(), $('#sw_lng').val());
        var bounds = new google.maps.LatLngBounds(sw, ne);
        var center = new google.maps.LatLng($('#lat').val(), $('#lng').val());
        google_map.map.fitBounds(bounds);
        //Need to wait before we add the events when page loads.
        google_map.idle_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
          add_idle_events();
        });
        return
      }
    });
    return
  } else if( $('#ne_lat').val().length > 0 ){
    if(zoom){
      google_map.idle_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
        //When executing a saved search with only coords we need to fix the map
        var ne = new google.maps.LatLng($('#ne_lat').val(), $('#ne_lng').val());
        var sw = new google.maps.LatLng($('#sw_lat').val(), $('#sw_lng').val());
        var bounds = new google.maps.LatLngBounds(sw, ne);
        var center = new google.maps.LatLng($('#lat').val(), $('#lng').val());
        google_map.map.setCenter(center);
        google_map.map.setZoom(parseInt(zoom));
        //Need to wait before we add the events when page loads.
        google_map.idle_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
          add_idle_events();
        });

      });
    }else{
      var ne = new google.maps.LatLng($('#ne_lat').val(), $('#ne_lng').val());
      var sw = new google.maps.LatLng($('#sw_lat').val(), $('#sw_lng').val());
      var bounds = new google.maps.LatLngBounds(sw, ne);
      google_map.map.fitBounds(bounds);
      //Need to wait before we add the events when page loads.
      google_map.idle_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
        add_idle_events();
      });
    }
    return
  }
    //Need to wait before we add the events when page loads.
    google_map.idle_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
      add_idle_events();
    });
  }

function set_update_map_listings(){
    var map_settings;
    map_settings = { map_canvas: "mini-map-canvas" };
    google_map.draggable_markers = false;
    google_map.create(map_settings);

}

function show_markers(fit_bounds, coords) {
  if(typeof coords=='undefined') return;

  var markerBounds = new google.maps.LatLngBounds();
  var position;
  var total_count = coords.length;

  if( total_count > 0 ){
    for( var x = 0; total_count > x; x=x+1){
      position = new google.maps.LatLng(coords[x][0], coords[x][1]);
      google_map.add_marker(position, {custom_icon:true});
      markerBounds.extend(position);
    }
    google_map.make_cluster(google_map.map);

    if(fit_bounds && total_count > 1) {
      google_map.map.fitBounds(markerBounds);
      return;
    }
    if(total_count == 1){// When only one listing set zoom to 13
      google_map.map.setCenter(position);
      google_map.map.setZoom(13);
    }
    return;
  }
  return;
}

function add_idle_events(){
    google_map.bounds_listener = google.maps.event.addListenerOnce(google_map.map, 'idle', function() {
        var bounds = google_map.map.getBounds();
        var ne_lat = bounds.getNorthEast().lat();
        var ne_lng = bounds.getNorthEast().lng();
        var sw_lat = bounds.getSouthWest().lat();
        var sw_lng = bounds.getSouthWest().lng();
        $('#ne_lat').val(ne_lat);
        $('#ne_lng').val(ne_lng);
        $('#sw_lat').val(sw_lat);
        $('#sw_lng').val(sw_lng);
        var center = google_map.map.getCenter();
        $('#lat').val(center.lat());
        $('#lng').val(center.lng());
        $('#zoom').val(google_map.map.getZoom());
        var map_search = true;
        do_filter_search(map_search);
    });
}


function activate_filters(){

    $('div#filter-list').on('change', '.select-filter', function(event) {
        do_filter_search();
    });


    // Activates filters for multiple selectors
    $("#search-result").on('click', 'ul.tag-cloud a', function(event) {
        event.preventDefault();
        $this = $(this);

        if($this.hasClass('selected')) {
            $this.removeClass('selected');
        } else {
            $this.addClass('selected');
        }

        do_filter_search(false);

    });

    var range_date = new Date();
    var range_start_year = range_date.getFullYear();
    var year_range = range_start_year.toString() + ':' + (parseInt(range_start_year) + 3).toString();


    $( "div#filter-list").on('focus','input#earliest-date', function(){
      $(this).datepicker({firstDay: 1, changeYear: true, yearRange: year_range, maxDate: "+2Y", dateFormat: 'yy-mm-dd', minDate: new Date(),
        onSelect: function(dateText, inst) {
            $('input#earliest-date-input').val(dateText);
            do_filter_search(false);
          }
        });
    });

    $( "div#filter-list").on('focus','input#latest-date', function(){
      $(this).datepicker({firstDay: 1, changeYear: true, yearRange: year_range, maxDate: "+2Y", dateFormat: 'yy-mm-dd', minDate: new Date(), beforeShow: function(input, inst) {
            var min_date = $("input#earliest-date").val();
            $( "input#latest-date" ).datepicker('option', 'minDate', min_date);
        },
        onSelect: function(dateText, inst) {
            $('input#latest-date-input').val(dateText);
            do_filter_search(false);
            }
        });
    });

    $("div#filter-list").on('click','button#clear-earliest-date',function(){
        $('input#earliest-date-input, input#earliest-date').val('');
        do_filter_search(false);
    });

    $("div#filter-list").on('click','button#clear-latest-date',function(){
        $('input#latest-date-input, input#latest-date').val('');
        do_filter_search(false);
    });


}

function activate_autocomplete(do_submit){
    $('#search-flag').val(0); // Better way to handle this?
    var google_map;
    google_map = GOOGLE_MAP;
    google_map.autocomplete('address-field');
    autocomplete = google_map.autocompleter;
    google.maps.event.addListener(autocomplete, 'place_changed', function() {
        var place = autocomplete.getPlace();
        if (typeof place.geometry === 'undefined'){
            return;
        }
        if(place.geometry.viewport){
            var ne_lat = place.geometry.viewport.getNorthEast().lat();
            var ne_lng = place.geometry.viewport.getNorthEast().lng();
            var sw_lat = place.geometry.viewport.getSouthWest().lat();
            var sw_lng = place.geometry.viewport.getSouthWest().lng();
            $('#ne_lat').val(ne_lat);
            $('#ne_lng').val(ne_lng);
            $('#sw_lat').val(sw_lat);
            $('#sw_lng').val(sw_lng);
        }else{
            $('#ne_lat').val('');
            $('#ne_lng').val('');
            $('#sw_lat').val('');
            $('#sw_lng').val('');
        }
        var lat = place.geometry.location.lat();
        var lng = place.geometry.location.lng();
        $('#lat').val(lat);
        $('#lng').val(lng);
        $('#search-flag').val(1);
        if(do_submit){
          $('form#listing-location, form#listing-destinations').submit();
        }
    });
}



function do_filter_search(map_search){
    form_data = build_filter_form(map_search);
    $('#filter-list').block({
      message: '',
      showOverlay: true,
    });
    $.get('/listings/search.js', form_data, function(data){
      $('#filter-list').unblock();
    });
}

function build_filter_form(map_search){

  var active_filters = $("ul.tag-cloud a.selected.tag");
  var exchange_types = $("ul.tag-cloud a.selected.exchange-type");
  var sleeping_capacity = $("#exchange-beds").val();
  var destination_is_checked = $("#exchange-destination").is(":checked");
  var destination_value = $("#exchange-destination").val();
  var environment = $("#exchange-environment").val();
  var filter_query = "";
  var href = "";
  var form_data = $('form#listing-destinations').serialize();
  active_filters.each(function(index){
      href = $(this).attr('href');
      // Handle hot list a little bit differently
      if(href == 'tag.hotlist'){
          form_data += "&hotlist=1";
          return true;
      }
      if(href != 'tag.any'){
          filter_query += '&filters[]=' + href;
      }
  });

  exchange_types.each(function(index){
      href = $(this).attr('href');
      filter_query += '&exchange_types[]=' + href;
  });

  form_data += filter_query;

  if(sleeping_capacity != '') {
      form_data += "&sleeping_capacity=" + sleeping_capacity;
  }

  if(destination_is_checked){
      form_data += "&destination=" + destination_value;
  }

  if(environment != 'environment.any'){
      form_data += "&environment=" + environment;
  }

  if(map_search){
      form_data += "&map_search=1";
  }
  return form_data;
}


function activate_pushstate(){
  History.Adapter.bind(window,'statechange',function(){

      var State = History.getState();
      if(ignore_statechange) {
        ignore_statechange = false;
        return;
      }
      //normal clicks
      if(State.data.timestamp in timestamps) {
          // Deleting the unique timestamp associated with the state
          delete timestamps[State.data.timestamp];
          return
      }

      //things that happen on back/forward clicks below

      update_map_on_back = true;
      //let's close the modal everytime we go back/forward IF state is shorter than 10
      //if not, we're still in a listing (state is equal to a long listingID then)
      if($('#listing-modal').is(":visible") && (!State.data.state || State.data.state.length < 10)) {
        force_hide = true;
        $('#listing-modal').modal('hide');
        return;
      }

      $.ajax({
        url: State.hash,
        type: "GET",
        processData: false,
        contentType: false,
        beforeSend: function(xhr, settings) {
          ignore_statechange = true;
          xhr.setRequestHeader('accept', '*/*;q=0.5, ' + settings.accepts.script);
        },
        complete: function(xhr, settings) {
          ignore_statechange = false;
        }
      });


    });
}


function activate_listing_modal(){
  $('#listing-modal').on('hidden', function (data) {
      //$(document).unbind('keypress');
        $('#result-cards li').unblock();
        $('body').removeClass('modal-open');
        if(force_hide == false) {
          ignore_statechange = true;
          History.back();
        }
        force_hide = false;
    });

    $('#listing-modal').on('shown', function () {
        $('body').addClass('modal-open');
        $("#listing-modal").scrollTop(0);
    });
}

function show_read_more() {
  if(!$("#read-more:visible").length) {
    var tmp_div = $("div#presentation-text").clone().hide().css("height","auto").css("overflow","visible").appendTo("#listings-infobox");
    new_height = tmp_div.height();
    tmp_div.remove();
    if(new_height > $("div#presentation-text").height()) {
        $("#read-more").fadeIn();
    }
  }
}
