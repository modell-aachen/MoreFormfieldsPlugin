jQuery(function($) {
  var format = function(value) {
      if (!value.text.match(/^[A-Z]/)) {
         return '<i class="fa fa-' + value.text + '"></i> ' + value.text;
      } else {
         return value.text;
      }
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
