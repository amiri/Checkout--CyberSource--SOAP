package CyberSource::SOAP::Checkout;

use Moose;
use SOAP::Lite;
use Time::HiRes qw/gettimeofday/;
use namespace::autoclean;

use 5.008_001;
our $VERSION = '0.01';

extends 'Catalyst::Model';

has 'id' => (
    is  => 'ro',
    isa => 'Str',
);

has 'key' => (
    is  => 'ro',
    isa => 'Str',
);

has 'production' => (
    is => 'ro',
    isa => 'Bool',
);

has 'column_map' => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
);

has 'response' => (
    is      => 'rw',
    isa     => 'CyberSource::SOAP::Checkout::Response',
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
            . ( $self->production ? $self->prod_server : $self->test_server  )
            . '/commerce/1.x/transactionProcessor' )->autotype(0);
}

sub _get_response {
    my $self = shift;
    return CyberSource::SOAP::Checkout::Response->new;
}

sub addField {
    my ( $self, $parentRef, $name, $val ) = @_;
    push( @$parentRef, SOAP::Data->name( $name => $val ) );
}

sub addComplexType {
    my ( $self, $parentRef, $name, $complexTypeRef ) = @_;
    $self->addField( $parentRef, $name,
        \SOAP::Data->value(@$complexTypeRef) );
}

sub addItem {
    my ( $self, $parentRef, $index, $itemRef ) = @_;
    my %attr;
    push( @$parentRef,
        SOAP::Data->name( item => \SOAP::Data->value(@$itemRef) )
            ->attr( { ' id' => $index } ) );
}

sub addService {
    my ( $self, $parentRef, $name, $serviceRef, $run ) = @_;
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

    my $header = $self->formSOAPHeader();
    my @request;

    $self->addField( \@request, 'merchantID',            $self->id );
    $self->addField( \@request, 'merchantReferenceCode', $self->refcode );
    $self->addField( \@request, 'clientLibrary',         'Perl' );
    $self->addField( \@request, 'clientLibraryVersion',  "$]" );
    $self->addField( \@request, 'clientEnvironment',     "$^O" );

    my @billTo;
    $self->addField( \@billTo, $_, $args->{$self->column_map->{$_}}) for qw/firstName lastName street1 city state postalCode country email ipAddress/;
    $self->addComplexType( \@request, 'billTo', \@billTo );

    my @item;
    $self->addField( \@item, $_, $args->{$self->column_map->{$_}}) for qw/unitPrice quantity/;
    $self->addItem( \@request, '0', \@item );

    my @purchaseTotals;
    $self->addField( \@purchaseTotals, 'currency', $args->{$self->column_map->{currency}} );
    $self->addComplexType( \@request, 'purchaseTotals', \@purchaseTotals );

    my @card;
    $self->addField( \@card, $_, $args->{$self->column_map->{$_}}) for qw/accountNumber expirationMonth expirationYear/;
    $self->addComplexType( \@request, 'card', \@card );

    my @ccAuthService;
    $self->addService( \@request, 'ccAuthService', \@ccAuthService, 'true' );
    my $reply = $self->agent->call( 'requestMessage' => @request, $header );
    return $self->response->respond( $reply, $args );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

CyberSource::SOAP::Checkout - A Modern Perl interface to CyberSource's SOAP API.

=head1 SYNOPSIS

This is for single transactions of variable quantity.

You can use this as a standalone module by sending it a payment information hashref. You will receive a C::S::Checkout::Response object containing either a success message or an error message. If successful, you will also receive a payment_info hashref, suitable for storing in your database.

You must map the keys in the hashref you send (which also sets the keys for the payment_info hashref you receive back). CyberSource uses camelCased and otherwise idiosyncratic identifiers here, so this mapping cannot be avoided.

You can use this in a Catalyst application by using Catalyst::Model::Adaptor and setting your configuration file somewhat like this:

    <Model::Checkout>
        class   CyberSource::SOAP::Checkout
        <args>
            id  your_cybersource_id
            key your cybersource_key
            #production  1
            <column_map>
                firstName		firstname
                lastName		lastname
                street1		    address1
                city    		city
                state	    	state
                postalCode	    zip
                country         country
                email           email
                ipAddress		ip
                unitPrice		amount
                quantity		quantity
                currency		currency
                accountNumber	cardnumber
                expirationMonth	expiry.month
                expirationYear	expiry.year
            </column_map>
        </args>
    </Model::Checkout>

So that in your payment processing controller you would get validated data back from a shopping cart or other form and do something like this:
    
    # If your checkout form is valid, call C::S::Checkout's process method:

    my $response = $c->model('Checkout')->process( $c->req->params );


    # Check the response object, branch accordingly.

    if ( $response->success ) {

        # Store a payment in your database

        my $payment = $c->model('Payment')->create($response->payment_info);

        $c->flash( status_msg => $response->success->{message} );
        $c->res->redirect($c->uri_for('/Yay! Money!')); # Don't do this.
    
    }
    
    else {
        $c->stash( error_msg => $response->error->{message} );
        return;
    }


=head1 WHY?

Folks often have a need for simple and quick, but "enterprise-level" payment-gateway integration. CyberSource's Simple Order API still requires that you compile a binary, and it won't compile on 64-bit processors (no, not OSes, but processors, i.e., what I imagine to be most development workstations by now). So you have to use the SOAP API, which is unwieldy, not least because it uses XML. May no one struggle with this again.  :)

=head1 AUTHOR

Amiri Barksdale E<lt>amiri@metalabel.comE<gt>

=head1 CONTRIBUTORS

Tomas Doran (t0m) E<lt>bobtfish@bobtfish.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catalyst::Model::Adaptor> L<Business::OnlinePayment::CyberSource>

=cut
