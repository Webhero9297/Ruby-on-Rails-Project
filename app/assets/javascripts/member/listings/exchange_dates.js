function setup_exchange_dates(){
        var range_date = new Date();
        var range_start_year = range_date.getFullYear();
        var year_range = range_start_year.toString() + ':' + (parseInt(range_start_year) + 3).toString();
        var earliest_date, latest_date;
        
        $("#earliest-date").datepicker({
            firstDay: 1,
            changeYear: true,
            yearRange: year_range,
            maxDate: "+2Y",
            dateFormat: 'yy-mm-dd',
            minDate: new Date(),
            showOn: 'both',
            buttonText: '<i class="icon-calendar"></i>',
            onClose: function(args) {
                    var date = new Date(args);
                    var today = new Date();
                    today.setHours(0,0,0,0)
                    if(date <  today) {
                        alert('Earliest date can not be set to before todays date');
                        $("#earliest-date").val($.datepicker.formatDate('yy-mm-dd', today));
                    }
                    
                    if($("#latest-date").val() === "" && $("#latest-date").val() !== "") {
                        $("#latest-date").val($.datepicker.formatDate('yy-mm-dd', date));
                    }
                    
                    if($("#latest-date").val() !== "" && new Date($("#latest-date").val()) < date ) {
                        $("#latest-date").val($.datepicker.formatDate('yy-mm-dd', date));
                    }
                }
        });
            
        $("#latest-date").datepicker({
            firstDay: 1,
            changeYear: true,
            yearRange: year_range,
            maxDate: "+2Y",
            dateFormat: 'yy-mm-dd',
            showOn: 'both',
            buttonText: '<i class="icon-calendar"></i>',
            minDate: new Date(),
            beforeShow: function(input, inst) {
                    if($("#earliest-date").val() !== "") {
                        var min_date = $("#earliest-date").val();
                        $("#latest-date").datepicker('option', 'minDate', min_date);
                    }
                    $('button.ui-datepicker-trigger').addClass('btn');
                },
            onClose: function(args) {
                    var min_date = new Date($("#earliest-date").val());
                    var max_date = new Date($("#latest-date").val());
                    
                    if(min_date > max_date) {
                        alert('Latest date must be after earliest date');
                        $("#latest-date").val($.datepicker.formatDate('yy-mm-dd', min_date));
                    }
                    
                },
            onSelect: function(args) {
                if($("#earliest-date").val() === "") {
                    $("#earliest-date").val($.datepicker.formatDate('yy-mm-dd', range_date));
                }
            }
        });
        
        $('button.ui-datepicker-trigger').addClass('btn');
}