package Foswiki::Form::Matheval;

use strict;
use warnings;

use Foswiki::Form::Eval;
use Foswiki::Plugins::MoreFormfieldsPlugin::MathExpression;

our @ISA = ('Foswiki::Form::Eval');

sub new {
    my $class = shift;
    my $this = $class->SUPER::new(@_);
    $this->{size} = 1;
    $this->{delayBeforeSaveHandler} = 0;
    return $this;
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
    $valueToSet = "NaN";
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

