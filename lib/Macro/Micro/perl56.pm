package Macro::Micro::perl56;
use base qw(Macro::Micro);

use warnings;
use strict;

use Carp ();

=head1 NAME

Macro::Micro::perl56 - micro macros for perl 5.6

=head1 VERSION

version 0.02

 $Id: /my/icg/macexp/trunk/lib/Macro/Micro.pm 17183 2005-12-10T00:39:55.084057Z rjbs  $

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Macro::Micro:perl56;

  my $expander = Macro::Micro::perl56->new;

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

  my $regex = $self->macro_format;

  return unless defined $object;
  Carp::croak "object of expansion must not be a reference" if ref $object;

  my $expander = sub {
    my $macro = $self->get_macro($_[1]);
    return $_[0] unless $macro;
    return ref $macro ? $macro->($_[1], $object, $stash) : $macro;
  };

  $object =~ s/$regex/$expander->($1,$2)/eg;

#  $object =~ s/$regex/
#               my $macro = $self->get_macro($2);
#               $macro ? (ref $macro ? $macro->($2, $object, $stash) : $macro)
#                      : ''/eg;

  return $object;
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

  $$object = $self->expand_macros($$object, $stash);
}

=head2 C<fast_expander>

  my $fast_expander = $expander->fast_expander($stash);

  my $rewritten_text = $fast_expander->($original_text);

This method returns a closure which will expand the macros in text passed to
it using the expander's macros and the passed-in stash.

=cut

sub fast_expander {
  Carp::croak "Macro::Micro::perl56 cannot provide a fast expander";
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
