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

package Foswiki::Form::Select2;

use strict;
use warnings;

use Foswiki::Form::Select ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Plugins::MoreFormfieldsPlugin ();
our @ISA = ('Foswiki::Form::Select');

use Assert;
use HTML::Entities;

BEGIN {
  if ($Foswiki::cfg{UseLocale}) {
    require locale;
    import locale();
  }
}

sub getOptions {
  my $this = shift;
  my $raw = shift;

  my $query = Foswiki::Func::getCgiQuery();

  my @values = @{$this->SUPER::getOptions()};

  return \@values if $raw || !@values || $values[0] !~ /^https?:\/\//;

  # For AJAX-based values, just take whatever we get via query
  @values = ();
  my @valuesFromQuery = $query->param( $this->{name} );
  foreach my $item (@valuesFromQuery) {

    # Item10889: Coming from an "Warning! Confirmation required", often
    # there's an undef item (the, last, empty, one, <-- here)
    if ( defined $item ) {
      foreach my $value ( split( /\s*,\s*/, $item ) ) {
        push @values, $value if defined $value;
      }
    }
  }
  return \@values;
}

sub getDefaultValue {
  my $this = shift;
  $this->param('defaultValue') || '';
}

sub param {
  my ($this, $key) = @_;

  unless (defined $this->{_params}) {
    my ($web, $topic) = @{$this}{'web', 'topic'};
    my $form = Foswiki::Form->new($Foswiki::Plugins::SESSION, $web, $topic);
    my %params = Foswiki::Func::extractParameters($form->expandMacros($this->{attributes}));
    $this->{_params} = \%params;
  }

  if (defined $key) {
    my $res = $this->{_params}{$key};
    $res = $this->{_defaultsettings}{$key} unless defined $res;
    return $res;
  }
  return $this->{_params};
}

sub cssClasses {
  my $this = shift;
  my $addClass = $this->param('cssClasses');
  push @_, $addClass if $addClass;

  $this->SUPER::cssClasses(@_);
}

sub _maketag {
  my ($tag, $params, $content, $forceempty) = @_;
  my $res = "<$tag";
  while (my ($k, $v) = each(%$params)) {
    $res .= " $k=\"";
    $res .= encode_entities($v, '<>&"');
    $res .= '"';
  }
  $content = '' unless defined $content;
  if ($content eq '' && !$forceempty) {
    return "$res />";
  }
  return "$res>$content</$tag>";
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $choices = '';
  my $choices_count = 0;

  $value = '' unless defined $value;
  my %isSelected = map { $_ => 1 } split(/\s*,\s*/, $value);
  my @options = @{$this->getOptions(1)};

  my $url;
  if (@options && $options[0] =~ /^https?:\/\//) {
    $url = $options[0];

    my @values = grep { defined $_ && /\S/ } split(/\s*,\s*/, $value);
    my @labels;
    if ($this->param('displayTopic') && $this->param('displaySection')) {
      @labels = $this->mapValuesToLabels(@values);
    }
    while (my $v = shift @values) {
      my %params;
      my $label = $v;
      if (@labels) {
        $params{value} = $v;
        $label = shift @labels;
      }
      $label =~ s/<nop/&lt;nop/g;
      $choices .= _maketag('option', \%params, $label);
      $choices_count++;
    }
  } else {
    foreach my $item (@options) {
      my $option = $item;    # Item9647: make a copy not to modify the original value in the array
      my %params;
      $params{selected} = 'selected' if $isSelected{$option};
      if ($this->{_descriptions}{$option}) {
        $params{title} = $this->{_descriptions}{$option};
      }
      if (defined($this->{valueMap}{$option})) {
        $params{value} = $option;
        $option = $this->{valueMap}{$option};
      }
      $option =~ s/<nop/&lt\;nop/go;
      $choices .= _maketag('option', \%params, $option);
      $choices_count++;
    }
  }
  $size = $choices_count;
  if ($size > $this->{maxSize}) {
    $size = $this->{maxSize};
  } elsif ($size < $this->{minSize}) {
    $size = $this->{minSize};
  }
  my $params = {
    class => $this->cssClasses('foswikiSelect2Field'),
    name => $this->{name},
    size => $this->{size},
    'data-width' => $this->param("width") || 'element',
    'data-allow-clear' => $this->param("allowClear") || 'false',
  };
  $params{'data-placeholder'} = $this->param('placeholder') if defined $this->param('placeholder');
  $params->{style} = 'width: '.$this->{size}.'ex;' if $this->{size};
  if (defined $url) {
    $params->{'data-url'} = $url;
    my $apf = $this->param('ajaxPassFields');
    $params->{'data-ajaxpassfields'} = $apf if $apf;
    my $resf = $this->param('resultsFilter');
    $params->{'data-resultsfilter'} = $resf if $resf;
    $params->{value} = $value;
  }
  $params->{'multiple'} = 'multiple';
  $value = _maketag('select', $params, $choices);

  $this->addJavascript();

  return ('', $value);
}

sub renderForDisplay {
  my ($this, $format, $value, $attrs) = @_;


  my $displayValue = $this->getDisplayValue($value);
  $format =~ s/\$value\(display\)/$displayValue/g;
  $format =~ s/\$value/$value/g;

  return $this->SUPER::renderForDisplay($format, $value, $attrs);
}

sub mapValuesToLabels {
  my ($this, @values) = @_;

  my $session = $Foswiki::Plugins::SESSION;
  my $mweb;
  ($mweb, $mtopic) = Foswiki::Func::normalizeWebTopicName(undef, $this->param('displayTopic'));
  my ($meta, $text) = Foswiki::Func::readTopic($mweb, $mtopic);
  return @values unless $meta && $meta->haveAccess('VIEW');

  $session->{prefs}->pushTopicContext($mweb, $mtopic);

  $text =~ s/^.*%STARTSECTION\{(?:\s*name\s*=)?\s*"?$msec"?\s*\}%//s;
  $text =~ s/%(?:STOP|END)SECTION\{(?:\s*name\s*=)?\s*"?$msec"?\s*\}%.*$//s;

  my @res = map { $session->{prefs}->setSessionPreferences(id => $_); $meta->expandMacros($text) } @$values;
  $session->{prefs}->popTopicContext();
  @res;
}

sub getDisplayValue {
  my ($this, $value) = @_;

  return '' unless defined $value && $value ne '';

  my @options = @{$this->getOptions($value)};

  if ($options[0] =~ /https?:\/\//) {
    if (my $mtopic = $this->param('displayTopic') and my $msec = $this->param('displaySection')) {
      my @v = $value;
      if ($this->isMultiValued()) {
        @v = split(/\s*,\s*/, $value);
      }
      return join($this->param('separator') || ', ', $this->mapValuesToLabels(@v));
    } else {
      return $value;
    }
  }
  my @v = $value;
  if ($this->isMultiValued()) {
    @v = split(/\s*,\s*/, $value);
  }
  my @res = map { $this->{valueMap}{$_} || $_ } @v;

  return join($this->param('separator') || ', ', @res);;
}

sub addJavascript {
  #my $this = shift;

  Foswiki::Plugins::JQueryPlugin::createPlugin("select2");
  Foswiki::Func::addToZone("script", "FOSWIKI::SELECT2FIELD", <<"HERE", "JQUERYPLUGIN::SELECT2");
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/select2field.js?v=$Foswiki::Plugins::MoreFormfieldsPlugin::RELEASE'></script>
HERE
}

1;
