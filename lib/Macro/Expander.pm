package Macro::Expander;

use warnings;
use strict;

use Carp ();

=head1 NAME

Macro::Expander - really simple templating for really simple templates

=head1 VERSION

version 0.01

 $Id$

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Macro::Expander;

  my $expander = Macro::Expander->new;

  $expander->register_macros(
    ALIGNMENT => "Lawful Good",
    HEIGHT    => sub {
      my ($macro, $object, $stash) = @_;
      $stash->{race}->avg_height;
    },
  );

  $expander->expand_macros_in($character);

  # character is now a Lawful Good, 5' 6" human

=head1 DESCRIPTION

This module performs very basic expansion of macros in text, with a very basic
concept of context and lazy evaluation.

=head1 METHODS

=head2 C<new>

  my $expander = Macros::Expander->new(%arg);

This method creates a new macro expander.

There is only one valid argument:

  macro_format - this is the format for macros; see the macro_format method

=cut

my $DEFAULT_MACRO_FORMAT = qr/([\[<] (\w+) [>\]])/x;

sub new {
  my ($class, %arg) = @_;

  my $self = bless { } => $class;

  $arg{macro_format} = $DEFAULT_MACRO_FORMAT unless $arg{macro_format};

  $self->macro_format($arg{macro_format});

  return $self;
}

=head2 C<macro_format>

  $expander->macro_format( qr/.../ );

This method returns the macro format regexp for the expander.

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
}

=head2 C<get_macro>

  my $macro = $expander->get_macro($macro_name);

This returns the currently-registered value for the named macro.

=cut

sub get_macro {
  my ($self, $macro_name) = @_;

  return $self->{macro}{$macro_name} if exists $self->{macro}{$macro_name};

  foreach my $regexp (values %{ $self->{macro_regexp} }) {
    return $regexp->[1] if $macro_name =~ $regexp->[0];
  }

  return;
}

=head2 C<fast_expander>

  my $fast_expander = $expander->fast_expander($stash);

This method returns a closure which will expand the macros in text passed to
it.

=cut

sub fast_expander {
  my ($self, $stash) = @_;

  my $regex = $self->macro_format;

  my $applicator = sub {
    my ($object) = @_;

    Carp::croak "object of expansion must be a defined, non-reference scalar"
      if not(defined $object) or ref $object;

    while (my ($match, $macro_name) = $object =~ m/$regex/gc) {
      next unless my $macro = $self->get_macro($macro_name);

      my $expansion
        = ref $macro ? $macro->($macro_name, $object, $stash) : $macro;

      $object =~ s/\Q$match\E/$expansion/;
    }
    return $object;
  }
}

=head2 C<expand_macros_in>

  $expander->expand_macros_in($object, \%stash);

This rewrites the content of C<$object> in place, using the expander's macros
and the provided stash of data.

=cut

sub expand_macros_in {
  my ($self, $object, $stash) = @_;

  Carp::croak "object of in-place expansion must be a scalar reference"
    if (not ref $object)
    or (ref $object ne 'SCALAR');

  my $fast_expander = $self->fast_expander($stash);

  $$object = $fast_expander->($$object);
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-macro-expander@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"[MAGIC_TRUE_VALUE]";
