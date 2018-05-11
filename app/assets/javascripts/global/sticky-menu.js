$(document).ready(function(){
    transform_menu();

    $(window).scroll(function(){
        transform_menu();
    });
});

function transform_menu() {
    //if logged in
    if($("ul#menu:visible").length) {
        if(!$('nav[role="primary"].stuck').length) {
            $('nav[role="primary"]').clone().addClass('stuck').appendTo('body').hide();
        }
        if($(window).scrollTop() >= 108) {
            $('nav[role="primary"].stuck').show();
        } else {
            $('nav[role="primary"].stuck').hide();
        }
    }
    else if(!$("body#contact").length) {
        if(!$("header.stuck").length) {
            $('header').clone().addClass('stuck').appendTo('body').hide();
        }
        if($(window).scrollTop() > 85) {
            $('header.stuck').show();
        } else {
            $('header.stuck').hide();
        }
    }
}

function transform_listing_sidebar(sidebar_from_top, search_h1_height) {
    //let's not do this sticky for handheld devices
    if( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
        return;
    }
    if(window_height > $(".listing-sidebar").height()-search_h1_height) {
        if($(window).scrollTop() > (sidebar_from_top-55) && !form_is_sticky) {
            form_is_sticky = true;
            var modifier = -50;
            if($("body.logged-in").length) {
                modifier = 20;
            }
            var new_top = sidebar_from_top-search_h1_height-modifier;
            $("section.listing-sidebar").addClass("stuck").css("top",new_top);

        } else if(form_is_sticky && $(window).scrollTop() <= (sidebar_from_top-55)) {
            form_is_sticky = false;
            $("section.listing-sidebar").removeClass("stuck");
        }
    }
}