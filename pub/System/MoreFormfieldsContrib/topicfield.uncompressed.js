jQuery(function($) {
  var defaults = {
    minimumInputLength: 0,
    url: foswiki.getPreference('SCRIPTURL')+'/'+foswiki.getPreference('SYSTEMWEB')+'/MoreFormfieldsAjaxHelper?section=select2::topic&skin=text&contenttype=application/json%3Bcharset%3Dutf-8',
    width: 'element',
    quietMillis:500
  };

  function formatTopicItem(item) {
    if (item.thumbnail) {
      return "<div class='image-item' style='background-image:url("+item.thumbnail + ")'>"+
         item.text + 
         "</div>";
    } else {
      return item.text;
    }
  }

  $(".foswikiTopicField:not(.foswikiTopicFieldInited)").livequery(function() {
    var $this = $(this), 
        opts = $.extend({}, defaults, $this.data()),
        requestOpts = $.extend({}, opts),
        val = $this.val();


    delete requestOpts.minimumInputLength;
    delete requestOpts.url;
    delete requestOpts.width;
    delete requestOpts.quietMillis;
    delete requestOpts.valueText;

    //console.log("opts=",opts);
    //console.log("requestOpts=",requestOpts);

    $this.addClass("foswikiTopicFieldInited");

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
        callback({id:val, text:opts.valueText});
      },
      DISinitSelection: function(elem, callback) {
        var params;
        if (val!=='') {
          params = 
            $.extend({}, {
              q: val,
              limit: 1,
              property: 'topic'
            }, requestOpts);
          $.ajax(opts.url, {
            data: params,
            dataType: 'json'
          }).done(function(data) { 
            callback(data.results[0]); 
          });
        }
      },
      formatResult: formatTopicItem,
      formatSelection: formatTopicItem
    });
  });

});
