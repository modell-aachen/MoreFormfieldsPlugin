# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# MoreFormfieldsContrib is Copyright (C) 2010-2014 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Form::Icon;

use strict;
use warnings;

use YAML ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Form::FieldDefinition ();
our @ISA = ('Foswiki::Form::FieldDefinition');

our %icons = ();

BEGIN {
  if ($Foswiki::cfg{UseLocale}) {
    require locale;
    import locale();
  }
}

sub new {
  my $class = shift;
  my $this = $class->SUPER::new(@_);

  my $size = $this->{size} || '';
  $size =~ s/\D//g;
  $size = 10 if (!$size || $size < 1);
  $this->{size} = $size;

  if ($this->{type} =~ /\+/) {
    my %modifiers = map {lc($_) => 1} grep {!/^icon$/} split(/\+/,$this->{type});
    @{$this->{modifiers}} = keys %modifiers;
    $this->{groupPattern} = join("|", @{$this->{modifiers}});
  }

  $this->{hasMultipleGroups} = (!defined($this->{modifiers}) || scalar(@{$this->{modifiers}}) > 1);

  return $this;
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  Foswiki::Plugins::JQueryPlugin::createPlugin("fontawesome");
  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");

  Foswiki::Func::addToZone("script", "FOSWIKI::ICONFIELD", <<'HERE', "JQUERYPLUGIN::FONTAWESOME, JQUERYPLUGIN::SELECT2");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsContrib/iconfield.js'></script>
HERE

  $this->readIcons();

  my $html = "<select class='".$this->cssClasses("foswikiFontAwesomeIconPicker")."' style='width:".$this->{size}."em' name='".$this->{name}."'>\n";
  $html .= '<option></option>';
  foreach my $group (sort keys %icons) {
    next if $this->{groupPattern} && $group !~ /$this->{groupPattern}/i;

    $html .= "  <optgroup label='$group'>\n" if scalar$this->{hasMultipleGroups};

    foreach my $entry (sort {$a->{id} cmp $b->{id}} @{$icons{$group}}) {
      $html .= "    <option value='$entry->{id}'".($value && $entry->{id} eq $value?"selected":"").">$entry->{id}</option>\n";
    }

    $html .= "  </optgroup>\n" if $this->{hasMultipleGroups};
  }
  $html .= "</select>\n";

  return ('', $html);
}

sub readIcons {
  my $this = shift;

  return if %icons;

  my $iconFile = $Foswiki::cfg{PubDir}.'/'.$Foswiki::cfg{SystemWebName}.'/MoreFormfieldsContrib/icons.yml';

  my $yml = YAML::LoadFile($iconFile); 


  foreach my $entry (@{$yml->{icons}}) {
    foreach my $cat (@{$entry->{categories}}) {
      push @{$icons{$cat}}, $entry;
      if ($entry->{aliases}) {
        foreach my $alias (@{$entry->{aliases}}) {
          my %clone = %$entry;
          $clone{id} = $alias;
          $clone{_isAlias} = 1;
          push @{$icons{$cat}}, \%clone;
        }
      }
    }
  }
}

sub renderForDisplay {
    my ( $this, $format, $value, $attrs ) = @_;

    Foswiki::Plugins::JQueryPlugin::createPlugin("fontawesome");

    my $displayValue = $this->getDisplayValue($value);
    $format =~ s/\$value\(display\)/$displayValue/g;
    $format =~ s/\$value/$value/g;

    return $this->SUPER::renderForDisplay( $format, $value, $attrs );
}

sub getDisplayValue {
    my ( $this, $value ) = @_;

    return "<i class='fa fa-$value'></i> ".$value;
}

1;
