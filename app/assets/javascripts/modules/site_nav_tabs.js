function make_tabs() {
    set_active_based_on_hash();

    $(window).on('hashchange', function() {
        set_active_based_on_hash();
    });

    $('.nav-tab-link').click(function(event) {
        var self = $(this);
        window.location.hash = self.attr('href');
        event.preventDefault();
        $('.nav-tab-link').removeClass('active');
        self.addClass('active');
        $('.tab-pane').removeClass('active');
        $(self.attr('href')).addClass('active');
    });
}


function set_active_based_on_hash() {
    var hash = window.location.hash;

    if(hash != '') {
        $('.nav-tab-link, .tab-pane').removeClass('active');
        $('.nav-tabs a[href="' + hash + '"]').addClass('active');
        $(hash).addClass('active');
    }


}