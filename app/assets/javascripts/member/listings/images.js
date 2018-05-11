function enable_image_upload(element, use_runtimes) {

    var button = $(element);
    var runtimes = 'html5,flash,html4';

    if (use_runtimes === 'html4') {
        runtimes = 'html4';
    }

    var uploader = new plupload.Uploader({
        runtimes: runtimes,
        browse_button: button.attr('id'),
        container: $(element).data('placement'),
        max_file_size: '10mb',
        url: button.attr('data-url'),
        unique_names: true,
        multipart: true,
        multipart_params: {
            "authenticity_token": button.attr('data-token'),
            "category": button.attr('data-category'),
            "format": 'js'
        },
        flash_swf_url: "/assets/plupload/Moxie.swf"
    });


    uploader.bind('Error', function (up, error) {
        if (error.code == -600) {
            $('#image-size-alert').fadeIn();
        }
    });

    uploader.bind('FilesAdded', function (up, files) {
        up.refresh();
        button.siblings('img.upload-pointer:first').attr('src', '/assets/spinner.gif');
        button.after('<img src="/assets/spinner.gif" alt="" class="small-spinner"/>');
        setTimeout(function () {
            uploader.start();
        }, 500);
        $('#image-size-alert').fadeOut();
    });

    uploader.bind('FileUploaded', function (up, file, response) {
        var json_response = $.parseJSON(response.response);
        if (json_response.error) {
            if ($('#image-message').length > 0) {
                $('#image-message').remove();
            }

            button.parent().parent().prepend('<div id="image-message" class="alert alert-danger">' + json_response.image + '</div>');
            return;
        }

        if (button.attr('data-replace')) {
            console.log('#' + button.attr('data-insert'));
            console.log(json_response.html);
            $('#' + button.attr('data-insert')).replaceWith(json_response.html);
        } else {
            $('#' + button.attr('data-insert')).append(json_response.html);
        }

        $('#figure-blocks').children('.no-photos').remove();
        button.parent().siblings('#' + button.attr('data-category') + '-images').find('div.no-photos').remove();
        button.parent().siblings('div.alert').fadeOut('slow', function () {
            $(this).remove();
            up.refresh();
        });
    });

    uploader.bind('UploadComplete', function (up, files) {
        button.siblings('img.upload-pointer:first').attr('src', '/assets/upload-pointer.png');
        $('img.small-spinner').remove();
        up.refresh();
    });

    uploader.init();
}

function enable_blur() {
    $('.blur-submit').unbind('blur');
    $('.blur-submit').blur(function (event) {
        $(this).closest('form').submit();
    }).focus();
}

function enable_image_sorting(image_kind) {
    $("#figure-blocks").sortable({
        placeholder: "figure-block-placeholder",
        cursor: "move",
        items: "> article",
        update: function (event, ui) {
            var images_list, form_data, listing_id;
            images_list = $('#figure-blocks').sortable('toArray', {attribute: 'data-image'});
            form_data = {'images_list': images_list}
            listing_id = ui.item.data('listing');

            if (image_kind == 'listing') {
                $.post('/listings/' + listing_id + '/images/set-order', form_data, function (data) {
                }, 'html');
            }

            if (image_kind == 'profile') {
                $.post('/accounts/' + listing_id + '/profiles/photos/set-order', form_data, function (data) {
                }, 'html');
            }

        },
        start: function (event, ui) {
            ui.item.addClass('is-moving');
        },
        stop: function (event, ui) {
            ui.item.removeClass('is-moving');
        }
    });
}
