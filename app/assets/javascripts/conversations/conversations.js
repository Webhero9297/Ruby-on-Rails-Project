function add_archive_conversation_events(){
	$('#btn-archive-conversation').on('click', function(event) {
		var conversation_threads, confirmed;
		event.preventDefault();

		conversation_threads = $('.conversation-thread:checked');
		if(conversation_threads.length > 0) {
			confirmed = window.confirm("Are you sure you want to archive these messages?");
			if(confirmed) {
                var query_string = get_query_string();
				$.post('/conversations/archive/messages.js?'+query_string, conversation_threads.serialize());
			}
		} else {
			alert('You must select one or more conversations');
		}
	});

}

function add_delete_conversation_events(){
	$('#btn-delete-conversation').on('click', function(event) {
		var conversation_threads, confirmed;
		event.preventDefault();

		conversation_threads = $('.conversation-thread:checked');
		if(conversation_threads.length > 0) {
			confirmed = window.confirm("Are you sure you want to delete these messages?");
			if(confirmed) {
				$.post('/conversations/delete/messages.js', conversation_threads.serialize());
			}
		} else {
			alert('You must select one or more conversations');
		}
	});

}


function set_active_filter(filter_class, filter_id) {
	var checked = false;
	var filter_option;

	$('.'+filter_class).each(function() {
		if($(this).prop('checked')) {
			checked = true;
		}
	});

	if(!checked) {
		filter_option = $('#'+filter_id);
		filter_option.prop('checked', true);
		filter_option.parent().addClass('active');
	}
}


function add_conversation_form_events(){
	$('.conversations-option:checked').parent().addClass('active');

	$('.send-form-data').on('click', function(event) {
        event.preventDefault();

		var that = $(this);
		that.siblings().removeClass('active');
		that.addClass('active');
        that.children('input').first().prop('checked', true);
		$('#conversation-form').submit();
	});
	
}

function get_query_string() {
    return window.location.search.substring(1);
}


function get_query_variable(variable) {
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i=0;i<vars.length;i++) {
        var pair = vars[i].split("=");
        if(pair[0] == variable){return pair[1];}
    }
    return false;
}
