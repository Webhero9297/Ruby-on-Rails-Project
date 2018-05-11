function mark_selected_favorites() {
    $('.favorite-card-select').click(function(event) {
        var card_id = $(this).val();
        $('#favorite-card-'+card_id).toggleClass('favorite-card-selected');
    });
}