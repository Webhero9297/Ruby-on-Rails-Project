function setup_autocomplete_for_categories(){
    categories = $('.typeahead').first().data('source');
    $('.typeahead').autocomplete({
        source: categories
    });
}

function edit_translation(event){
  event.preventDefault();
  var msgid = $(this).data('msgid');
  $.get('/agent/translations/edit-on-page/'+msgid, function(data){
  });
}