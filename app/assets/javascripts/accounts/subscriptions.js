function expiration_date() {
    
    var expiration_date;

    $("#expiration-date").datepicker({
        firstDay: 1,
        changeYear: true,
        yearRange: '-0:+5',
        dateFormat: 'yy-mm-dd',
        showOn: 'both',
        buttonText: '<i class="icon-calendar"></i>'
    });
    $("#joined_at").datepicker({
        firstDay: 1,
        changeYear: true,
        yearRange: '1953:+0',
        dateFormat: 'yy-mm-dd',
        showOn: 'both',
        buttonText: '<i class="icon-calendar"></i>'
    });

    $('button').addClass('btn');

}
