use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Model::CyberSource',
    AUTHOR              => q{Amiri Barksdale <amiri@metalabel.com>},
    VERSION_FROM        => 'lib/Catalyst/Model/CyberSource.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Model/CyberSource.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Model-CyberSource-*' },
);
