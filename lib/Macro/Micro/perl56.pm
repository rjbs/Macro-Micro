package Macro::Micro::perl56;
use base qw(Macro::Micro);

use warnings;
use strict;

use Carp ();

=head1 NAME

Macro::Micro::perl56 - micro macros for perl 5.6

=head1 VERSION

 $Id: /my/icg/macexp/trunk/lib/Macro/Micro.pm 17183 2005-12-10T00:39:55.084057Z rjbs  $

=head1 DESCRIPTION

Macro::Micro::perl56 implements a subset of Macro::Micro that does not leak
insane amounts of memory on 5.6.x perls.  If you are going to use Macro::Micro
on perl 5.6.x, you should use Macro::Micro::perl56.

The main difference is that the C<fast_expander> method from Macro::Micro is
implemented in terms of C<expand_macros> as opposed to the other way around.
Also, C<fast_expander> is not actually faster than C<expand_macros>.

While this is less efficient, it will I<not> leak huge heaps of memory, which
is a nice benefit.

=cut

sub expand_macros {
  my ($self, $object, $stash) = @_;

  my $regex = $self->macro_format;

  return unless defined $object;
  Carp::croak "object of expansion must not be a reference" if ref $object;

  my $expander = sub {
    my $macro = $self->get_macro($_[1]);
    return $_[0] unless $macro;
    return ref $macro ? $macro->($_[1], $object, $stash)||'' : $macro;
  };

  $object =~ s/$regex/$expander->($1,$2)/eg;

## I was afraid I'd have to further unroll the above into the following to
## eliminate memory problems in 5.6.1; this didn't happen, but I'm leaving this
## here for future reference, just in case!
#  $object =~ s/$regex/
#               my $macro = $self->get_macro($2);
#               $macro ? (ref $macro ? $macro->($2, $object, $stash) : $macro)
#                      : ''/eg;

  return $object;
}

sub expand_macros_in {
  my ($self, $object, $stash) = @_;

  Carp::croak "object of in-place expansion must be a scalar reference"
    if (not ref $object)
    or (ref $object ne 'SCALAR');

  $$object = $self->expand_macros($$object, $stash);
}

sub fast_expander {
  my ($self, $stash) = @_;
  return sub { $self->expand_macros($_[0], $stash) };
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
