$(document).ready(function(){

    if($("a#action-button span").height() > 70) {
        $("a#action-button").addClass("smaller");
    }
    if($("html").height() < $(window).height()) {
        $(".row").css("min-height",($(window).height()-250)+"px");
    }

    //make listings equal heigh
    var heighest_box = 0;
    $("ul.box-listings:not(#unexpected-listings ul.box-listings) li div").each(function(){
        if($(this).height() > heighest_box) {
            heighest_box = $(this).height();
        }
    });
    $("ul.box-listings:not(#unexpected-listings ul.box-listings) li div").css("height",heighest_box);

    //enable search on frontpage
    $('form#listing-location').submit(function(event) {
        if( $('#search-flag').val() == 1){
            return true;
        }
        return false;
    });

    if($("body#start").length) {
        var do_submit = true;
        activate_autocomplete(do_submit);

        window.setTimeout(function(){
            $('input#address-field').focus();
        },100);
    }

    //make bigpic image-tag background if exists
    if($("#bigpic-top-background img").length) {
        var background_src = $("#bigpic-top-background img").attr("src");
        $("#bigpic-top-background").css("background-image","url('"+background_src+"')");
        $("#bigpic-top-background img").remove();
    }

})
