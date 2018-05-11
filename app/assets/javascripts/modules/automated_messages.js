function automated_messages_kind(){
    $("#message-kind").on('change', function() {
        $.ajax({
            type: "POST",
            url: '<%= automated_messages_meta_data_path %>',
            data: 'selected=' + this.value,
            dataType: 'script'
        });
    });
}

function automated_messages_preview_actions() {
    $("#btn-preview").on('click', function(event) {
        event.preventDefault();
        var data = $('#message-kind, #message-subject, #message-body').serialize();
        $.ajax({
            type: "POST",
            url: '/automated/messages/preview',
            data: data,
            dataType: 'script'
        });
    });

    $('#automated-message-form').on('click', '#btn-close-preview', function(event) {
        event.preventDefault();
        $('#message-preview').remove();
        $('#message-section').show();
    });
}

function automated_messages_select_deselect() {
    $('#btn-select-all').on('click', function(event) {
        event.preventDefault();
        $('.country-check-box').prop('checked', true);
    });

    $('#btn-deselect-all').on('click', function(event) {
        event.preventDefault();
        $('.country-check-box').prop('checked', false);
    });
}