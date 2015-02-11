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
our @ISA = ('Foswiki::Form::Select');

use Assert;

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

  return (defined $key)?$this->{_params}{$key}:$this->{_params};
}

sub renderForEdit {
  my ($this, $topicObject, $value) = @_;

  my $choices = '';

  $value = '' unless defined $value;
  my %isSelected = map { $_ => 1 } split(/\s*,\s*/, $value);
  my @options = @{$this->getOptions(1)};

  my $url;
  if (@options && $options[0] =~ /^https?:\/\//) {
    $url = $options[0];
  } else {
    foreach my $item (@options) {
      my $option = $item;    # Item9647: make a copy not to modify the original value in the array
      my %params = (class => 'foswikiOption',);
      $params{selected} = 'selected' if $isSelected{$option};
      if ($this->{_descriptions}{$option}) {
        $params{title} = $this->{_descriptions}{$option};
      }
      if (defined($this->{valueMap}{$option})) {
        $params{value} = $option;
        $option = $this->{valueMap}{$option};
      }
      $option =~ s/<nop/&lt\;nop/go;
      $choices .= CGI::option(\%params, $option);
    }
  }
  my $size = scalar(@{$this->getOptions()});
  if ($size > $this->{maxSize}) {
    $size = $this->{maxSize};
  } elsif ($size < $this->{minSize}) {
    $size = $this->{minSize};
  }
  my $params = {
    class => $this->cssClasses('foswikiSelect2Field'),
    name => $this->{name},
    size => $this->{size},
    'data-placeholder' => $this->param("placeholder") || 'select ...', 
    'data-width' => $this->param("width") || 'element',
    'data-allow-clear' => $this->param("allowClear") || 'false',
  };
  $params->{style} = 'width: '.$this->{size}.'ex;' if $this->{size};
  if (defined $url) {
    $params->{'data-url'} = $url;
    my $initUrl = $this->param('initUrl');
    $params->{'data-initurl'} = $initUrl if $initUrl;
    my $mapperTopic = $this->param('mapperTopic');
    $params->{'data-mappertopic'} = $mapperTopic if $mapperTopic;
    my $mapperSection = $this->param('mapperSection');
    $params->{'data-mappersection'} = $mapperSection if $mapperSection;
    my $apf = $this->param('ajaxPassFields');
    $params->{'data-ajaxpassfields'} = $apf if $apf;
    my $resf = $this->param('resultsFilter');
    $params->{'data-resultsfilter'} = $resf if $resf;
    $params->{value} = $value;
  }
  if ($this->isMultiValued()) {
    if (defined $url) {
      $params->{'data-multiple'} = 'true';
      $value = CGI::hidden($params);
    } else {
      $params->{'multiple'} = 'multiple';
      $value = CGI::Select($params, $choices);
    }
  } else {
    if (defined $url) {
      $value = CGI::hidden($params);
    } else {
      $value = CGI::Select($params, $choices);
    }
  }

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
      my $session = $Foswiki::Plugins::SESSION;
      my $mweb;
      ($mweb, $mtopic) = Foswiki::Func::normalizeWebTopicName(undef, $this->param('displayTopic'));
      my ($meta, $text) = Foswiki::Func::readTopic($mweb, $mtopic);
      return $value unless $meta && $meta->haveAccess('VIEW');

      $session->{prefs}->pushTopicContext($mweb, $mtopic);

      $text =~ s/^.*%STARTSECTION\{(?:\s*name\s*=)?\s*"?$msec"?\s*\}%//s;
      $text =~ s/%(?:STOP|END)SECTION\{(?:\s*name\s*=)?\s*"?$msec"?\s*\}%.*$//s;

      my @res = map { $session->{prefs}->setSessionPreferences(id => $_); $meta->expandMacros($text) } @v;
      $session->{prefs}->popTopicContext();

      return join($this->param('separator') || ', ', @res);
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
<script type='text/javascript' src='%PUBURLPATH%/%SYSTEMWEB%/MoreFormfieldsPlugin/select2field.js'></script>
HERE
}

1;
