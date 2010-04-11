use inc::Module::Install;

if ($Module::Install::AUTHOR) {
    system('pod2text lib/CyberSource/SOAP/Checkout.pm > README');
    system('pod2html lib/CyberSource/SOAP/Checkout.pm > README.html');
}

name 'CyberSource-SOAP-Checkout';
all_from 'lib/CyberSource/SOAP/Checkout.pm';
test_requires 'Test::More';
auto_include_deps;
auto_install;
tests 't/*.t';
repository 'http://github.com/amiri/CyberSource--SOAP--Checkout';

WriteAll;
