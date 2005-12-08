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

  my $expander = Macros::Expander->new;

This method creates a new macro expander.

=cut

sub new {
  my ($class) = @_;
  bless {} => $class;
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
      Carp::croak "macro name '$name' must be a string or regex reference";
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

  my $applicator = sub {
    my ($object) = @_;

    while (my ($match, $macro_name) = $object =~ /([\[<] (\w+) [>\]])/x) {
      next unless my $macro = $self->get_macro($macro_name);

      my $expansion
        = ref $macro ? $macro->($macro_name, $object, $stash) : $macro;

      $object =~ s/\Q$match\E/$expansion/;
    }
    return $object;
  }
}

=head2 C<expand_macros_in>

=cut

sub expand_macros_in {
  my ($self, $object, $stash) = @_;

  Carp::croak "object of expansion must be a scalar reference"
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