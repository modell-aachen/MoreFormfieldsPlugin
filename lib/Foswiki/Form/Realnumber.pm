# See bottom of file for license and copyright information
package Foswiki::Form::Realnumber;

use strict;
use warnings;

use Foswiki::Form::FieldDefinition ();
use Foswiki::Plugins::VueJSPlugin;
our @ISA = ('Foswiki::Form::FieldDefinition');

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);
    my $size  = $this->{size} || '';
    $size =~ s/\D//g;
    $size = 60 if ( !$size || $size < 1 );
    $this->{size} = $size;
    return $this;
}

sub renderForEdit {
    my ( $this, $topicObject, $value ) = @_;

    my $mandatoryAttribute = ($this->isMandatory ? ' is-mandatory' : '');
    $value = Foswiki::Func::encode($value);
    my $name = Foswiki::Func::encode($this->{name});
    my $size = Foswiki::Func::encode($this->{size});

    return (
        '',
        "<vue-input-real-number-form-wrapper class='vue-container'$mandatoryAttribute value='$value' name='$name' :size='$size'></vue-input-real-number-wrapper>"
    );
}

sub solrIndexFieldHandler {
    my ( $this, $doc, $value, $mapped) = @_;
    $doc->add_fields('field_' . $this->{name} . '_d' => $value,) if defined $value && $value ne '';
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2005-2007 TWiki Contributors. All Rights Reserved.
TWiki Contributors are listed in the AUTHORS file in the root
of this distribution. NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

