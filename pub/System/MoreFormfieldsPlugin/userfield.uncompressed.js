jQuery(function($) {
  var defaults = {
    minimumInputLength: 0,
    url: foswiki.getPreference('SCRIPTURL')+'/view/'+foswiki.getPreference('SYSTEMWEB')+'/MoreFormfieldsAjaxHelper?section=select2::user&skin=text&contenttype=application/json%3Bcharset%3Dutf-8',
    initUrl: foswiki.getPreference('SCRIPTURL')+'/view/'+foswiki.getPreference('SYSTEMWEB')+'/MoreFormfieldsAjaxHelper?section=select2::user::init&skin=text&contenttype=application/json%3Bcharset%3Dutf-8',
    width: 'element',
    quietMillis:500
  };

  function formatUserItem(item) {
     return "<div class='image-item' style='background-image:" +
        (item.thumbnail?"url("+item.thumbnail + ")": "none") + "'>"+
        item.text + 
        "</div>";
  }

  $(".foswikiUserField:not(.foswikiUserFieldInited)").livequery(function() {
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

    $this.addClass("foswikiUserFieldInited");

    $this.select2({
      placeholder: opts.placeholder,
      minimumInputLength: opts.minimumInputLength,
      width: opts.width,
      multiple: opts.multiple || false,
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
        var params;
        if (val!=='') {
          params = 
            $.extend({}, {
              q: val,
              limit: 1,
              property: 'topic'
            }, requestOpts);
          $.ajax(opts.initUrl, {
            data: params,
            dataType: 'json'
          }).done(function(data) { 
            if (opts.multiple) {
              callback(data.results);
            } else {
              callback(data.results[0]);
            }
          });
        }
      },
      formatResult: formatUserItem,
      formatSelection: formatUserItem
    });
  });

});

