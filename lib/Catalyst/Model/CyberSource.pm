package Catalyst::Model::CyberSource;

use Moose;
use SOAP::Lite;
use Time::HiRes qw/gettimeofday/;
use namespace::autoclean;

extends 'Catalyst::Model';

has 'response' => (
    is      => 'rw',
    isa     => 'Catalyst::Model::CyberSource::Response',
    lazy => 1,
    builder => '_get_response',
);

has 'test_server' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ics2wstest.ic3.com',
);

has 'prod_server' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ics2ws.ic3.com',

);

has 'cybs_version' => (
    is      => 'ro',
    isa     => 'Str',
    default => '1.26',
);

has 'wsse_nsuri' => (
    is  => 'ro',
    isa => 'Str',
    default =>
        'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
);

has 'wsse_prefix' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'wsse',
);

has 'password_text' => (
    is  => 'ro',
    isa => 'Str',
    default =>
        'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText',
);

has 'refcode' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { return join( '', Time::HiRes::gettimeofday ) }
);

has 'agent' => (
    is      => 'ro',
    isa     => 'SOAP::Lite',
    lazy    => 1,
    builder => '_get_agent',
);

sub _get_agent {
    my $self = shift;
    return SOAP::Lite->uri( 'urn:schemas-cybersource-com:transaction-data-'
            . $self->cybs_version )
        ->proxy( 'https://'
            . $self->test_server
            . '/commerce/1.x/transactionProcessor' )->autotype(0);
}

sub _get_response {
    my $self = shift;
    return Catalyst::Model::CyberSource::Response->new;
}


sub addField {
    my ( $parentRef, $name, $val ) = @_;
    push( @$parentRef, SOAP::Data->name( $name => $val ) );
}

sub addComplexType {
    my ( $parentRef, $name, $complexTypeRef ) = @_;
    addField( $parentRef, $name, \SOAP::Data->value(@$complexTypeRef) );
}

sub addItem {
    my ( $parentRef, $index, $itemRef ) = @_;
    my %attr;
    push( @$parentRef,
        SOAP::Data->name( item => \SOAP::Data->value(@$itemRef) )
            ->attr( { ' id' => $index } ) );
}

sub addService {
    my ( $parentRef, $name, $serviceRef, $run ) = @_;
    push( @$parentRef,
        SOAP::Data->name( $name => \SOAP::Data->value(@$serviceRef) )
            ->attr( { run => $run } ) );
}

sub formSOAPHeader {
    my $self = shift;
    my %tokenHash;
    $tokenHash{Username}
        = SOAP::Data->type( '' => $self->id )->prefix( $self->wsse_prefix );
    $tokenHash{Password}
        = SOAP::Data->type( '' => $self->key )
        ->attr( { 'Type' => $self->password_text } )
        ->prefix( $self->wsse_prefix );

    my $usernameToken = SOAP::Data->name( 'UsernameToken' => {%tokenHash} )
        ->prefix( $self->wsse_prefix );

    my $header
        = SOAP::Header->name( Security =>
            { UsernameToken => SOAP::Data->type( '' => $usernameToken ) } )
        ->uri( $self->wsse_nsuri )->prefix( $self->wsse_prefix );

    return $header;
}

sub process {
    my ( $self, $args ) = @_;
    $args->{refcode} = $self->refcode;
    #print STDERR Dumper $args;

    my $header = $self->formSOAPHeader();
    my @request;

    

    addField( \@request, 'merchantID',            $self->id );
    addField( \@request, 'merchantReferenceCode', $args->{refcode} );
    addField( \@request, 'clientLibrary',         'Perl' );
    addField( \@request, 'clientLibraryVersion',  "$]" );
    addField( \@request, 'clientEnvironment',     "$^O" );

    my @billTo;
    addField( \@billTo, 'firstName',  $args->{firstname} );
    addField( \@billTo, 'lastName',   $args->{lastname} );
    addField( \@billTo, 'street1',    $args->{address1} );
    addField( \@billTo, 'city',       $args->{city} );
    addField( \@billTo, 'state',      $args->{state} );
    addField( \@billTo, 'postalCode', $args->{zip} );
    addField( \@billTo, 'country',    $args->{country} );
    addField( \@billTo, 'email',      $args->{email} );
    addField( \@billTo, 'ipAddress',  $args->{ip} );
    addComplexType( \@request, 'billTo', \@billTo );

    my @item;
    addField( \@item, 'unitPrice', $args->{amount} );
    addField( \@item, 'quantity',  $args->{quantity} );
    addItem( \@request, '0', \@item );

    my @purchaseTotals;
    addField( \@purchaseTotals, 'currency', $args->{currency} );
    addComplexType( \@request, 'purchaseTotals', \@purchaseTotals );

    my @card;
    addField( \@card, 'accountNumber',   $args->{cardnumber} );
    addField( \@card, 'expirationMonth', $args->{'expiry.month'} );
    addField( \@card, 'expirationYear',  $args->{'expiry.year'} );
    addComplexType( \@request, 'card', \@card );

    my @ccAuthService;
    addService( \@request, 'ccAuthService', \@ccAuthService, 'true' );
    my $reply = $self->agent->call( 'requestMessage' => @request, $header );
    return $self->response->respond($reply,$args);
}

1;
