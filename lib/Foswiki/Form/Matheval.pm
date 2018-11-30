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

package Foswiki::Form::Matheval;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins::MoreFormfieldsPlugin::MathExpression;

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
  my $form = Foswiki::Form->new($Foswiki::Plugins::SESSION, $web, $topic);

  $form->getPreference('dummy'); # make sure it's cached
  for my $key ($form->{_preferences}->prefs) {
      next unless $key =~ /^\Q$this->{name}\E_matheval_(\w+)$/;
      my $expanded = $topicObject->expandMacros($form->getPreference($key));
      return Foswiki::Func::decodeFormatTokens($expanded);
  }
}

sub renderForEdit {
    my ( $this, $topicObject, $value ) = @_;

    return (
        '',
        qq{
          <div class="wfapp-info-block grid-x ma-disabled-text ma-margin-top-small">
            <div class="cell shrink">
                <i class="far fa-info-circle"></i>
            </div>
            <div class="cell shrink">
                <div class="ma-spacer" style="width: 16px;"></div>
            </div>
            <div class="cell auto">
                %MAKETEXT{"Automatically computed on save"}%
            </div>
          </div>
        }
    );
}

sub beforeSaveHandler {
  my ($this, $topicObject) = @_;
  my $mathExpression = $this->param('expression', $topicObject);

  $mathExpression =~ s/,/./g;

  my $evaluator = Foswiki::Plugins::MoreFormfieldsPlugin::MathExpression->new();

  $evaluator->setExpression($mathExpression);
  my $valueToSet = $evaluator->evaluate();

  if(!defined $valueToSet){
    $valueToSet = "N/A";
  }

  $topicObject->putKeyed('FIELD', {
    name => $this->{name},
    title => $this->{name},
    type => "Set",
    value => $valueToSet
  });
}

sub solrIndexFieldHandler {
    my ( $this, $doc, $value, $mapped) = @_;
    $doc->add_fields('field_' . $this->{name} . '_f' => $value,) if defined $value && $value ne '';
}


1;

