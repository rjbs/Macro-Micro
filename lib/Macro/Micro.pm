package Macro::Micro;

use warnings;
use strict;

use Carp ();

=head1 NAME

Macro::Micro - really simple templating for really simple templates

=head1 VERSION

version 0.04

 $Id$

=cut

our $VERSION = '0.04';

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

=head2 new

  my $expander = Macro::Micro->new(%arg);

This method creates a new macro expander.

There is only one valid argument:

  macro_format - this is the format for macros; see the macro_format method

Because of memory leaks in perl 5.6, this method will return a
Macro::Micro::perl56 object instead of a Macro::Micro object under versions
prior to 5.8.

=cut

my $DEFAULT_MACRO_FORMAT = qr/(?<!\\)([\[<] (\w+) [>\]])/x;

sub new {
  my ($class, %arg) = @_;

  if (($class eq 'Macro::Micro') && ($] < 5.008)) {
    require Macro::Micro::perl56;
    $class = 'Macro::Micro::perl56';
  }

  my $self = bless { } => $class;

  $arg{macro_format} = $DEFAULT_MACRO_FORMAT unless $arg{macro_format};

  $self->macro_format($arg{macro_format});

  return $self;
}

=head2 macro_format

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

=head2 register_macros

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
      Carp::croak "macro name '$name' must be a string or a regexp";
    }
  }

  return $self;
}

=head2 clear_macros

  $expander->clear_macros;

This method clears all registered macros.

=cut

sub clear_macros {
  my ($self, @macros) = @_;

  if (@macros) {
    Carp::croak "partial deletion not implemented";
  } else {
    delete @$self{qw(macro macro_regexp)};
  }

  return;
}

=head2 get_macro

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

=head2 expand_macros

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

  if (eval { $object->isa('Macro::Micro::Template') }) {
    return $self->_expand_template($object, $stash);
  }

  $self->fast_expander($stash)->($object);
}

sub _expand_template {
  my ($self, $object, $stash) = @_;
  # expects to be passed ($whole_macro, $macro_inside_delim, $whole_text)
  my $expander = sub {
    my $macro = $self->get_macro($_[1]);
    return $_[0] unless defined $macro;
    return ref $macro ? $macro->($_[1], $_[2], $stash)||'' : $macro;
  };

  return join '', map { ref $_ ? $expander->(@$_[0, 1], $object->_text) : $_ }
                  $object->_parts;
}

=head2 expand_macros_in

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

=head2 fast_expander

  my $fast_expander = $expander->fast_expander($stash);

  my $rewritten_text = $fast_expander->($original_text);

This method returns a closure which will expand the macros in text passed to
it using the expander's macros and the passed-in stash.

=cut

sub fast_expander {
  my ($self, $stash) = @_;

  my $regex = $self->macro_format;

  # expects to be passed ($whole_macro, $macro_inside_delim, $whole_text)
  my $expander = sub {
    my $macro = $self->get_macro($_[1]);
    return $_[0] unless defined $macro;
    return ref $macro ? $macro->($_[1], $_[2], $stash)||'' : $macro;
  };

  my $applicator = sub {
    my ($object) = @_;

    return unless defined $object;
    Carp::croak "object of expansion must not be a reference" if ref $object;

    $object =~ s/$regex/$expander->($1,$2,$object)/eg;

    return $object;
  }
}

=head2 study

  my $template = $expander->study($text);

Given a string, this returns an object which can be used as an argument to
C<expand_macros>.  Macro::Micro will find and mark the locations of macros in
the text so that calls to expand the macros will not need to search the text.

=cut

sub study {
  my ($self, $text) = @_;

  my $macro_format = $self->macro_format;

  my @total;

  my $pos;
  while ($text =~ m/\G(.*?)$macro_format/gsm) {
    my ($snippet, $whole, $name) = ($1, $2, $3);
    push @total, (length $snippet ? $snippet : ()),
                 ($whole ? [ $whole, $name ] : ());
    $pos = pos $text;
  }

  push @total, substr $text, $pos if defined $pos;

  return Macro::Micro::Template->_new(\$text, \@total);
}

{
  package Macro::Micro::Template;
  sub _new   { bless [ $_[1], $_[2] ] => $_[0] }
  sub _parts { @{ $_[0][1] } }
  sub _text  {    $_[0][0]   }
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-macro-micro@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2005-2006 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"[MAGIC_TRUE_VALUE]";
