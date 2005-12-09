#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Macro::Expander'); }

my $format = qr/(\{\s*(\w+)\s*\})/;

my $expander = Macro::Expander->new(macro_format => $format);

isa_ok($expander, 'Macro::Expander');

can_ok($expander, 'register_macros');

$expander->register_macros(
  FAVORITE_BEVERAGE => sub { "hot tea" },
  TURN_ONS          => "50,000 volts",
  TURN_OFFS         => "electromagnetic pulses",
  qr/SECRET_\w+/    => sub { "(secret macro! $_[0]!)" },
  AREA_OF_FLATHEAD  => sub { ($_[2]->{edge}||0) ** 2 },
);

my $text_square = <<END_TEXT;
I enjoy drinking [FAVORITE_BEVERAGE].
My turn-ons include [TURN_ONS] but not [TURN_OFFS].

My head, which is flat, is [AREA_OF_FLATHEAD] square inches in area.

<SECRET_YOUR_FACE>
END_TEXT

my $text_squiggly = <<END_TEXT;
I enjoy drinking {FAVORITE_BEVERAGE}.
My turn-ons include {TURN_ONS   } but not {   TURN_OFFS}.

My head, which is flat, is {  AREA_OF_FLATHEAD  } square inches in area.

{SECRET_YOUR_FACE}
END_TEXT

my $translated = <<END_TEXT;
I enjoy drinking hot tea.
My turn-ons include 50,000 volts but not electromagnetic pulses.

My head, which is flat, is 4 square inches in area.

(secret macro! SECRET_YOUR_FACE!)
END_TEXT

my $orig_square = $text_square;
$expander->expand_macros_in(\$text_square, { edge => 2 });
is($text_square, $orig_square, "square brackets ignored with of new format");

$expander->expand_macros_in(\$text_squiggly, { edge => 2 });
is($text_squiggly, $translated, "expansion worked as planned");
