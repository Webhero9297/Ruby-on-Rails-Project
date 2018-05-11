var current_profile_image = $('#figure-block-<%= params[:id] %>');
if(current_profile_image.siblings('.figure-block').length == 0) {
    current_profile_image.replaceWith("<%= escape_javascript(render( partial: '/accounts/profile_images/no_images')) %>");
}
current_profile_image.css({'background-color' : '#ffa', 'border-color' : '#ffa'}).delay(300).fadeOut(400, function(event) {
  $(this).remove();
});