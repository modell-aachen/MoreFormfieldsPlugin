# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MyEmptyPlugin is Copyright (C) 2013-2014 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::MoreFormfieldsPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Form ();
use Foswiki::OopsException ();
use Foswiki::Plugins ();

use Error qw(:try);

our $VERSION = '0.0.1';
our $RELEASE = '0.0.1';
our $SHORTDESCRIPTION = 'Helper plugin for MoreFormfieldsContrib';
our $NO_PREFS_IN_TOPIC = 1;


sub initPlugin {
  return 1;
}

sub beforeSaveHandler {
  my ($text, $topic, $web, $meta) = @_;
  
  my $form = $meta->get("FORM");
  return unless $form;

  my $formName = $form->{name};

  my $session = $Foswiki::Plugins::SESSION;

  $form = undef;
  try {
    $form = new Foswiki::Form($session, $web, $formName);
  } catch Foswiki::OopsException with {
    my $error = shift;
    #print STDERR "Error reading form definition for $formName ... baling out\n";
  };
  return unless $form;

  # forward to formfields
  foreach my $field (@{$form->getFields}) {
    if ($field->can("beforeSaveHandler")) {
      $field->beforeSaveHandler($meta, $form);
    }
  }

  return;
}

1;

