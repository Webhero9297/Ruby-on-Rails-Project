function setup_birthdate(){

  $("#birthdate").datepicker({
      firstDay: 1,
      changeYear: true,
      yearRange: "1900:" + (new Date().getFullYear()).toString(),
      dateFormat: 'yy-mm-dd',
      showOn: 'both',
      buttonText: '<i class="icon-calendar"></i>'
  });
  $('button.ui-datepicker-trigger').addClass('btn');

}
