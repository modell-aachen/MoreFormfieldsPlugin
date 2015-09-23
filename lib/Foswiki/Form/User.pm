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

use Foswiki::Form::Select2 ();

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

our @ISA = ('Foswiki::Form::Select2');

sub new {
    my $class = shift;
    my $this = $class->SUPER::new(@_);

    $this->{_defaultsettings}{cssClasses} = 'foswikiUserField';
    $this->{_defaultsettings}{displayTopic} = "$Foswiki::cfg{SystemWebName}.MoreFormfieldsAjaxHelper";
    $this->{_defaultsettings}{displaySection} = "select2::user::display";
    return $this;
}

sub getOptions {
  my $this = shift;
  my $raw = shift;

  my $web = $Foswiki::cfg{SystemWebName};
  my $topic = 'MoreFormfieldsAjaxHelper';
  my $pref = Foswiki::Func::getPreferencesValue('USERFIELDAJAXHELPER');
  if ($pref) {
    ($web, $topic) = Foswiki::Func::normalizeWebTopicName($Foswiki::Plugins::SESSION->{webName}, $pref);
  }
  return [Foswiki::Func::getScriptUrl($web, $topic, 'view',
    skin => 'text',
    contenttype => 'text/plain',
    section => 'select2::user',
  )];
}

1;

