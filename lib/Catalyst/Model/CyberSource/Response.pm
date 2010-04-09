package Catalyst::Model::CyberSource::Response;

use Moose;
use Business::CreditCard;
use namespace::autoclean;

has 'error' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has 'payment_info' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'success' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

has 'handler' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        return {
            100 => \&successful,  ### Success
            101 => \&missing,     ### Missing info
            102 => \&invalid,     ### Invalid field data
            150 => \&sysfail,     ### System failure
            151 => \&servertime,  ### Server timeout
            152 => \&servicetime, ### Service timeout
            200 => \&addressver,  ### Address verification failed
            201 => \&verbconf,    ### Call bank, verbal communication required
            202 => \&expiry,      ### Card expred or expiry doesn't match
            203 => \&gendecline,  ### General card decline by BANK
            204 => \&nsf,         ### Insufficient funds
            205 => \&stolen,      ### Stolen or lost card
            207 => \&lunch,       ### Bank unavailable to approve request
            208 => \&present,     ### Unactivated/unauth for card-not-present
            209 => \&amexcid,     ### AMEX CID mismatch
            210 => \&limit,       ### Card maxed out
            211 => \&cid,         ### CID mismatch
            221 => \&badclient,   ### Customer flagged in bank DB
            230 => \&cv,          ### Bank approves, Cybersource doesn't
            231 => \&badnum,      ### Invalid account number
            232 => \&proctype,    ### Processor doesn't accept card type
            233 => \&procdecline, ### General card decline by PROCESSOR
            234 => \&merchprob,   ### Merchant account misconfigured
            235 => \&toomuch,     ### Capturing more than authorized
            236 => \&procfail,    ### Processor failure
            237 => \&authrev,     ### Authorization already reversed
            238 => \&authcap,     ### Authorization already captured
            239 => \&prevtrans,   ### Trans. must match prev. trans. amount
            240 => \&card_type,   ### Card invalid or doesn't match number
            241 => \&reqval,      ### Request ID invalid
            242 => \&badcap,      ### Unsuccessful auth or auth used already
            243 => \&transrev,    ### Transaction already settled or reversed
            246 => \&novoid,      ### Can't void capture/credit: already done
            247 => \&voided,      ### Capture was voided
            250 => \&proctime,    ### Processor timeout
        };
    },
);

sub respond {
    my ( $self, $reply, $args ) = @_;

    unless ( $reply->fault ) {
        if ( $reply->match('//Body/replyMessage') ) {    ### IF REPLY

            if ( exists $self->handler->{ $reply->valueof('reasonCode') } ) {

                if ( $reply->valueof('reasonCode') == 100 ) {
                    my @payment_cols = qw/
                        address1 amount card_type
                        city country decision email
                        expmonth expyear firstname
                        ip lastname postcode
                        reasoncode refcode state
                        /;

                    @{ $self->payment_info }{@payment_cols} = (
                        $args->{address1},
                        $args->{amount},
                        Business::CreditCard::cardtype( $args->{cardnumber} ),
                        $args->{city},
                        $args->{country},
                        $reply->valueof('decision'),
                        $args->{email},
                        $args->{'expiry.month'},
                        $args->{'expiry.year'},
                        $args->{firstname},
                        $args->{ip},
                        $args->{lastname},
                        $args->{zip},
                        $reply->valueof('reasonCode'),
                        $args->{refcode},
                        $args->{state}
                    );
                }
                $self->success->{message}
                    = $self->handler->{ $reply->valueof('reasonCode') }->(
                    $self,
                    $reply->valueof('reasonCode'),
                    $reply->valueof('decision')
                    );
            }
            else {
                return $self->DEFAULT( $reply->valueof('reasonCode'),
                    $reply );
            }
        }
        else {    ### IF NO REPLY
            return $self->EMPTY;
        }
    }
    else {        ### IF FAULT
        ( my $fault = $reply->faultstring ) =~ s/\n//g;
        return $self->FAULT( $fault, $reply );
    }
    return $self;
}

sub successful {
    my ( $self, $code, $decision, $args ) = @_;
    return 'Successful transaction';
}

sub missing {
    my $self = shift;

    return
        "You have omitted necessary information. Please check your form and try again.";
}

sub invalid {
    my $self = shift;

    return
        "You have submitted invalid information. Please check your form and try again.";
}

sub sysfail {
    my $self = shift;

    return "System error. Please wait a few minutes and try again.";
}

sub servertime {
    my $self = shift;

    return "Server timeout. Please wait a few minutes and try again.";
}

sub servicetime {
    my $self = shift;

    return "Service timeout. Please wait a few minutes and try again.";
}

sub addressver {
    my $self = shift;

    return
        "Your address was rejected. Please check your address or try another card.";
}

sub verbconf {
    my $self = shift;

    return
        "<div class='notice'><h5>Your purchase requires verbal confirmation. You do not need to do anything at this time; we will call and confirm your purchase.";
}

sub expiry {
    my $self = shift;

    return
        "Either your card has expired or you have provided the wrong expiration date. Please check it and try again.";
}

sub gendecline {
    my $self = shift;

    return
        "Your bank declined your card for an unspecified reason. Please try another card.";
}

sub nsf {
    my $self = shift;

    return
        "Your card was declined for insufficient funds. Please try another card.";
}

sub stolen {
    my $self = shift;

    return "Your card was reported lost or stolen. Please try another card.";
}

sub lunch {
    my $self = shift;

    return
        "Your bank is unavailable. Please wait a few minutes and try again.";
}

sub present {
    my $self = shift;

    return
        "Either your card has not been activated or it is not authorized for remote transactions. Please try another card.";
}

sub amexcid {
    my $self = shift;

    return
        "Your AMEX CID does not match what the bank has on file. Please try another card.";
}

sub limit {
    my $self = shift;

    return
        "Your card was declined because it has reached the credit limit. Please try another card.";
}

sub cid {
    my $self = shift;

    return
        "Your CID does not match what the bank has on file. Please try another card.";
}

sub badclient {
    my $self = shift;

    return
        "Your account has been flagged by your bank. Please try another card.";
}

sub cv {
    my $self = shift;

    return "Your purchase failed card verification. Please try another card.";
}

sub badnum {
    my $self = shift;

    return "Your card number is invalid. Please check it and try again.";
}

sub proctype {
    my $self = shift;

    return
        "We do not accept the type of card you entered. Please try another card.";
}

sub procdecline {
    my $self = shift;

    return
        "Our processor declined your card for an unspecified reason. Please try another card.";
}

sub merchprob {
    my $self = shift;

    return
        "We have a configuration error and are working to correct it. Please try again later.";
}

sub toomuch {
    my $self = shift;

    return
        "Our capture and authorization amounts mismatch. Your card has not been charged. We are working to correct the problem.";
}

sub procfail {
    my $self = shift;

    return
        "Our processor has failed to process this transaction. Please wait a few minutes and try again.";
}

sub authrev {
    my $self = shift;

    return "The authorization has already been reversed.";
}

sub authcap {
    my $self = shift;

    return "The authorization has already been captured.";
}

sub prevtrans {
    my $self = shift;

    return "The amount must equal the amount of your last purchase.";
}

sub card_type {
    my $self = shift;

    return "Your card type is invalid. Please check it and try again.";
}

sub reqval {
    my $self = shift;

    return
        "Our request is invalid. Your card has not been charged. Please try again.";
}

sub badcap {
    my $self = shift;

    return
        "This capture attempt is invalid. Your card has not been charged. Please try again.";
}

sub transrev {
    my $self = shift;

    return
        "This transaction is invalid because it has already been settled or reversed. Please try again later.";
}

sub novoid {
    my $self = shift;

    return
        "This transaction cannot be voided, reversed, or captured because it is already underway.";
}

sub voided {
    my $self = shift;

    return
        "This transaction cannot be captured because it has already been voided.";
}

sub proctime {
    my $self = shift;

    return
        "Our processor timed out. Please wait a few minutes and try again.";
}

sub DEFAULT {
    my ( $self, $code, $reply ) = @_;
    $self->error->{message}
        = "Your purchase failed for an unknown reason. Try another card or wait a few minutes.";
}

sub FAULT {
    my ( $self, $fault, $reply ) = @_;
    $self->error->{message}
        = "Your purchase failed for an unknown reason. Try another card or wait a few minutes.";
}

sub EMPTY {
    my $self = shift;
    $self->error->{message}
        = "We did not receive a response from our processor. Wait a few minutes and try again.";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

<Model::CyberSource>
    id  your_cybersource_id
    key your cybersource_key
    <payment_columns>
        address1
        amount
        card_type
        city
        country
        decision
        email
        expmonth
        expyear
        firstname
        ip
        lastname
        postcode
        reasoncode
        refcode
        state    
    </payment_columns>
</Model::CyberSource>
