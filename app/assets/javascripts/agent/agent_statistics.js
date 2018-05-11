function set_line_chart(container, views, caption){
    var categories = []
    var data = []
    var i = 0;
    var l = views.length;
    for(i; i<l; i=i+1){
        categories.push(views[i]['year_month']);
        data.push(views[i]['count']);
    }
    
    var options = {
        chart: {
            renderTo: container,
            defaultSeriesType: 'line'
        },
        title: {
            text: caption,
        },
        xAxis: {
            title: {
                text: 'Month'
            },
            categories: categories
        },
        yAxis: {
            allowDecimals: false,
            title: {
                text: caption
            }
        },
        series: [
        {
            name: caption,
            data: data
        }]
    };
    var chart = new Highcharts.Chart(options);
}



function load_agent_chart_data() {
    $.get('/agent/stats/', function(stats) {
        set_line_chart('stats-activated', stats['activated'], 'Activations last 3 months');
        set_line_chart('stats-expirations', stats['expires'], 'Expirations next 3 months');
    });
}