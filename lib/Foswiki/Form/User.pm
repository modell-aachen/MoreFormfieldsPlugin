# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsPlugin is Copyright (C) 2010-2014 Michael Daum http://michaeldaumconsulting.com
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

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

our @ISA = ('Foswiki::Form::Select2');

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);

    $this->{_defaultsettings}{cssClasses} = 'foswikiUserField';
    $this->{_defaultsettings}{displayTopic} = "$Foswiki::cfg{SystemWebName}.MoreFormfieldsAjaxHelper";
    $this->{_defaultsettings}{displaySection} = "user_display";
    return $this;
}

sub getOptions {
  my $this = shift;
  my $raw = shift;
  my @values = @{$this->SUPER::getOptions()};

  return \@values if $raw || !@values || $values[0] !~ /^https?:\/\//;

  return Foswiki::Func::getScriptUrl($Foswiki::cfg{SystemWebName}, 'MoreFormfieldsAjaxHelper', 'view',
    skin => 'text',
    contenttype => 'text/plain',
    section => 'user',
  );
}

1;

