#!perl -T

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Macro::Micro'); }
BEGIN { use_ok('Macro::Micro::perl56'); }

my $text = <<END_TEXT;
  I enjoy drinking <SILENCE>[FAVORITE_BEVERAGE].
  My turn-ons include [TURN_ONS] but not [TURN_OFFS].

  My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

  <SECRET_YOUR_FACE>
  SNXBLORT
END_TEXT

for my $module (qw(Macro::Micro Macro::Micro::perl56)) {
  my $expander = $module->new;

  my $template = $expander->study($text);

  {
    my @macros = (
      FAVORITE_BEVERAGE => sub { "hot tea" },
      TURN_ONS          => "50,000 volts",
      TURN_OFFS         => "electromagnetic pulses",
      qr/SECRET_\w+/    => sub { "(secret macro! $_[0]!)" },
      AREA_OF_FLATHEAD  => sub { ($_[2]->{edge}||0) ** 2 },
      SILENCE           => '',
    );

    my $filled_in = $expander->register_macros(@macros)->expand_macros(
      $template,
      { edge=>2 }
    );

    my $expected = <<END_TEXT;
  I enjoy drinking hot tea.
  My turn-ons include 50,000 volts but not electromagnetic pulses.

  My head, which is flat, is 4 square inches in area.

  (secret macro! SECRET_YOUR_FACE!)
  SNXBLORT
END_TEXT

    is($filled_in, $expected, "we filled in a studied string");
  }
}
