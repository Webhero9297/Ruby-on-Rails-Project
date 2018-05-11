function add_change_event_for_adults(){
	$('#profile_number_of_adults').on('change', function(){
		$(this).closest('form').submit();
	});
}