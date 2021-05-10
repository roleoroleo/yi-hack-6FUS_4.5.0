var APP = APP || {};

APP.ptz = (function($) {

    function init() {
        registerEventHandler();
        initPage();
        updatePage();
    }

    function registerEventHandler() {
        $(document).on("click", '#img-au', function(e) {
            move('#img-au', 'up');
        });
        $(document).on("click", '#img-al', function(e) {
            move('#img-al', 'left');
        });
        $(document).on("click", '#img-ar', function(e) {
            move('#img-ar', 'right');
        });
        $(document).on("click", '#img-ad', function(e) {
            move('#img-ad', 'down');
        });
        $(document).on("click", '#button-goto', function(e) {
            gotoPreset('#button-goto', '#select-goto');
        });
    }

    function move(button, dir) {
        $(button).attr("disabled", true);
        $.ajax({
            type: "GET",
            url: 'cgi-bin/ptz.sh?dir=' + dir,
            dataType: "json",
            error: function(response) {
                console.log('error', response);
                $(button).attr("disabled", false);
            },
            success: function(data) {
                $(button).attr("disabled", false);
            }
        });
    }

    function gotoPreset(button, select) {
        $(button).attr("disabled", true);
        $.ajax({
            type: "GET",
            url: 'cgi-bin/preset.sh?num=' + $(select + " option:selected").text(),
            dataType: "json",
            error: function(response) {
                console.log('error', response);
                $(button).attr("disabled", false);
            },
            success: function(data) {
                $(button).attr("disabled", false);
            }
        });
    }

    function initPage() {
        interval = 1000;

        (function p() {
            jQuery.get('cgi-bin/snapshot.sh?res=low&base64=yes', function(data) {
                image = document.getElementById('imgSnap');
                image.src = 'data:image/png;base64,' + data;
            })
            setTimeout(p, interval);
        })();
    }

    function updatePage() {
        $.ajax({
            type: "GET",
            url: 'cgi-bin/status.json',
            dataType: "json",
            success: function(data) {
                for (let key in data) {
                    if (key == "model_suffix") {
                        if (data[key] == "h201c" || data[key] == "h305r" || data[key] == "y30") {
                            $('#ptz_description').show();
                            $('#ptz_available').hide();
                            $('#ptz_main').show();
                        } else {
                            $('#ptz_description').hide();
                            $('#ptz_available').show();
                            $('#ptz_main').hide();
                        }
                    }
                }
            },
            error: function(response) {
                console.log('error', response);
            }
        });
    }

    return {
        init: init
    };

})(jQuery);