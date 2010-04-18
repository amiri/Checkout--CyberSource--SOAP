
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Checkout::CyberSource::SOAP',
                       'DISTNAME' => 'Checkout-CyberSource-SOAP',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Amiri Barksdale <amiri@metalabel.com>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'A Modern Perl interface to CyberSource\'s SOAP API.',
                       'EXE_FILES' => [],
                       'VERSION' => '0.01',
                       'PREREQ_PM' => {
                                        'SOAP::Lite' => '0',
                                        'Business::CreditCard' => '0',
                                        'namespace::autoclean' => '0',
                                        'Crypt::SSLeay' => '0',
                                        'Time::HiRes' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



