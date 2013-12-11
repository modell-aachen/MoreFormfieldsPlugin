# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsContrib is Copyright (C) 2010-2013 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Form::User;

use strict;
use warnings;

use Foswiki::Form::Topic ();
our @ISA = ('Foswiki::Form::Topic');

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);

    $this->{_formfieldClass} = 'foswikiUserField';

    return $this;
}

sub addJavascript {
  my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::USERFIELD", <<"HERE", "JQUERYPLUGIN::SELECT2");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsContrib/userfield.js'></script>
HERE
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;

  $this->getOptions($value);

  if ($this->isMultiValued) {
    my @result = ();
    foreach my $val (split(/\s*,\s*/, $value)) {
      if (defined($this->{valueMap}{$val})) {
        $val = $this->{valueMap}{$val};
      }
      push @result, $val;
    }
    $value = join(", ", @result);
  } else {
    if ($this->isValueMapped) {
      if (defined($this->{valueMap}{$value})) {
        $value = $this->{valueMap}{$value};
      }
    }
  }

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub renderValueForDisplay {
  my ($this, $val) = @_;

  my $web = $this->param("web") || $Foswiki::cfg{UsersWebName};
  my $topicTitle = $this->getTopicTitle($web, $val);
  my $url = Foswiki::Func::getScriptUrl($web, $val, 'view');
  return "<a href='$url'>$topicTitle</a>";
}


1;

