jQuery(function($) {
  var defaults = {
    minimumInputLength: 0,
    width: 'resolve',
    quietMillis:500
  };

  $(".foswikiSelect2Field:not(.foswikiSelect2FieldInited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val();


    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.initUrl;
    delete requestOpts.width;
    delete requestOpts.quietMillis;

    $this.addClass("foswikiSelect2FieldInited");


    var select2opts = {
      placeholder: opts.placeholder,
      minimumInputLength: opts.minimumInputLength,
      width: opts.width
    };
    if (opts.url) {
      select2opts.ajax = {
        url: opts.url,
        dataType: 'json',
        data: function(term, page) {
          var params =
            $.extend({}, {
              q: term, // search term
              limit: 10,
              page: page
            }, requestOpts);
          return params;
        },
        initSelection: function(elem, callback) {
          var $e = $(elem);
          if (opts.initUrl) {
            $.ajax(opts.initUrl +';id='+ $e.val()).
            then(function(data, textStatus, xhr) {
              callback(data);
            }).
            fail(function() {
              callback({id: $e.val(), text: $e.val()});
            });
          } else {
            callback({id: $e.val(), text: $e.val()});
          }
        },
        results: function(data, page) {
          data.more = (page * (requestOpts.limit || 10)) < data.total;
          return data;
        }
      };
    }
    $this.select2(select2opts);
  });

});

