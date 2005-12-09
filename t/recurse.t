#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Macro::Expander'); }

my $expander = Macro::Expander->new;

$expander->register_macros(
  FOO => "[BAR]",
  BAR => "[FOO]",
  BAZ => "[BAZ]",
  OOO => "[FOO][BAR]",
);

my $text = <<END_TEXT;
[FOO][BAR][OOO][BAZ]
END_TEXT

my $expected = <<END_TEXT;
[BAR][FOO][FOO][BAR][BAZ]
END_TEXT

is(
  $expander->expand_macros($text),
  $expected,
  "we get no stupid recursive expansion",
);

