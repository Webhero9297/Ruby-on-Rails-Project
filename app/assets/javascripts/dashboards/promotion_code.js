function promotion_code_date(){
    $("#end-date").datepicker({
        firstDay: 1,
        changeYear: true,
        maxDate: "+2Y",
        dateFormat: 'yy-mm-dd',
        showOn: 'both',
        buttonText: '<i class="icon-calendar"></i>'
    });
    
    $('button').addClass('btn');
}