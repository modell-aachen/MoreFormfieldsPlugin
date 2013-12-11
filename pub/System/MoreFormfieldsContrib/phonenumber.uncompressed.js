(function($) {
  $.validator.addMethod('phone', function(value) {
    return (
      value.match(/^(((\+)?[1-9]{1,2})?([-\s\.])?(\(\d\)[-\s\.]?)?((\(\d{1,4}\))|\d{1,4})(([-\s\.])?[0-9]{1,12}){1,2}(\s*(ext|x)\s*\.?:?\s*([0-9]+))?)?$/)
    );
  }, 'Please enter a valid phone number (Intl format accepted + ext: or x:)');

  $("input.foswikiPhoneNumber").livequery(function() {
    $(this).rules("add", {
      phone: true
    });
  });
  
})(jQuery);
