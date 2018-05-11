function open_social_tab() {
    $('div#facebook-feed-wrapper').animate({
        'margin-right': 0
    });
}

function close_social_tab() {
    $('div#facebook-feed-wrapper').animate({
        'margin-right': -300
    }, 'fast');
}

function edit_translation(event){
  event.preventDefault();
  var msgid = $(this).data('msgid');
  $.get('/agent/translations/edit-on-page/'+msgid, function() {});
}


function edit_public_translation(event){
    event.preventDefault();
    var msgid = $(this).data('msgid');
    $.get('/agent/translations/edit-on-page/'+msgid+'/public', function() {});
}