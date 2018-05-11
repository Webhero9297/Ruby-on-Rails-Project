// Future versions could take paramters to make it more flexible
function toggle_caption() {
    $('.photo-row').hover(function(event) {
        $(this).children('.photo-row-img-caption').show();
    }, function(event) {
        $(this).children('.photo-row-img-caption').hide();
    });
}