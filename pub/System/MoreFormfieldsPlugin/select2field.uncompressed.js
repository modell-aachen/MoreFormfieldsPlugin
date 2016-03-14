jQuery(function($) {
  var defaults = {
    minimumInputLength: 0,
    width: 'resolve',
    quietMillis:500,
    limit: '10'
  };

  $(".foswikiSelect2Field:not(.foswikiSelect2FieldInited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val();


    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.ajaxpassfields;
    delete requestOpts.width;
    delete requestOpts.quietMillis;
    delete requestOpts.multiple;
    delete requestOpts.allowClear;
    delete requestOpts.resultsfilter;

    // jqselect2 will fail if limit is too small.
    if(requestOpts.limit < 8) requestOpts.limit = 8;

    // See if there is a limit in the url
    if(opts.url) {
        var m = /[;&]limit=(\d*)/.exec(opts.url);
        if(m) requestOpts.limit = m[1];
    }

    if (opts.ajaxpassfields) {
      var form = $this.closest('form');
      var apf = opts.ajaxpassfields;
      opts.ajaxpassfields = {};
      $.each(apf.split(/\s*,\s*/), function(k, v) {
        v = v.split(/:/);
        if (v.length === 1) {
          v[1] = v[0];
        }
        if (v[1].match(/^=/)) {
          opts.ajaxpassfields[v[0]] = v[1].replace(/^=/, '');
        } else {
          opts.ajaxpassfields[v[0]] = form.find('[name="'+v[1]+'"]');
        }
      });
    }

    $this.addClass("foswikiSelect2FieldInited");


    var select2opts = {
      placeholder: opts.placeholder,
      minimumInputLength: opts.minimumInputLength,
      width: opts.width,
      multiple: opts.multiple,
      allowClear: !!(opts.allowClear)
    };
    if(opts.placeholder !== undefined && opts.placeholder !== false) {
        var id = (opts.placeholdervalue !== 'undefined' && opts.placeholdervalue !== false) ? opts.placeholdervalue : '';

        select2opts.placeholder = { id: id, text: opts.placeholder };

        $this.prepend($('<option></option>').val(id).text(opts.placeholder));
    }
    if (opts.url) {
      var makeParams = function() {
        if (!opts.ajaxpassfields) {
          return {};
        } else {
          var res = {};
          $.each(opts.ajaxpassfields, function(k, v) {
            if (typeof v === 'string') {
              res[k] = v;
            } else if (v.is('[type="checkbox"]')) {
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
        data: function(params) {
          $.extend(params, makeParams(), {
            q: params.term, // search term
          }, requestOpts);
          params.page = params.page || 0;
          params.start = params.limit * params.page;
          return params;
        },
        processResults: function(data, params) {
          params.page = params.page || 0;
          if(data.total) {
              data.more = ((params.page + 1) * params.limit) < data.total;
              data.pagination = { more: data.more };
          }
          if (opts.resultsfilter) {
            data = window[opts.resultsfilter](data);
          }
          return data;
        }
      };
      select2opts.formatSelection = function(object, container) {
        return object.textSelected || object.text;
      };
    }
    $this.select2(select2opts);
  });

});

