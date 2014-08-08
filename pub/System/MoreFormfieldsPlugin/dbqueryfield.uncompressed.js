jQuery(function($) {
  var defaults = {
    minimumInputLength: 1,
    width: 'element',
    quietMillis:500
  };

  $(".foswikiDbqueryField:not(.foswikiDbqueryFieldInited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val();

    var map = {};
    if (opts.mapFields) {
      $.each(opts.mapFields.split(/\s*,\s*/), function(_idx, f) {
        var fs = f.split(/=/, 2);
        if (fs.length == 1) {
          map[f] = f;
        } else {
          map[fs[1]] = fs[0];
        }
      });
    }

    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.width;
    delete requestOpts.quietMillis;
    delete requestOpts.valueText;
    delete requestOpts.labelfield;

    //console.log("opts=",opts);
    //console.log("requestOpts=",requestOpts);

    $this.addClass("foswikiDbqueryFieldInited");

    var getff = function(name) {
      return $this.closest('form').find('[name="'+name+'"]');
    };

    var formatDbqueryItem = function(item) {
      return item[opts.labelfield || 'text'];
    };

    var drawTable = function() {
      var t = $('<table class="foswikiDbqueryTable"></table>');
      $.each(map, function(k, v) {
        var th = $('<th></th>').text(v);
        var td = $('<td></td>').text(getff(k).val());
        var tr = $('<tr></tr>').append(th).append(td);
        t.append(tr);
      });
      $this.next('.foswikiDbQueryTable').remove();
      $this.after(t);
    };
    var synthesizeObject = function() {
      var result = {};
      $.each(map, function(k, v) {
        result[k] = getff(k).val();
      });
      return result;
    };
    var applyObject = function(o) {
      $.each(map, function(k, v) {
        getff(k).val(o[k]);
      });
      drawTable();
    }

    $this.select2({
      placeholder: opts.placeholder,
      minimumInputLength: opts.minimumInputLength,
      width: opts.width,
      ajax: {
        url: opts.url,
        dataType: 'json',
        data: function (term, page) {
          var params = 
            $.extend({}, {
              q: term, // search term
              limit: 10,
              page: page
            }, requestOpts);
          return params;
        },
        results: function (data, page) {
           data.more = (page * 10) < data.total;
           return data;
        }
      },
      initSelection: function(elem, callback) {
        var label = opts.valueText;
        if (opts.labelfield) label = getff(opts.labelfield).val();
        callback({id:val, label:opts.valueText});
      },
      formatResult: formatDbqueryItem,
      formatSelection: formatDbqueryItem
    }).on('change', function(e) {
      var d = $this.select2('data');
      applyObject(d);
    });
    setTimeout(function() {
      // Select2 freshly inited, set proper defaults
      drawTable();
      var o = synthesizeObject();
      o.id = $this.select2('val');
      $this.select2('data', o);
    });
  });

});
