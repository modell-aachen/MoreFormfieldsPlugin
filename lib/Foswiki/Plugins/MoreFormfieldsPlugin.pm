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

use JSON;

use Error qw(:try);

our $VERSION = '0.01';
our $RELEASE = '0.01';
our $SHORTDESCRIPTION = 'Additionall formfield types for %SYSTEMWEB%.DataForms';
our $NO_PREFS_IN_TOPIC = 1;


sub initPlugin {
  Foswiki::Func::registerRESTHandler( 'tags',
                                      \&_restTags,
                                      authenticate => 0,
                                      validate => 0,
                                      http_allow => 'GET'
                                      );
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
}

sub _restTags {
  my $session = shift;
  my $json = JSON->new->utf8;
  my $requestObject = Foswiki::Func::getRequestObject();
  my $q = $requestObject->param('q');
  my $tagField = $requestObject->param('tagField');
  my $term = $requestObject->param('term') || '';
  my $start = $requestObject->param('start') || 0;
  my $limit = $requestObject->param('limit') || 10;


  my $tagFieldFormName = 'field_'.$tagField.'_lst';
  my %search = (
      q => $q,
      start => 0,
      rows => 0,
      facet => 'true',
      'facet.field' => [$tagFieldFormName],
      'facet.contains' => $term,
      'facet.contains.ignoreCase' => 'true',
      'facet.sort' => 'count',
      'facet.limit' => $limit,
      'facet.offset' => $start
  );

  my $searcher = Foswiki::Plugins::SolrPlugin::getSearcher($session);
  my $results = $searcher->solrSearch(undef, \%search);
  my $content = $results->raw_response;

  my $result = {
    results => []
  };
  $content = $json->decode($content->{_content});
  my @facets = @{$content->{facet_counts}->{facet_fields}->{$tagFieldFormName}};
  for(my $i=0; $i < scalar @facets; $i = $i + 2){
    my $facet = {
      id => $facets[$i],
      text => $facets[$i],
      sublabel => "($facets[$i+1])"
    };
    push(@{$result->{results}}, $facet);
  }
  return to_json($result);
}

1;

