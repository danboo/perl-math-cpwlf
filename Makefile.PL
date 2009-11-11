use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Math::CPWLF',
    AUTHOR              => q{Dan Boorstein <dan@boorstein.net>},
    VERSION_FROM        => 'lib/Math/CPWLF.pm',
    ABSTRACT_FROM       => 'lib/Math/CPWLF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Math-CPWLF-*' },
);
