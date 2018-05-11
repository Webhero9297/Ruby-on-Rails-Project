function set_up_line_chart(container, views){
    var categories = []
    var data = []
    var i = 0;
    var l = views.length;
    for(i; i<l; i=i+1){
        categories.push(views[i]['count_date']);
        data.push(views[i]['count']);
    }
    
    var options = {
        chart: {
            renderTo: container,
            defaultSeriesType: 'line'
        },
        title: {
            text: 'Listing visits per day',
        },
        xAxis: {
            title: {
                text: 'Day'
            },
            categories: categories
        },
        yAxis: {
            title: {
                text: 'Number of visits'
            },
            allowDecimals: false
        },
        series: [
        {
            name: 'Number of visits',
            data: data
        }],
        credits: {
          enabled: false
        }
    };
    var chart = new Highcharts.Chart(options);
}


function set_up_pie_chart(container, countries){
    
        var data = [];
        var i = 0;
        var l = countries.length;
        for(i; i<l; i=i+1){
            data.push({name:countries[i]['country_short'], long_name:countries[i]['country_long'],y:countries[i]['count']});
        }
        
        var options = {
            chart: {
            renderTo: container,
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false
        },
        title: {
            text: 'Visitor countries'
        },
        tooltip: {
            formatter: function() {
                return '<b>'+ this.point.long_name +'</b>: '+ Highcharts.numberFormat(this.percentage, 0) +' %';
            }
        },
        credits: {
          enabled: false
        },
        plotOptions: {
            pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: true,
                    color: '#000000',
                    connectorColor: '#000000',
                    formatter: function() {
                        return '<b>'+ this.point.name +'</b>: '+ Highcharts.numberFormat(this.percentage, 0) +' %';
                    }
                }
            }
        },
        series: [{
            type: 'pie',
            name: 'Visitor countries',
            data: data
        }]
        };
        
        var chart = new Highcharts.Chart(options);
}


function load_chart_data(element) {
    var listing_id = $(element).data('listing');
    var pie_container_id = 'piechart-'+listing_id;
    $.get('/listing/stats/'+listing_id+'.json', function(stats) {
        var views = stats['views'];
        var countries = stats['countries'];
        set_up_line_chart(element.id, views);
        set_up_pie_chart(pie_container_id, countries)
    });
}