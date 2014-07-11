jQuery(function($) {
  
  function format(value) {
      if (typeof(value.id) === 'undefined') {
         return value.text;
      }
      if (value.id.match(/^fa\-/)) {
        return '<i class="fa ' + value.id + '"></i> ' + value.text;
      }
      var url = $(value.element).data("url");
      if (url) {
        return '<img src="'+url+'" class="foswikiIcon" /> ' + value.text;
      }
      return value.text;
  };

  $(".foswikiFontAwesomeIconPicker").select2({
     formatSelection: format,
     formatResult: format,
     escapeMarkup: function(m) { return m; },
     width: 'element',
     allowClear: true,
     placeholder: 'None'
  });
});
