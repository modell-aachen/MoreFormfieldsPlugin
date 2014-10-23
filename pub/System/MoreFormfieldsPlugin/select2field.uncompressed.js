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
    delete requestOpts.initurl;
    delete requestOpts.ajaxpassfields;
    delete requestOpts.width;
    delete requestOpts.quietMillis;

    if (opts.ajaxpassfields) {
      var form = $this.closest('form');
      var apf = opts.ajaxpassfields;
      opts.ajaxpassfields = {};
      $.each(apf.split(/\s*,\s*/), function(k, v) {
        v = v.split(/:/);
        if (v.length === 1) {
          v[1] = v[0];
        }
        opts.ajaxpassfields[v[0]] = form.find('[name="'+v[1]+'"]');
      });
    }

    $this.addClass("foswikiSelect2FieldInited");


    var select2opts = {
      placeholder: opts.placeholder,
      minimumInputLength: opts.minimumInputLength,
      width: opts.width
    };
    if (opts.url) {
      var makeParams = function() {
        if (!opts.ajaxpassfields) {
          return {};
        } else {
          var res = {};
          $.each(opts.ajaxpassfields, function(k, v) {
            if (v.is('[type="checkbox"]')) {
              res[k] = v.filter(':checked').map(function() {
                return $(this).val();
              }).get().join(',');
            } else {
              res[k] = v.val();
            }
          });
          return res;
        }
      };
      select2opts.ajax = {
        url: opts.url,
        dataType: 'json',
        data: function(term, page) {
          var params =
            $.extend(makeParams(), {
              q: term, // search term
              limit: 10,
              page: page
            }, requestOpts);
          return params;
        },
        results: function(data, page) {
          data.more = (page * (requestOpts.limit || 10)) < data.total;
          return data;
        }
      };
      select2opts.initSelection = function(elem, callback) {
        var $e = $(elem);
        if (opts.initurl) {
          $.ajax(opts.initurl +';id='+ $e.val(), {
            dataType: 'json'
          }).
          then(function(data, textStatus, xhr) {
            callback(data);
          }).
          fail(function() {
            callback({id: $e.val(), text: $e.val()});
          });
        } else {
          callback({id: $e.val(), text: $e.val()});
        }
      };
    }
    $this.select2(select2opts);
  });

});

