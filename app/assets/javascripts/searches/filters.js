function init_date_pickers(){
  $('.travel-dates-filter').keydown(function(event){event.preventDefault(); return false;});

  var range_date = new Date();
  var range_start_year = range_date.getFullYear();
  var year_range = range_start_year.toString() + ':' + (parseInt(range_start_year) + 3).toString();

  $( "#date-filters").on('focus','input#earliest-date', function(){
    $(this).datepicker({
      firstDay: 1,
      changeYear: true,
      yearRange: year_range,
      maxDate: "+2Y",
      dateFormat: 'yy-mm-dd',
      minDate: new Date(),
      onSelect: function(dateText, inst) {
        var date = new Date(dateText);
        var future_date = new Date(dateText);
        future_date.setDate(date.getDate() + 7);
        $('input#earliest-date-input').val(dateText);

        if($("#latest-date").val() === "") {
          $("#latest-date").val($.datepicker.formatDate('yy-mm-dd', future_date));
        }

        if($("#latest-date").val() !== "" && new Date($("#latest-date").val()) < date ) {
          $("#latest-date").val($.datepicker.formatDate('yy-mm-dd', future_date));
        }
      }
    });
  });

  $( "#date-filters").on('focus','input#latest-date', function(){
    $(this).datepicker({
      firstDay: 1,
      changeYear: true,
      yearRange: year_range,
      maxDate: "+2Y",
      dateFormat: 'yy-mm-dd',
      minDate: new Date(),
      beforeShow: function(input, inst) {
        var min_date = $("input#earliest-date").val();
        $( "input#latest-date" ).datepicker('option', 'minDate', min_date);
      },
      onSelect: function(dateText, inst) {
        $('input#latest-date-input').val(dateText);
      }
    });
  });

  $("#date-filters").on('click','a#clear-dates',function(){
    $('input#latest-date, input#earliest-date').val('');
  });
}


function init_filter_counts(){
  // Clear success class
  var selector = "#house-filters-count, #environment-filters-count, #exchange-filters-count, #family-filters-count, #surrounding-filters-count, #preference-filters-count";
  $(selector).removeClass('badge-success');
  $(selector).addClass('hidden');

  //House
  var count = $("[name='capacity']:checked").length;
  count += $("[name='house_filters[]']:checked").length;
  count += $("[name='house_type_filters[]']:checked").length;
  $("span#house-filters-count").html(count);
  if(count > 0){
    $("span#house-filters-count").addClass('badge-success').removeClass('hidden');
  }

  //Environment
  count = $("[name='environment_filters[]']:checked").length;
  $("span#environment-filters-count").html(count);
  if(count > 0){
    $("span#environment-filters-count").addClass('badge-success').removeClass('hidden');
  }

  //Exchange
  count = $("[name='exchange_type_filters[]']:checked").length;
  count += $(".travel-dates-filter[value]").length;
  $("span#exchange-filters-count").html(count);
  if(count > 0){
    $("span#exchange-filters-count").addClass('badge-success').removeClass('hidden');
  }

  //Family
  count = $("[name='adults']:checked").length;
  count += $("[name='children']:checked").length;
  count += $("[name='pets']:checked").length;
  count += $("[name='ee']:checked").length;

  $("span#family-filters-count").html(count);
  if(count > 0){
    $("span#family-filters-count").addClass('badge-success').removeClass('hidden');
  }

  //Surroundings
  count = $("[name='surroundings[]']:checked").length;
  $("span#surrounding-filters-count").html(count);
  if(count > 0){
    $("span#surrounding-filters-count").addClass('badge-success').removeClass('hidden');
  }

  //Preferences
  count = $(".preference-filter:checked").length;
  $("span#preference-filters-count").html(count);
  if(count > 0){
    $("span#preference-filters-count").addClass('badge-success').removeClass('hidden');
  }
}

function init_headline_popover(){
  $('.photo-container').hover(
    function() {
      $(this).children('.headline').slideDown('fast');
    }, function() {
      $(this).children('.headline').slideUp('fast');
    }
  );
}
