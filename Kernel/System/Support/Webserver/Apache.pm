# --
# Kernel/System/Support/Webserver/Apache.pm - all required system informations
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: Apache.pm,v 1.7 2007-12-21 11:01:46 ho Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Support::Webserver::Apache;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.7 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for (qw(ConfigObject LogObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    return $Self;
}

sub SupportConfigArrayGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw()) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }
}

sub SupportInfoGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleInputHash} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
        return;
    }
    if ( ref( $Param{ModuleInputHash} ) ne 'HASH' ) {
        $Self->{LogObject}
            ->Log( Priority => 'error', Message => "ModuleInputHash must be a hash reference!" );
        return;
    }

    # add new function name here
    my @ModuleList = (
        '_ApacheDBICheck', '_ApacheReloadCheck',
        '_ModPerlVersionCheck',
    );

    my @DataArray;

    FUNCTIONNAME:
    for my $FunctionName (@ModuleList) {

        # run function and get check data
        my $Check = $Self->$FunctionName( Type => $Param{ModuleInputHash}->{Type} || '', );

        next FUNCTIONNAME if !$Check;

        # attach check data if valid
        push @DataArray, $Check;
    }

    return \@DataArray;
}

sub AdminChecksGet {
    my ( $Self, %Param ) = @_;

    # add new function name here
    my @ModuleList = (
        '_ApacheDBICheck', '_ApacheReloadCheck',
        '_ModPerlVersionCheck',
    );

    my @DataArray;

    FUNCTIONNAME:
    for my $FunctionName (@ModuleList) {

        # run function and get check data
        my $Check = $Self->$FunctionName();

        next FUNCTIONNAME if !$Check;

        # attach check data if valid
        push @DataArray, $Check;
    }

    return \@DataArray;
}

sub _ApacheDBICheck {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    # check if Apache::DBI is loaded
    my $ApacheDBI = 0;
    my $Check     = '';
    my $Message   = '';
    for my $Module ( keys %INC ) {
        $Module =~ s/\//::/g;
        $Module =~ s/\.pm$//g;
        if ( $Module eq 'Apache::DBI' || $Module eq 'Apache2::DBI' ) {
            $ApacheDBI = $Module;
        }
    }
    if ( !$ApacheDBI ) {
        $Check = 'Critical';
        $Message
            = 'Apache::DBI should be used to get a better performance (pre establish database connections).';
    }
    else {
        $Check   = 'OK';
        $Message = "$ApacheDBI";
    }
    $Data = {
        Key         => 'Apache::DBI',
        Name        => 'Apache::DBI',
        Description => "Check used Apache::DBI.",
        Comment     => $Message,
        Check       => $Check,
        },
        return $Data;
}

sub _ApacheReloadCheck {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    # reload check
    my $Check   = 'Failed';
    my $Message = '';
    if ( $ENV{MOD_PERL} ) {
        eval "require mod_perl";
        if ( defined $mod_perl::VERSION ) {
            if ( $mod_perl::VERSION >= 1.99 ) {

                # check if Apache::Reload is loaded
                my $ApacheReload = 0;
                for my $Module ( keys %INC ) {
                    $Module =~ s/\//::/g;
                    $Module =~ s/\.pm$//g;
                    if ( $Module eq 'Apache::Reload' || $Module eq 'Apache2::Reload' ) {
                        $ApacheReload = $Module;
                    }
                }
                if ( !$ApacheReload ) {
                    $Check = 'Critical';
                    $Message
                        = 'Apache::Reload or Apache2::Reload should be used as PerlModule and PerlInitHandler in Apache config file.';
                }
                else {
                    $Check   = 'OK';
                    $Message = "$ApacheReload";
                }
            }
        }
    }
    else {
        $Check   = 'Critical';
        $Message = 'You should use mod_perl to increase your performance very strong!';
    }
    $Data = {
        Key         => 'Apache::Reload',
        Name        => 'Apache::Reload',
        Description => "Check used Apache::Reload/Apache2::Reload.",
        Comment     => $Message,
        Check       => $Check,
        },
        return $Data;
}

sub _ModPerlVersionCheck {
    my ( $Self, %Param ) = @_;

    my $Data = {};

    # check mod_perl version
    my $Check   = 'Failed';
    my $Message = '';
    if ( $ENV{MOD_PERL} ) {
        if ( $ENV{MOD_PERL} =~ /\/1.99/ ) {
            $Check = 'Critical';
            $Message
                = "You use a beta version of mod_perl ($ENV{MOD_PERL}), you should upgrade to a stable version.";
        }
        elsif ( $ENV{MOD_PERL} =~ /\/1/ ) {
            $Check   = 'Critical';
            $Message = "You should update mod_perl to 2.x ($ENV{MOD_PERL}).";
        }
        else {
            $Check   = 'OK';
            $Message = "$ENV{MOD_PERL}";
        }
    }
    else {
        $Check   = 'Critical';
        $Message = 'You should use mod_perl to increase your performance.';
    }
    $Data = {
        Key         => 'mod_perl version',
        Name        => 'mod_perl version',
        Description => "Check used mod_perl version.",
        Comment     => $Message,
        Check       => $Check,
        },
        return $Data;
}

1;
