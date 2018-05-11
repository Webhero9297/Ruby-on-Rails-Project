function ListingScripts(translations) {
  this.translations = translations;
}

ListingScripts.prototype.init = function(){
  var scope = this;
  
  if ($('.nav-tab-link-map').length > 0) {
    var location_map = initialize_location_map();
    var pins = $('span.pin');

    // Add any saved pins to the map
    if (pins.length > 0) {
      add_location_pins_to_map(location_map.map, pins, location_map.property_position);
    }
  }

  $('.nav-tab-link').click(function (event) {
    var self = $(this);
    event.preventDefault();
    $('.nav-tab-link').removeClass('active');
    self.addClass('active');
    $('.tab-pane').removeClass('active');
    $(self.attr('href')).addClass('active');

    if (self.hasClass('nav-tab-link-map')) {
      location_map.map.reset_map(location_map.property_position);
    }
  });

  if ($('.listing-presentation-text').height() < 230) {
    $('.listing-presentation-btn').remove();
  }

  $('.listing-presentation-btn').click(function (event) {
    event.preventDefault();
    $('.listing-presentation').addClass('show-text');
    $(this).remove();
  });

  $('.print-btn').click(function (event) {
    event.preventDefault();
    window.print();
  });

  $('#send-msg-btn').on('click', function (event) {
    event.preventDefault();
    var listing_id = $(this).data('listing-id');
    $('#contact-messages-' + listing_id).slideDown('fast');
  });

  $('.close-contact-message-btn').click(function (event) {
    event.preventDefault();
    var listing_id = $(this).data('listing-id');
    $('#contact-messages-' + listing_id).slideUp('fast');
  });

  $('.interaction-history-link').click(function (event) {
    $("#interaction-history-link").click();
  });

  $('body').on('submit','.ajax-file #file-attachment', function( event ) {
    if( $('#file-attachment')[0].files[0].size > 10485760) {
      alert(scope.translations["file-too-large"]);
      event.preventDefault();
      return false;
    }
  });

  (function ($) {
    var gallery = $('.mt-slider');
    var gallery_width = gallery.outerWidth();
    var slider_view = $('.mt-slider-view');
    var slider_width = slider_view.innerWidth();
    var slides = $('.mt-slider-slide');
    var slides_length = slides.length;

    var thumbs = $('.mt-slider-thumb');
    var thumbs_width = thumbs.first().outerWidth();
    var total_thumbs = thumbs.length;

    if(total_thumbs < 2){
      $('.mt-slider-btn-left, .mt-slider-btn-right').remove();
    }

    var current_slide = 0;
    var number_of_visible_thumbs = Math.floor(gallery_width / thumbs_width);
    var range_top = Math.ceil(total_thumbs - number_of_visible_thumbs / 2);

    $('.mt-slider-content').width(slides_length * slider_width);
    slides.width(slider_width);

    $(thumbs[current_slide]).addClass('active-thumb');
    $('.mt-slider-thumbs-content').width(thumbs_width * total_thumbs);


    thumbs.click(function () {
      setActiveImage($(this).data('sliderThumb'));
    });

    thumbs.each(function (index, thumb) {
      thumb.setAttribute("data-slider-thumb", index);
    });


    function setActiveImage(image_index) {
      current_slide = image_index;
      set_active_thumb();
      var content = $('.mt-slider-content');
      var thumbs = $('.mt-slider-thumbs-content');

      content.animate({
        marginLeft: -Math.abs(image_index * slider_width)
      }, 300);
      slide_thumbs(thumbs);
    }


    $("[data-mt-slider='button-left']").click(function (event) {
      event.preventDefault();
      var content = $('.mt-slider-content');
      var thumbs = $('.mt-slider-thumbs-content');

      if (current_slide <= 0) {
        current_slide = 0;
        set_active_thumb();
        return;
      }

      decrement_slide_number();
      set_active_thumb();
      content.animate({
        marginLeft: "+=" + slider_width.toString()
      }, 300);

      slide_thumbs(thumbs);
    });

    $("[data-mt-slider='button-right']").click(function (event) {
      event.preventDefault();
      var content = $('.mt-slider-content');
      var thumbs = $('.mt-slider-thumbs-content');

      if (current_slide >= (slides_length - 1)) {
        current_slide = (slides_length - 1);
        set_active_thumb();
        return;
      }

      increment_slide_number();
      set_active_thumb();

      content.animate({
        marginLeft: "-=" + slider_width.toString()
      }, 300);

      slide_thumbs(thumbs);
    });


    function increment_slide_number() {
      current_slide = current_slide + 1;
    }

    function decrement_slide_number() {
      current_slide = current_slide - 1;
    }

    function set_active_thumb() {
      thumbs.removeClass('active-thumb');
      $(thumbs[current_slide]).addClass('active-thumb');
    }

    function slide_thumbs(thumbs){
      var slide_to = 0;
      if (current_slide < range_top && current_slide > 2) {
        thumbs.animate({
          marginLeft: -Math.abs((current_slide - 2) * thumbs_width)
        }, 300);
      } else {
        if (current_slide <= 2) {
          slide_to = 2;
        } else if (current_slide >= range_top) {
          slide_to = range_top - 1;
        }
        thumbs.animate({
          marginLeft: -Math.abs((slide_to - 2) * thumbs_width)
        }, 300);
      }
    }

  })(jQuery);

  return true;
}
