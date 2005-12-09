use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Macro::Micro',
    AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Macro/Micro.pm',
    ABSTRACT_FROM       => 'lib/Macro/Micro.pm',
    PL_FILES            => {},
    PREREQ_PM => {
      'Carp'       => 0,
      'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Macro-Micro-* cover_db' },
);
