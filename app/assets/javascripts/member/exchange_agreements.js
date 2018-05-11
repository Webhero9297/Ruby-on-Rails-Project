function init_exchange_form() {
    $('div.exchange-terms').on('click', 'button.term-button', function(event) {
        var element = $(this);
        var prefix = element.attr('rel');
        var form = $('form#'+prefix);
        var action = form.find('input[name=choice]');
        if( element.hasClass('accept')){
          action.val('accept');
          form.submit();
          return
        }
        action.val('decline');
        $("#modal-"+prefix).modal('show');
    });

    $('div.exchange-terms').on('click', 'button[data-dismiss="modal"]', function(event) {
      var prefix = $(this).attr('rel');
      $('button[data-cancel="'+prefix+'"]').removeClass('active');
      $('[data-message="'+prefix+'"]').remove();
    })
}