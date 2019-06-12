FOSWIKI_ROOT?=~/foswiki/trunk/core
TARGET= \
  moreformfields.css \
  networkaddress.js \
  userfield.js \
  topicfield.js \
  phonenumber.js \
  clockpicker.js \
  clockpicker.init.js \
  clockpicker.css

-include $(FOSWIKI_ROOT)/pub/System/JQueryPlugin/Makefile.include

clockpicker.uncompressed.js: clockpicker/dist/jquery-clockpicker.js
	@echo "creating $@"; cp $< $@

clockpicker.uncompressed.css: clockpicker/dist/jquery-clockpicker.css
	@echo "creating $@"; cp $< $@
