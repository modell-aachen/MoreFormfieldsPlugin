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
    return $this;
}

sub isValueMapped {
  return 1;
}

sub param {
  my ($this, $key, $topicObject) = @_;

  my ($web, $topic) = @{$this}{'web', 'topic'};
  use Data::Dumper;
  my $form = Foswiki::Form->new($Foswiki::Plugins::SESSION, $web, $topic);
  
  my %params = Foswiki::Func::extractParameters($form->expandMacros($this->{attributes}));
  $this->{_params} = \%params;

  $form->getPreference('dummy'); # make sure it's cached
  Foswiki::Func::writeWarning(Dumper($form->{_preferences}->prefs));
  for my $key ($form->{_preferences}->prefs) {
    Foswiki::Func::writeWarning($key);
      next unless $key =~ /^\Q$this->{name}\E_eval_(\w+)$/;
      Foswiki::Func::writeWarning(Dumper($topicObject->expandMacros("%QUERY{\"3spe0h\"}%")));
      $this->{_params}{$1} = $topicObject->expandMacros($form->getPreference($key));
  }

  Foswiki::Func::writeWarning("Evaled!");

  if (defined $key) {
    my $res = $this->{_params}{$key};
    $res = $this->{_defaultsettings}{$key} unless defined $res;
    return $res;
  }
  return $this->{_params};
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

