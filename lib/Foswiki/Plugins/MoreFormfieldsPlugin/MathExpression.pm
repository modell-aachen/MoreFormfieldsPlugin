# ########################################################################################
# A CALCULUS EXPRESSION OBJECT
# Common algebra routines module by Jonathan Worthington.
# Copyright (C) Jonathan Worthington 2004-2005
# This module may be used and distributed under the same terms as Perl.
# ########################################################################################

package Foswiki::Plugins::MoreFormfieldsPlugin::MathExpression;
use strict;
our $VERSION = '0.2.2';

=head1 NAME

Math::Calculus::Expression - Algebraic Calculus Tools Expression Class

=head1 SYNOPSIS

  use Math::Calculus::Expression;

  # Create an expression object.
  my $exp = Math::Calculus::Expression->new;

  # Set a variable and expression.
  $exp->addVariable('x');
  $exp->setExpression('x^(2+1) + 6*5*x') or die $exp->getError;

  # Simplify
  $exp->simplify or die $exp->getError;;

  # Print the result.
  print $exp->getExpression; # Prints x^3 + 30*x


=head1 DESCRIPTION

This module can take an algebraic expression, parse it into a tree structure, simplify
the tree, substitute variables and named constants for other variables or constants
(which may be numeric), numerically evaluate the tree and turn the tree back into an
output of the same form as the input.

It supports a wide range of expressions including the +, -, *, / and ^ (raise to
power) operators, bracketed expressions to enable correct precedence and the functions
ln, exp, sin, cos, tan, sec, cosec, cot, sinh, cosh, tanh, sech, cosech, coth, asin,
acos, atan, asinh, acosh and atanh.

=head1 EXPORT

None by default.

=head1 METHODS

=cut

# Constructor
# ###########

=item new

  $exp = Math::Calculus::Expression->new;

Creates a new instance of the expression object, which can hold an individual
expression and perform basic operations on it.

=cut

sub new {
	# Get invocant.
	my $invocant = shift;

	# Create object.
	my $self = {
		traceback	=> '',
		error		=> '',
		expression	=> 0,
		variables	=> [],
	};
	return bless $self, $invocant;
}


# Add variable.
# #############

=item addVariable

  $exp->addVariable('x');

Sets a certain named value in the expression as being a variable. A named value must be
an alphabetic chracter.

=cut

sub addVariable {
	# Get invocant and parameters.
	my ($self, $var) = @_;

	# Provided the variable is just one character and we don't already have it...
	unless (length($var) != 1 || grep { $_ eq $var } @{$self->{'variables'}}) {
		$self->{'variables'}->[@{$self->{'variables'}}] = $var;
		$self->{'error'} = '';
		return 1;
	} else {
		$self->{'error'} = 'Invalid variable or variable already added.';
		return undef;
	}
}


# Set Expression
# ##############

=item setExpression

  $exp->setExpression('x^2 + 5*x);

Takes an expression in human-readable form and stores it internally as a tree structure,
checking it is a valid expression that the module can understand in the process. Note that
the module is strict about syntax. For example, note above that you must write 5*x and not
just 5x. Whitespace is allowed in the expression, but does not have any effect on precedence.
If you require control of precedence, use brackets; bracketed expressions will always be
evaluated first, as you would normally expect. The module follows the BODMAS precedence
convention. Returns undef on failure and a true value on success.

=cut

sub setExpression {
	# Get invocant and parameters.
	my ($self, $expr) = @_;

	# Clear up the expression.
	$expr =~ s/\s//g;
	1 while $expr =~ s/--/+/g
	     || $expr =~ s/\+-|-\+/-/g
	     || $expr =~ s/([+\-*\/\^])\+/$1/g
	     || $expr =~ s/^\+//g;

	# Build expression tree.
	$self->{'error'} = $self->{'traceback'} = undef;
	$self->{'expression'} = $self->buildTree($expr);

	# Return depending on whether there was an error.
	if ($self->{'error'}) {
		return undef;
	} else {
		return 1;
	}
}


# Get Expression
# ##############

=item getExpression

  $expr = $exp->getExpression;

Returns a textaul, human readable representation of the expression that is being stored.

=cut

sub getExpression {
	# Get invocant.
	my $self = shift;

	# Walk expression tree and generate something to display.
	$self->{'error'} = '';
	my $text = $self->prettyPrint($self->{'expression'});

	# If there was an error, return nothing.
	if ($self->{'error'}) {
		return undef;
	} else {
		return $text;
	}
}


# Simplify.
# #########

=item simplify

  $exp->simplify;

Attempts to simplify the expression that is stored internally.

=cut

sub simplify {
	# Get invocant.
	my ($self) = @_;

	# Clear error.
	$self->{'error'} = undef;

	# Simplify.
	eval {
		$self->{'expression'} = $self->recSimplify($self->{'expression'}, undef);
	};

	# We may have boiled it all down to a numerical constant...
	my $const = $self->numericEvaluation($self->{'expression'});
	if (defined($const)) {
		$self->{'expression'} = $const;
	}

	# Return an appropriate value (or lack thereof...).
	if ($self->{'error'}) {
		return undef;
	} else {
		return 1;
	}
}


# Evaluate.
# #########

=item evaluate

  $exp->evaluate(x => 0.5, a => 4);

This method takes a hash mapping any variables and named constants (represented
by letters) in the expression to numerical values, and attempts to evaluate the
expression and return a numerical value. It fails and returns undef if it finds
letters that have no mapping or an error such as division by zero occurs during
the evaluation.

=cut

sub evaluate {
	# Get invocant.
	my ($self, %mapping) = @_;

	# Clear error.
	$self->{'error'} = undef;

	# Evaluate.
	my $value = undef;
	eval {
		$value = $self->evaluateTree($self->{'expression'}, %mapping);
	} || ($self->{'error'} ||= $@);

	# Return value or undef if we there was an error.
	if ($self->{'error'}) {
		return undef;
	} else {
		return $value;
	}
}


# Same representation?
# ####################

=item sameRepresentation

  $same = $exp->sameRepresentation($exp2);

The sameRepresentation method takes another expression object as its parameter
and returns true if that expression has the same internal representation as the
expression the method is invoked on. Be careful  while it can be said that if
two expressions have the same representation they are equal, it would be wrong
to say that if they have different representations they are not equal. It is
clear to see that "x + 2" and "2 + x" are equal, but their internal representation
may well differ.

=cut

sub sameRepresentation {
	# Get invocant.
	my ($self, $exp2) = @_;

	# Clear error.
	$self->{'error'} = undef;

	# Compare and return result.
	return $self->isIdentical($self->{'expression'}, $exp2->getExpressionTree);
}


# Clone.
# ######

=item clone

  $expCopy = $exp->clone;

The clone method returns a deep copy of the expression object (deep copy meaning
that if the original is modified the copy will not be affected and vice versa).

=cut

sub clone {
	# Get invocant.
	my ($self) = @_;

	# Clear error.
	$self->{'error'} = undef;

	# Do a deep copy.
	my $tree = $self->deepCopy($self->{'expression'});

	# Create new object with copied tree and return.
	my $clone = {
		traceback	=> $self->{'traceback'},
		error		=> $self->{'error'},
		expression	=> $tree,
		variables	=> [ @{$self->{'variables'}} ]
	};
	return bless $clone, 'Math::Calculus::Expression';
}


# Get traceback.
# ##############

=item getTraceback

  $exp->getTraceback;

When setExpression and differentiate are called, a traceback is generated to describe
what these functions did. If an error occurs, this traceback can be extremely useful
in helping track down the source of the error.

=cut

sub getTraceback {
	return $_[0]->{'traceback'};
}


# Get error.
# ##########

=item getError

  $exp->getError;

When any method other than getTraceback is called, the error message stored is cleared, and
then any errors that occur during the execution of the method are stored. If failure occurs,
call this method to get a textual representation of the error.

=cut

sub getError {
	return $_[0]->{'error'};
}


# Any other methods.
# ##################

=item Other Methods

Any other method call is taken to refer to a subclass of Expression. The first letter of the
name of the method invoked is capitalized, then a module by that name is loaded (if it exists)
and the method is called on it. This works for, for example, the Differentiate module; calling
the differentiate method on an Expression will load the Differentiate module and call the
differentiate method. If a module cannot be loaded or the method cannot be called, then this
module will die.

=cut

sub AUTOLOAD {
	# Grab the params to pass on.
	my ($self, @params) = @_;

	# Get the name of the method called; skip if it is destroy.
	my $name = our $AUTOLOAD;
	return undef if $name =~ /::DESTROY$/;
	$name =~ s/^.+::([A-Za-z0-9]+)(_\w+)?$/$1$2/;
	my $modName = ucfirst $1;

	# Attempt to load the module and call the method.
	if (wantarray) {
		my @result = eval {
			require "Math/Calculus/$modName.pm";
			bless $self, "Math::Calculus::$modName";
			my $meth = eval('\&Math::Calculus::' . $modName . '::' . $name);
			$meth->($self, @params)
		};
		die $@ if $@;
		return @result;
	} else {
		my $result = eval {
			require "Math/Calculus/$modName.pm";
			bless $self, "Math::Calculus::$modName";
			my $meth = eval('\&Math::Calculus::' . $modName . '::' . $name);
			$meth->($self, @params)
		};
		die $@ if $@;
		return $result;
	}
}


=head1 SEE ALSO

The author of this module has a website at L<http://www.jwcs.net/~jonathan/>, which has
the latest news about the module and a web-based frontend to allow you to try out this
module and, more specifically, its subclasses.

=head1 AUTHOR

Jonathan Worthington, E<lt>jonathan@jwcs.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jonathan Worthington

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


# ########################################################################################
# Private Methods
# ########################################################################################


# Get expression tree simply gets the raw expression tree.
# ########################################################################################
sub getExpressionTree { return $_[0]->{'expression'}; }


# Build tree recursively explores the passed expression and generates a tree for it.
# The trees take a structure of an operation (which is +, -, *, /, ^, sin, cos, tan,
# sec, cosec, cot, sinh, cosh, tanh, sech, cosech, coth, asin, acos, atan, asinh,
# acosh, atanh, exp or ln) and two operands, which are either constants or references
# to other trees.
# ########################################################################################
sub buildTree {
	# Get invocant and expression.
	my ($self, $expr) = @_;

	# Store what we're parsing in the traceback.
	$self->{'traceback'} .= "Parsing $expr\n";

	# Clear any brackets around the entire expression.
	my $bracketsRemoved = 1;
	while ($bracketsRemoved && substr($expr, 0, 1) eq '(') {
		# See if there are any brackets to remove.
		my $bracketDepth = 0;
		my $bracketDepthHitZero = 0;
		my $count = 0;
		foreach my $char (split //, $expr) {
			if ($char eq '(') {
				$bracketDepth ++;
			} elsif ($char eq ')') {
				$bracketDepth --;
			}
			if ($bracketDepth == 0 && $count > 0 && $count + 1 < length($expr)) {
				$bracketDepthHitZero = 1;
			}
			$count++;
		}

		# If so, remove them.
		if ($bracketDepthHitZero == 0) {
			$expr =~ s/^\((.+)\)$/$1/;
		} else {
			$bracketsRemoved = 0;
		}
	}

	# If it's a constant or single variable...
	if ($expr =~ /^ (\-? ( (\d+(\.\d+)?) | [A-Za-z] )) $/x) {
		# No tree to build; just return the expression.
		return $1;

	# Otherwise it could be a function.
	} elsif ($expr =~ /^ (\-?) (a?sinh?|a?cosh?|a?tanh?|sech?|cosech?|coth?|ln|exp) \((.+)\) $/x &&
	         $self->isProperlyNested($3)) {
		# Return single operand parse tree.
		return {
			operation	=> "$1$2",
			operand1	=> $self->buildTree($3),
			operand2	=> undef
		};
	} else {
		# Otherwise full analysis needed. Analyse expressiona and try to find a split point.
		my $error = undef;
		my $bestSplitOp = '';
		my $splitOpPos = 0;
		my $bracketDepth = 0;

		# Cycle through all characters.
		my $curChar = 1;
		my $lastCharOp = 1;
		foreach my $char (split //, $expr) {
			# Maintain bracket depth.
			if ($char eq '(') {
				$bracketDepth ++;
			} elsif ($char eq ')') {
				$bracketDepth --;

			# Do we have a split point?
			} elsif ($curChar > 1 && $bracketDepth == 0 && $char =~ /[\^*\/+\-]/ &&
      	                    ($self->higherPrecedence($bestSplitOp, $char) || !$bestSplitOp)
			         && !$lastCharOp) {
				$splitOpPos = $curChar;
				$bestSplitOp = $char;
			}

			# If bracket depth is negative, we've got an error.
			if ($bracketDepth < 0)
			{
				$error = "Brackets not properly nested.";
			}

			# Maintain flag for if this character was an operator.
			$lastCharOp = $char =~ /[\^*\/+\-]/ ? 1 : 0;

			# Increment character counter.
			$curChar ++;
		}

		# Split failure error.
		if (!$error && !$bestSplitOp) {
			$error = 'Could not split expression ' . $expr;
		}

		# If there wasn't an error, split, get operand and parse each subexpression.
		unless ($error) {
			my $operand1 = substr($expr, 0, $splitOpPos - 1);
			my $operand2 = substr($expr, $splitOpPos);
			if ($operand2 ne '') {
				return {
					operation	=> $bestSplitOp,
					operand1	=> $self->buildTree($operand1),
					operand2	=> $self->buildTree($operand2)
				};
			} else {
				$error = 'Could not split expression ' . $expr;
			}
		}

		# If we've got an error, store it and return failure.
		if ($error) {
			$self->{'error'} = $error;
			return undef;
		}
 	}

	# If we get here, something weird happened.
	$self->{'error'} = "Unknown error parsing $expr.";
	return undef;
}


# Pretty print takes an expression tree and returns a text representation for it.
# #######################################################################################
sub prettyPrint {
	# Get invocant and tree.
	my ($self, $tree, $lastOp) = @_;

	# See if the tree actually is a tree. If not, it's a value and just return it.
	unless (ref $tree) {
		return $tree;
	} else {
		# See how many operands we take.
		my $curOp = $tree->{'operation'};
		if ($curOp =~ /^[\^\/*\-+]$/) {
			# Dual operand. Look at last op to see if we need brackets.
			my $brackets = ($curOp eq '^' && $lastOp =~ /[\/*+\-]/ ||
			                $curOp =~ /[\/*]/ && $lastOp =~ /[*+\-]/ ||
			                $curOp =~ /[+\-]/ && $lastOp =~ /[+\-]/ ||
                                  !(defined($lastOp)) || $lastOp eq '(')
					   ? 0 : 1;

			# Pretty-print each operand, adding spaces around + and - ops.
			my $pretty = '';
			$pretty .= '(' if $brackets;
			$pretty .= $self->prettyPrint($tree->{'operand1'}, $curOp);
			$pretty .= ($curOp =~ /[+\-]/ ? ' ' : '') . $curOp . ($curOp =~ /[+\-]/ ? ' ' : '');
			$pretty .= $self->prettyPrint($tree->{'operand2'}, $curOp);
			$pretty .= ')' if $brackets;
			return $pretty;
		} else {
			# Single operand, e.g. function.
			return $curOp . '(' . $self->prettyPrint($tree->{'operand1'}, '(') . ')';
		}
	}
}


# recSimplify recursively walks a tree and simplifies the branches, then the current
# node.
# ########################################################################################
sub recSimplify {
	# Get invocant, variable and tree.
	my ($self, $tree) = @_;

	# If it's just a node, return it. We can't do a great deal with nodes.
	return $tree unless ref $tree;

	# Pull out left and right branches for neatness.
	my ($left, $right) = ($tree->{'operand1'}, $tree->{'operand2'});

	## RECURSIVELY SIMPLIFTY TREES
	$left = $self->recSimplify($left);
	$right = $self->recSimplify($right);

	## CONSTANT EVALUATION

	# Get any available numeric evaluations of the left and right branches.
	my $leftval = $self->numericEvaluation($left);
	my $rightval = $self->numericEvaluation($right);

	# If they have a numeric evaluation, assign them to the actual values.
	$left = $leftval if defined($leftval);
	$right = $rightval if defined($rightval);

	## SHIFTING NEGATIVES
	## These simplifications are not "the final word", indeed dealing with them
	## allows further simplifications to take place. So we modify the tree "in
	## place".

	# x - (-y) = x + y
	if ($tree->{'operation'} eq '-') {
		if (!(ref $right) && $right =~ /^-(.+)$/) {
			$tree->{'operation'} = '+';
			$right = $1;
		} elsif (ref $right && $right->{'operation'} =~ /^-(.+)$/) {
			$tree->{'operation'} = '+';
			$right->{'operation'} = $1;
		}
	}

	# x + (-y) = x - y
	elsif ($tree->{'operation'} eq '+') {
		if (!(ref $right) && $right =~ /^-(.+)$/) {
			$tree->{'operation'} = '-';
			$right = $1;
		} elsif (ref $right && $right->{'operation'} =~ /^-(.+)$/) {
			$tree->{'operation'} = '-';
			$right->{'operation'} = $1;
		}
	}

	# x - -y*z = x + y*z
	if ($tree->{'operation'} eq '-' && ref $right && $right->{'operation'} eq '*') {
		if (!(ref $right->{'operand1'}) && $right->{'operand1'} =~ /^-(.+)$/) {
			$tree->{'operation'} = '+';
			$right->{'operand1'} = $1;
		} elsif (ref($right->{'operand1'}) && $right->{'operand1'}->{'operation'} =~ /^-(.+)$/) {
			$tree->{'operation'} = '+';
			$right->{'operand1'}->{'operation'} = $1;
		}
	}

	# x + -y*z = x - y*z
	elsif ($tree->{'operation'} eq '+' && ref $right && $right->{'operation'} eq '*') {
		if (!(ref $right->{'operand1'}) && $right->{'operand1'} =~ /^-(.+)$/) {
			$tree->{'operation'} = '-';
			$right->{'operand1'} = $1;
		} elsif (ref $right->{'operand1'} && $right->{'operand1'}->{'operation'} =~ /^-(.+)$/) {
			$tree->{'operation'} = '-';
			$right->{'operand1'}->{'operation'} = $1;
		}
	}

	## MIGRATE CONSTANTS UP THE TREE

	# x * c = c * x
	if ($tree->{'operation'} eq '*' && !ref($right) && $right =~ /^-?\d+(\.\d+)?$/) {
		($left, $right) = ($right, $left);

	# x * c * y = c * x * y
	} elsif ($tree->{'operation'} eq '*' && ref $right && $right->{'operation'} eq '*' &&
	    $right->{'operand1'} =~ /^-?\d+(\.\d+)?$/) {
		($left, $right->{'operand1'}) = ($right->{'operand1'}, $left);

	# x * y * c = x * c * y
	} elsif ($tree->{'operation'} eq '*' && ref $right && $right->{'operation'} eq '*' &&
	    $right->{'operand2'} =~ /^-?\d+(\.\d+)?$/) {
		($right->{'operand1'}, $right->{'operand2'}) = ($right->{'operand2'}, $right->{'operand1'});
	}

	## NULL OPERATORS

	# 0 + x = x + 0 = x
	if ($tree->{'operation'} eq '+' && (!(ref $left) && $left eq '0')) {
		return $right;
	}
	if ($tree->{'operation'} eq '+' && (!(ref $right) && $right eq '0')) {
		return $left;
	}

	# x - 0 = x
	if ($tree->{'operation'} eq '-' && (!(ref $right) && $right eq '0')) {
		return $left;
	}

	# x - 0 + y = x - y
	# x + 0 + y = x + y
	if ($tree->{'operation'} =~ /^[+-]$/ && ref $right && $right->{'operation'} =~ /^[+-]$/ &&
	    !(ref $right->{'operand1'}) && $right->{'operand1'} eq '0') {
		$right = $right->{'operand2'};
	}

	# 1 * x = x * 1 = x
	if ($tree->{'operation'} eq '*' && (!(ref $left) && $left eq '1')) {
		return $right;
	}
	if ($tree->{'operation'} eq '*' && (!(ref $right) && $right eq '1')) {
		return $left;
	}

	# x / 1 = x
	if ($tree->{'operation'} eq '/' && (!(ref $right) && $right eq '1')) {
		return $left;
	}

	# x ^ 1 = x
	if ($tree->{'operation'} eq '^' && (!(ref $right) && $right eq '1')) {
		return $left;
	}

	## EFFECTS OF ZERO

	# x ^ 0 = 1
	if ($tree->{'operation'} eq '^' && (!(ref $right) && $right eq '0')) {
		return 1;
	}

	# 0 * x = x * 0 = 0
	if ($tree->{'operation'} eq '*' && (!(ref $left) && $left eq '0')) {
		return 0;
	}
	if ($tree->{'operation'} eq '*' && (!(ref $right) && $right eq '0')) {
		return 0;
	}

	# 0 / x = 0
	if ($tree->{'operation'} eq '/' && (!(ref $left) && $left eq '0')) {
		return 0;
	}

	## DIVISION OF AN EXPRESSION BY ITSELF

	# x / x = 1
	if ($tree->{'operation'} eq '/' && $self->isIdentical($left, $right)) {
		return 1;
	}

	## SUBTRACTION OF AN EXPRESSION FROM ITSELF

	# x - x = 0
	if ($tree->{'operation'} eq '-' && $self->isIdentical($left, $right)) {
		return 0;
	}

	## DEEP NUMERICAL CONSTANT COMBINATION

	# n * (m * x) = (o * x) where o = nm
	if ($tree->{'operation'} eq '*' && ref($right) && $right->{'operation'} eq '*' &&
	    !(ref($left)) && $left =~ /^-?\d+(\.\d+)?$/ && $right->{'operand1'} =~ /^-?\d+(\.\d+)?$/) {
		return {
			operation	=> '*',
			operand1	=> ($left * $right->{'operand1'}),
			operand2	=> $right->{'operand2'}
		};

	# n * (x * m) = (o * x) where o = nm
	} elsif ($tree->{'operation'} eq '*' && ref($right) && $right->{'operation'} eq '*' &&
	    !(ref($left)) && $left =~ /^-?\d+(\.\d+)?$/ && $right->{'operand2'} =~ /^-?\d+(\.\d+)?$/) {
		return {
			operation	=> '*',
			operand1	=> ($left * $right->{'operand2'}),
			operand2	=> $right->{'operand1'}
		};

	# (m * x) * n = (o * x) where o = nm
	} elsif ($tree->{'operation'} eq '*' && ref($left) && $left->{'operation'} eq '*' &&
	    !(ref($right)) && $right =~ /^-?\d+(\.\d+)?$/ && $left->{'operand1'} =~ /^-?\d+(\.\d+)?$/) {
		return {
			operation	=> '*',
			operand1	=> ($right * $left->{'operand1'}),
			operand2	=> $right->{'operand2'}
		};

	# (x * m) * n = (o * x) where o = nm
	} elsif ($tree->{'operation'} eq '*' && ref($left) && $left->{'operation'} eq '*' &&
	    !(ref($right)) && $right =~ /^-?\d+(\.\d+)?$/ && $left->{'operand2'} =~ /^-?\d+(\.\d+)?$/) {
		return {
			operation	=> '*',
			operand1	=> ($right * $left->{'operand2'}),
			operand2	=> $right->{'operand1'}
		};
	}

	## NATURAL LOGARITHM AND EXPONENTIATION INVERSTION

	# exp(ln(f(x))) = f(x)
	if ($tree->{'operation'} =~ /^-?exp$/ && ref($left) && $left->{'operation'} =~ /^ln$/) {
		if ($tree->{'operation'} =~ /^-/) {
			return {
				operation	=> '*',
				operand1	=> "-1",
				operand2	=> $left->{'operand1'}
			};
		} else {
			return $left->{'operand1'};
		}
	}

	# ln(exp(f(x))) = f(x)
	if ($tree->{'operation'} =~ /^-?ln$/ && ref($left) && $left->{'operation'} =~ /^exp$/) {
		if ($tree->{'operation'} =~ /^-/) {
			return {
				operation	=> '*',
				operand1	=> "-1",
				operand2	=> $left->{'operand1'}
			};
		} else {
			return $left->{'operand1'};
		}
	}

	## MULTIPLICATION CHAINS BECOME POWERS

	# e * e = e^2
	if ($tree->{'operation'} eq '*' && $self->isIdentical($left, $right)) {
		return {
			operation	=> '^',
			operand1	=> $left,
			operand2	=> 2
		};
	}

	# -e * e = -(e^2)
	elsif ($tree->{'operation'} eq '*') {
		# Check if left is negative.
		if (ref $left && $left->{'operation'} =~ /^-(.+)$/) {
			$left->{'operation'} = $1;
			if ($self->isIdentical($left, $right)) {
				return {
					operation	=> '-',
					operand1	=> 0,
					operand2	=> {
						operation	=> '^',
						operand1	=> $left,
						operand2	=> 2
					}
				};
			} else {
				$left->{'operation'} = "-$1";
			}
		} elsif (!(ref $left) && $left =~ /^-(.+)$/) {
			$left = $1;
			if ($self->isIdentical($left, $right)) {
				return {
					operation	=> '-',
					operand1	=> 0,
					operand2	=> {
						operation	=> '^',
						operand1	=> $left,
						operand2	=> 2
					}
				};
			} else {
				$left = "-$1";
			}
		}
	}

	## TRIG IDENTITIES

	# cos^2 - sin^2 = 1
	if ($tree->{'operation'} eq '-' && ref $left && ref $right &&
	    $left->{'operation'} eq '^' && $right->{'operation'} eq '^' &&
	    (!ref $left->{'operand2'}) && $left->{'operand2'} == 2 &&
	    (!ref $right->{'operand2'}) && $right->{'operand2'} == 2 &&
	    ref $left->{'operand1'} && $left->{'operand1'}->{'operation'} =~ /-?cos$/ &&
	    ref $right->{'operand1'} && $right->{'operand1'}->{'operation'} =~ /-?sin$/ &&
	    $self->isIdentical($left->{'operand1'}->{'operand1'}, $right->{'operand1'}->{'operand1'})) {
		return 1;
	}

	## NO SIMPLIFICATION POSSIBLE - BUILD NEW TREE OF SIMPLIFIED SUBTREES

	# If we get here, just build and return a new tree, which may have no changes.
	return {
		operation	=> $tree->{'operation'},
		operand1	=> $left,
		operand2	=> $right
	};
}


# Evaluate tree simply subs a list of values in to numerically evaluate the tree.
# ########################################################################################
sub evaluateTree {
	# Get invocant, tree and mappings.
	my $self = shift;
	my $tree = shift;
	my %mapping = @_;

	# If we've got a numerical constant, just return it.
	if (!ref($tree) && $tree =~ /^-?\d+(\.\d+)?$/) {
		return $tree;

	# If we've got an atom, look it up in the mapping; die if we fail.
	} elsif (!ref($tree)) {
		my $val = $mapping{$tree};
		if (defined($val)) {
			return $val;
		} else {
			die; "No mapping for $tree";
		}

	#  +
	} elsif ($tree->{'operation'} eq '+') {
		return $self->evaluateTree($tree->{'operand1'}, %mapping) + $self->evaluateTree($tree->{'operand2'}, %mapping);

	#  -
	} elsif ($tree->{'operation'} eq '-') {
		return $self->evaluateTree($tree->{'operand1'}, %mapping) - $self->evaluateTree($tree->{'operand2'}, %mapping);

	#  *
	} elsif ($tree->{'operation'} eq '*') {
		return $self->evaluateTree($tree->{'operand1'}, %mapping) * $self->evaluateTree($tree->{'operand2'}, %mapping);

	#  /
	} elsif ($tree->{'operation'} eq '/') {
		return $self->evaluateTree($tree->{'operand1'}, %mapping) / $self->evaluateTree($tree->{'operand2'}, %mapping);

	#  ^
	} elsif ($tree->{'operation'} eq '^') {
		return $self->evaluateTree($tree->{'operand1'}, %mapping) ** $self->evaluateTree($tree->{'operand2'}, %mapping);

	# ln
	} elsif ($tree->{'operation'} =~ /^(-?)ln$/) {
		return ($1 ? -1 : 1) * log($self->evaluateTree($tree->{'operand1'}, %mapping));

	# exp
	} elsif ($tree->{'operation'} =~ /^(-?)exp$/) {
		return ($1 ? -1 : 1) * exp($self->evaluateTree($tree->{'operand1'}, %mapping));

	# sin
	} elsif ($tree->{'operation'} =~ /^(-?)sin$/) {
		return ($1 ? -1 : 1) * sin($self->evaluateTree($tree->{'operand1'}, %mapping));

	# cos
	} elsif ($tree->{'operation'} =~ /^(-?)cos$/) {
		return ($1 ? -1 : 1) * cos($self->evaluateTree($tree->{'operand1'}, %mapping));

	# tan
	} elsif ($tree->{'operation'} =~ /^(-?)tan$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * (sin($val) / cos($val));

	# sec
	} elsif ($tree->{'operation'} =~ /^(-?)sec$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * (1 / cos($val));

	# cosec
	} elsif ($tree->{'operation'} =~ /^(-?)cosec$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * (1 / sin($val));

	# cot
	} elsif ($tree->{'operation'} =~ /^(-?)cot$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * (cos($val) / sin($val));

	# asin
	} elsif ($tree->{'operation'} =~ /^(-?)asin$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * atan2($val, sqrt(1 - $val * $val));

	# acos
	} elsif ($tree->{'operation'} =~ /^(-?)acos$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * atan2(sqrt(1 - $val * $val), $val);

	# atan
	} elsif ($tree->{'operation'} =~ /^(-?)atan$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * atan2($val, 1);

	# sinh
	} elsif ($tree->{'operation'} =~ /^(-?)sinh$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * ((exp($val) - exp(-$val)) / 2);

	# cosh
	} elsif ($tree->{'operation'} =~ /^(-?)cosh$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * ((exp($val) + exp(-$val)) / 2);

	# tanh
	} elsif ($tree->{'operation'} =~ /^(-?)tanh$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * ((exp($val) - exp(-$val)) / (exp($val) + exp(-$val)));

	# sech
	} elsif ($tree->{'operation'} =~ /^(-?)sech$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * (2 / (exp($val) + exp(-$val)));

	# cosech
	} elsif ($tree->{'operation'} =~ /^(-?)cosech$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * (2 / (exp($val) - exp(-$val)));

	# coth
	} elsif ($tree->{'operation'} =~ /^(-?)coth$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * ((exp($val) + exp(-$val)) / (exp($val) - exp(-$val)));

	# asinh
	} elsif ($tree->{'operation'} =~ /^(-?)asinh$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * log($val + sqrt($val * $val + 1));

	# acosh
	} elsif ($tree->{'operation'} =~ /^(-?)acosh$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -1 : 1) * log($val + sqrt(($val * $val >= 1 ? $val * $val : -($val * $val)) - 1));

	# atanh
	} elsif ($tree->{'operation'} =~ /^(-?)atanh$/) {
		my $val = $self->evaluateTree($tree->{'operand1'}, %mapping);
		return ($1 ? -0.5 : 0.5) * (log(1 + $val) + log(1 - $val));

	# Otherwise, fail.
	} else {
		die "Cannot evaluate $tree->{'operation'}";
	}
}



# higherPrecedence(a, b) returns true if a has higher or equal precedence than b.
# ########################################################################################
sub higherPrecedence {
	# Get invocant and parameters.
	my ($self, $a, $b) = @_;

	# Do precedence check.
	if ($a eq '^') {
		return 1;
	} elsif ($a eq '/' && $b =~ /\/|\*|\+|-/) {
		return 1;
	} elsif ($a eq '*' && $b =~ /\*|\+|-/) {
		return 1;
	} elsif ($a eq '+' && $b =~ /\+|-/) {
		return 1;
	} elsif ($a eq '-' && $b =~ /\+|-/) {
		return 1;
	}

	# If we get here, precedence is lower.
	return 0;
}


# isConstant takes a tree and a variable, checks if it's dependent on that variable and
# returns 1 if so and 0 if not.
# ########################################################################################
sub isConstant {
	# Get invocant, variable and tree.
	my ($self, $variable, $tree) = @_;

	# If the tree is undefined, we've run off the end of it, which means it was all constant.
	return 1 unless defined($tree);

	# If we have a ref...
	if (ref $tree) {
		return ($self->isConstant($variable, $tree->{'operand1'}) && $self->isConstant($variable, $tree->{'operand2'}));
	} else {
		# Atom. But is it the variable?
		return $tree eq $variable || $tree eq "-$variable" ? 0 : 1;
	}
}


# Numeric Evaluation takes a tree and, provided it is constant and all constants are
# numeric, calculates the value of the tree. Returns undef if numeric evaluation is
# not possible.
# ########################################################################################
sub numericEvaluation {
	# Get invocant and tree.
	my ($self, $tree) = @_;

	# If the tree is a value...
	unless (ref $tree) {
		# If it's numeric, return it.
		return $tree =~ /^-?\d+(\.\d+)?$/ ? $tree : undef;
	} else {
		# Attempt to numerically evaluate each branch.
		my $leftval = $self->numericEvaluation($tree->{'operand1'});
		my $rightval = $self->numericEvaluation($tree->{'operand2'});

		# If it's an addition op and both values are numeric...
		if ($tree->{'operation'} eq '+' && defined($leftval) && defined($rightval)) {
			# Add and return.
			return $leftval + $rightval;

		# If it's a subtraction op and both values are numeric...
		} elsif ($tree->{'operation'} eq '-' && defined($leftval) && defined($rightval)) {
			# Subtract and return.
			return $leftval - $rightval;

		# If it's a multiplication op and both values are numeric...
		} elsif ($tree->{'operation'} eq '*' && defined($leftval) && defined($rightval)) {
			# Multiply and return.
			return $leftval * $rightval;

		# If it's a power op and both values are numeric...
		} elsif ($tree->{'operation'} eq '^' && defined($leftval) && defined($rightval)) {
			# Multiply and return.
			return $leftval ^ $rightval;

		# Otherwise, we can't do numerical operations. Return undef.
		} else {
			return undef;
		}
	}
}


# isIdentical takes two trees and checks if they are identical. Note that identical might
# not mean equal.
# ########################################################################################
sub isIdentical {
	# Get invocant and trees.
	my ($self, $treeA, $treeB) = @_;

	# If both are not references and they are the same...
	if (!ref($treeA) && !ref($treeB) && $treeA eq $treeB) {
		return 1;

	# If they are both references and have the same operators...
	} elsif (ref($treeA) && ref($treeB) && $treeA->{'operation'} eq $treeB->{'operation'}) {
		# Recursively compare the subtrees.
		my $leftcomp = $self->isIdentical($treeA->{'operand1'}, $treeB->{'operand1'});
		my $rightcomp = $self->isIdentical($treeA->{'operand2'}, $treeB->{'operand2'});
		return $leftcomp && $rightcomp ? 1 : 0;

	# Otherwise, they must not be the same.
	} else {
		return 0;
	}
}


# deepCopy creates a deep copy of an expression tree. You'd never have guessed, huh?
# ########################################################################################
sub deepCopy {
	# Get invocant and what is being copied.
	my ($self, $tree) = @_;

	# If it's a reference...
	if (ref $tree) {
		# Copy.
		return {
			operation	=> $tree->{'operation'},
			operand1	=> $self->deepCopy($tree->{'operand1'}),
			operand2	=> $self->deepCopy($tree->{'operand2'}),
		};
	} else {
		# Just a value. Return.
		return $tree;
	}
}


# isProperlyNested checks if the brackets in an expression are properly nested.
# ########################################################################################
sub isProperlyNested {
	# Get invocant and string to check.
	my ($self, $check) = @_;

	# Do the check.
	my $valid = 1;
	my $bracketDepth = 0;
	for (split(//, $check)) {
		$bracketDepth++ if /\(/;
		$bracketDepth-- if /\)/;
		return 0 if $bracketDepth < 0;
	}
	return $bracketDepth == 0 ? 1 : 0;
}


1;

