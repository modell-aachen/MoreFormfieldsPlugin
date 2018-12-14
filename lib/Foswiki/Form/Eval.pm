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

package Foswiki::Form::Eval;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

our @ISA = ('Foswiki::Form::FieldDefinition');

sub new {
    my $class = shift;
    my $this = $class->SUPER::new(@_);
    $this->{size} = 1;
    $this->{delayBeforeSaveHandler} = 1;
    return $this;
}

sub isValueMapped {
  return 1;
}

sub param {
  my ($this, $key, $topicObject) = @_;

  my ($web, $topic) = @{$this}{'web', 'topic'};
  my $form = Foswiki::Form->new($Foswiki::Plugins::SESSION, $web, $topic);

  $form->getPreference('dummy'); # make sure it's cached
  for my $key ($form->{_preferences}->prefs) {
      next unless $key =~ /^\Q$this->{name}\E_$this->{type}_(\w+)$/;
      my $expanded = $topicObject->expandMacros($form->getPreference($key));
      return Foswiki::Func::decodeFormatTokens($expanded);
  }
}

sub beforeSaveHandler {
  my ($this, $topicObject) = @_;
  my $valueToSet = $this->param('value', $topicObject);

  $topicObject->putKeyed('FIELD', {
    name => $this->{name},
    title => $this->{name},
    type => "Set",
    value => $valueToSet
  });
}

1;

