jQuery(function($) {
  var addressRegex = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
  var macRegex = /^([a-f\d]+)[:\.-]([a-f\d]+)[:\.-]([a-f\d]+)[:\.-]([a-f\d]+)[:\.-]([a-f\d]+)[:\.-]([a-f\d]+)$/i;
  var errorMsgIp = 'Please provide a valid IP address';
  var errorMsgNetmask = 'Please provide a valid netmask';
  var errorMsgMac = 'Please provide a valid mac address';
  var $errorElem;

  function error(text, elem) {
    if ($errorElem) {
      $errorElem.remove();
    }
    $errorElem = $('<label class="error" generated="true">'+text+'</label>').insertAfter(elem);
  }

  function testAddress(elem) {
    var isRequired = elem.is(".required");
    var isIpAddr = elem.is(".foswikiIpAddress");
    var isNetmask = elem.is(".foswikiNetmask");
    var isMacAddr = elem.is(".foswikiMacAddress");
    var val = elem.val();
    var result = []
    var errorMsg = isNetmask?errorMsgNetmask:(isIpAddr?errorMsgIp:errorMsgMac);
    var radix = isMacAddr?16:10;
    var nrSegments = isMacAddr?6:4;
    var match = isMacAddr?macRegex.exec(val):addressRegex.exec(val);
    var separator = isMacAddr?':':'.';

    if (!isRequired && val == '') {
      $.log("empty value ... not required ... abording test");
      return true;
    }

    if (match === null) {
      $.log("formfield doesn't match");
      error(errorMsg, elem);
      return false;
    }

    var max;
    var min = 0;
    if (isIpAddr) {
      max = 254;
    } else {
      max = 255;
    }
    for (var i = 1; i <= nrSegments; i++) {
      var segment = parseInt(match[i], radix);
      if (isNaN(segment)) {
        $.log("can't parse segment"+match[i]);
        error(errorMsg, elem);
        return false;
      }
      if (isIpAddr) {
        if (i == 1 || i == nrSegments) {
          min = 1; // first and last segment must be > 0
        } else {
          min = 0;
        }
      }
      if (segment > max) {
        error(errorMsg, elem);
        $.log("segment too high");
        return false;
      } 
      if (segment < min) {
        $.log("segment too low");
        error(errorMsg, elem);
        return false;
      } 
      result.push(addZeros(segment.toString(radix), isMacAddr?2:3).toUpperCase());
    }
    elem.val(result.join(separator));

    if ($errorElem) {
      $errorElem.remove();
    }
    return true;
  }

  function addZeros(str, maxLen) {
    var len = str.length;
    if (len < 1) str = '000';
    if (len == 1) str = '00'+str;
    if (len == 2) str = '0'+str;
    return str.substr(3-maxLen, maxLen);
  }

  // dom ready
  $(function() {
    $(".foswikiIpAddress, .foswikiNetmask, .foswikiMacAddress").livequery(function() {
      var $input = $(this);
      var $form = $input.parents("form:first");

      // form validation
      $input.blur(function() {
        testAddress($input);
      });

      // validate formfields before submit
      $form.submit(function() {
        if(!testAddress($input)) {
          // get current action
          var action = $form.find("input[name*=action_][value!='']");
          if(action.length) {
            action = action.attr('name').substr(7,10);
          } else {
            action = 'save';
          }
          if (action == "save" || action == "checkpoint") {
            $.log("checking input field "+$input.attr('class'));
            alert("Validation Error: please check '"+$input.attr('name')+"'");
            $.log("blocking submit");
            return false; 
          } 
        }
      });
    });
  });
});
