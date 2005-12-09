package Macro::Micro;

use warnings;
use strict;

use Carp ();

=head1 NAME

Macro::Micro - really simple templating for really simple templates

=head1 VERSION

version 0.01

 $Id$

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Macro::Micro;

  my $expander = Macro::Micro->new;

  $expander->register_macros(
    ALIGNMENT => "Lawful Good",
    HEIGHT    => sub {
      my ($macro, $object, $stash) = @_;
      $stash->{race}->avg_height;
    },
  );

  $expander->expand_macros_in($character, { race => $human_obj });

  # character is now a Lawful Good, 5' 6" human

=head1 DESCRIPTION

This module performs very basic expansion of macros in text, with a very basic
concept of context and lazy evaluation.

=head1 METHODS

=head2 C<new>

  my $expander = Macros::Micro->new(%arg);

This method creates a new macro expander.

There is only one valid argument:

  macro_format - this is the format for macros; see the macro_format method

=cut

my $DEFAULT_MACRO_FORMAT = qr/(?<!\\)([\[<] (\w+) [>\]])/x;

sub new {
  my ($class, %arg) = @_;

  my $self = bless { } => $class;

  $arg{macro_format} = $DEFAULT_MACRO_FORMAT unless $arg{macro_format};

  $self->macro_format($arg{macro_format});

  return $self;
}

=head2 C<macro_format>

  $expander->macro_format( qr/.../ );

This method returns the macro format regexp for the expander.  It must be a
reference to a regular expression, and should have two capture groups.  The
first should return the entire string to be replaced in the text, and the
second the name of the macro found.

The default macro format is:  C<< qr/([\[<] (\w+) [>\]])/x >>

In other words: a probably-valid-identiifer inside angled or square backets.

=cut

sub macro_format {
  my $self = shift;

  return $self->{macro_format} unless @_;

  my $macro_format = shift;
  Carp::croak "macro format must be a regexp reference"
    unless ref $macro_format eq 'Regexp';

  $self->{macro_format} = $macro_format;
}

=head2 C<register_macros>

  $expander->register_macros($name => $value, ... );

This method register one or more macros for later expansion.  The macro names
must be either strings or a references to regular expression.  The values may
be either strings or references to code.

These macros may later be used for expansion by C<L</expand_macros>>.

=cut

sub register_macros {
  my ($self, @macros) = @_;

  while (@macros) {
    my ($name, $value) = splice @macros, 0, 2;
    Carp::croak "macro value must be a string or code reference"
      if (ref $value) and (ref $value ne 'CODE');

    if (not ref $name) {
      $self->{macro}{$name} = $value;
    } elsif (ref $name eq 'Regexp') {
      $self->{macro_regexp}{$name} = [ $name, $value ];
    } else {
      Carp::croak "macro name '$name' must be a string or regexp reference";
    }
  }

  return $self;
}

=head2 C<get_macro>

  my $macro = $expander->get_macro($macro_name);

This returns the currently-registered value for the named macro.  If the given
macro name is not registered exactly, the name is checked against any regular
expression macros that are registered.  The first of these to match is
returned.

At present, the regular expression macros are checked in an arbitrary order.

=cut

sub get_macro {
  my ($self, $macro_name) = @_;

  return $self->{macro}{$macro_name} if exists $self->{macro}{$macro_name};

  foreach my $regexp (values %{ $self->{macro_regexp} }) {
    return $regexp->[1] if $macro_name =~ $regexp->[0];
  }

  return;
}

=head2 C<expand_macros>

  my $rewritten = $expander->expand_macros($text, \%stash);

This method returns the result of rewriting the macros found the text.  The
stash is a set of data that may be used to expand the macros.

The text is scanned for content matching the expander's L</macro_format>.  If
found, the macro name in the found content is looked up with C<L</get_macro>>.
If a macro is found, it is used to replace the found content in the text.

A macros whose value is text is expanded into that text.  A macros whose value
is code is expanded by calling the code as follows:

 $replacement = $macro_value->($macro_name, $text, \%stash);

Macros are not expanded recursively.

=cut

sub expand_macros {
  my ($self, $object, $stash) = @_;

  $self->fast_expander($stash)->($object);
}

=head2 C<expand_macros_in>

  $expander->expand_macros_in($object, \%stash);

This rewrites the content of C<$object> in place, using the expander's macros
and the provided stash of data.

At present, only scalar references can be rewritten in place.  In the future,
there will be a system to define how various classes of objects should be
rewritten in place, such as email messages.

=cut

sub expand_macros_in {
  my ($self, $object, $stash) = @_;

  Carp::croak "object of in-place expansion must be a scalar reference"
    if (not ref $object)
    or (ref $object ne 'SCALAR');

  my $fast_expander = $self->fast_expander($stash);

  $$object = $fast_expander->($$object);
}

=head2 C<fast_expander>

  my $fast_expander = $expander->fast_expander($stash);

  my $rewritten_text = $fast_expander->($original_text);

This method returns a closure which will expand the macros in text passed to
it using the expander's macros and the passed-in stash.

=cut

sub fast_expander {
  my ($self, $stash) = @_;

  my $regex = $self->macro_format;

  my $applicator = sub {
    my ($object) = @_;

    return unless defined $object;
    Carp::croak "object of expansion must not be a reference" if ref $object;

    my $expander = sub {
      my $macro = $self->get_macro($_[1]);
      return $_[0] unless $macro;
      return ref $macro ? $macro->($_[1], $object, $stash) : $macro;
    };

    $object =~ s/$regex/$expander->($1,$2)/eg;

    return $object;
  }
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-macro-micro@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"[MAGIC_TRUE_VALUE]";
