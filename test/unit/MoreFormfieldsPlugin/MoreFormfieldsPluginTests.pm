# See bottom of file for license and copyright information
use strict;
use warnings;

package MoreFormfieldsPluginTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use warnings;

use Foswiki();
use Error qw ( :try );
use Foswiki::Plugins::MoreFormfieldsPlugin();
use Foswiki::Plugins::SolrPlugin::Search();

use Test::MockModule;

my $mocks;

sub new {
    my ($class, @args) = @_;
    my $this = shift()->SUPER::new('MoreFormfieldsPluginTests', @args);
    return $this;
}

sub loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();
    $Foswiki::cfg{Plugins}{MoreFormfieldsPlugin}{Enabled} = 1;
    $Foswiki::cfg{Plugins}{SolrPlugin}{Enabled} = 1;
}

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    $this->set_up_mocks();
}

sub set_up_mocks {
    my $this = shift;

    $mocks = {};
    foreach my $module (qw(
        Foswiki::Form::Select2
        Foswiki::Plugins::SolrPlugin::Search
    )) {
        $mocks->{$module} = Test::MockModule->new($module);
    }
}


sub tear_down {
    my $this = shift;

    foreach my $module (keys %$mocks) {
        $mocks->{$module}->unmock_all();
    }

    $this->SUPER::tear_down();
}

sub test_beforeSaveParsesQuery {
    my $this = shift;

    my ($topicMeta, $formTopicObject, $form, $field) = $this->createMockFormAndTopic();

    $field->beforeSaveHandler($topicMeta, $formTopicObject);
}

sub test_beforeSaveDetectsNewTags {
    my $this = shift;

    my ($topicMeta, $formTopicObject, $form, $field) = $this->createMockFormAndTopic(value => 'NewTag');

    try {
        $field->beforeSaveHandler($topicMeta, $formTopicObject);
        $this->assert(0, "Was able to save new tags");
    } catch Foswiki::OopsException with {
    }
}

sub test_allowedUsersMayCreateTags {
    my $this = shift;

    my ($topicMeta, $formTopicObject, $form, $field) = $this->createMockFormAndTopic(value => 'NewTag');
    $mocks->{'Foswiki::Form::Select2'}->mock('isAllowed', 1);

    try {
        $field->beforeSaveHandler($topicMeta, $formTopicObject);
    } catch Foswiki::OopsException with {
        $this->assert(0, "Was NOT able to save new tags");
    }
}

sub test_isAllowedDetectsAdmin {
    my $this = shift;

    my $session = $this->createNewFoswikiSession( $Foswiki::cfg{AdminUserLogin} || 'AdminUser' );

    $this->assert(Foswiki::Form::Select2::isAllowed('nobody'), "AdminUser was denied");
}

sub test_isAllowedDetectsGroup {
    my $this = shift;

    $this->registerUser( 'test1', 'Test', "One", 'testuser1@example.com' );
    Foswiki::Func::addUserToGroup('test1', 'MyGroup', 1);

    my $session = $this->createNewFoswikiSession( 'test1' );

    $this->assert(Foswiki::Form::Select2::isAllowed('SomeGroup,MyGroup'), "GroupMember was denied");
}

sub test_isAllowedDetectsUser {
    my $this = shift;

    $this->registerUser( 'test1', 'Test', "One", 'testuser1@example.com' );

    my $session = $this->createNewFoswikiSession( 'test1' );

    $this->assert(Foswiki::Form::Select2::isAllowed('SomeGroup,test1'), "User was denied");
}

sub createMockFormAndTopic {
    my $this = shift;
    my %opts = @_;

    my $formTopic = $opts{formTopic} || 'SelectTwoTestForm';
    my $fieldName = $opts{fieldName} || 'Tags';
    my $formValues = $opts{formValues} || '%SCRIPTURL{rest}%/MoreFormfieldsPlugin/tags?q=AStrangeQuery:%BASEWEB%+AnotherQuery:Test&blabla';
    my $allowCreateTags = $opts{allowCreateTags} || 'KeyUserGroup';

    my ($formTopicObject) = Foswiki::Func::readTopic( $this->{test_web}, $formTopic );
    $formTopicObject->text(<<FORM);
| *name* | *type* | *size* | *values* | *attributes* |
| $fieldName | select2+multi | 50 | $formValues | tagging="true" |
   * Set Tags_s2_allowCreateTags = $allowCreateTags
FORM
    $formTopicObject->save();

    my $topic = $opts{topic} || 'MyTopic';
    my $value = $opts{value} || 'MyValue,MyOtherValue';
    my ($topicMeta) = Foswiki::Func::readTopic( $this->{test_web}, $topic );
    $topicMeta->put('FORM', { name => $formTopic } );
    $topicMeta->put('FIELD', { name => $fieldName, title => $fieldName, value => $value } );

    my $form = new Foswiki::Form($Foswiki::Plugins::SESSION, $this->{test_web}, $formTopic);
    my $field = $form->getField($fieldName);

    $mocks->{'Foswiki::Form::Select2'}->mock('isAllowed', 0);

    my $expectedQuery = $opts{expectedQuery} || "AStrangeQuery:$this->{test_web} AnotherQuery:Test";
    $mocks->{'Foswiki::Plugins::SolrPlugin::Search'}->mock('doSearch', sub {
            my ($searcher, $query, $params) = @_;
            $this->assert($query eq $expectedQuery, "Could not parse query for Solr, got: '$query' instead of $expectedQuery");

            my $content = {
                facet_counts => {
                    facet_fields => {
                        "field_${fieldName}_lst" => $opts{solrMockResult} || [MyValue => 1, MyOtherValue => 1 ],
                    }
                }
            };
            return bless { content => $content }, 'MockSolrResponse';
        }
    );

    return ($topicMeta, $formTopicObject, $form, $field);
}

package MockSolrResponse;

sub content {
    my ($this) = @_;

    return $this->{content};
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Author: Modell Aachen GmbH

Copyright (C) 2008-2011 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

