jQuery(function($) {
  var defaults = {
    minimumInputLength: 0,
    width: 'resolve',
    quietMillis:500,
    limit: '10',
    delay: 300
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
      allowClear: !!(opts.allowClear),
      delay: opts.delay || 0
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
        delay: select2opts.delay,
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
    }
    select2opts.templateResult = function(d) {
      if (d instanceof jQuery) { return d; }
      if (d.loading) {
        return $('<div class="jqAjaxLoader" style="padding-left: 20px;">').text(foswiki.getMetaTag('l10n_modac_selecttopic_searching'));
      }
      var $e = $('<div class="topicselect_container"><div class="topicselect_label"></div><div class="topicselect_sublabel"></div></div>');
      $e.find('.topicselect_label').text(d.label || d.text);
      $e.find('.topicselect_sublabel').text(d.sublabel);
      $(d.labeltag).each(function(idx, item) {
        if(!item.text) return;
        $('<span></span>').text(item.text).addClass('select2_labeltag').addClass(item.class).prependTo($e.find('.topicselect_label'));
      });
      if(d.labelamend) {
        $e.find('.topicselect_label').append($('<span></span>').addClass('topicselect_amend').text(d.labelamend));
      }
      if(d.class) {
          $e.addClass(d.class);
      }
      return $e;
    };
    select2opts.templateSelection = function(d) {
      return $('<span class="select_label"></span>').text(d.label || d.text);
    };
    select2opts.formatSelection = function(object, container) {
      return object.textSelected || object.text;
    };
    if(typeof(opts.createTags) !== 'undefined' && !opts.createTags) {
        select2opts.createTag = function() {
            return null;
        };
    }
    $this.select2(select2opts);
  });

});

