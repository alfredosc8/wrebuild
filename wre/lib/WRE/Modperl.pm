package WRE::Modperl;

#-------------------------------------------------------------------
# WRE is Copyright 2005-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com	            		info@plainblack.com
#-------------------------------------------------------------------

use strict;
use base 'WRE::Service';
use Carp qw(croak);
use Class::InsideOut qw(new);
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use WRE::Host;

=head1 ISA

WRE::Service

=cut

{ # begin inside out object



#-------------------------------------------------------------------

=head getName () 

Returns human readable name.

=cut

sub getName {
    return "Apache/mod_perl";
}

#-------------------------------------------------------------------

=head2 graceful ( )

Performs a graceful restart of this service.

Note: The process that runs this command must be either root or the user specified in the WRE config file.

=cut

sub graceful {
    my $self = shift;
    my $wreConfig = $self->wreConfig;
    my $host = WRE::Host->new(wreConfig=>$wreConfig);
    unless ($wreConfig->get("apache/modperlPort") > 1024 || $host->isPrivilegedUser) {
        croak "You are not an administrator on this machine so you cannot start services with ports 1-1024.";
    }
    my $cmd = "";
    if ($host->getOsName eq "windows") {
        $cmd = "net start WREmodperl";
    }
    else {
        $cmd = $wreConfig->getRoot("/prereqs/bin/apachectl")." -f ".$wreConfig->getRoot("/etc/modperl.conf") 
            ." -D WRE-modperl -E ".$wreConfig->getRoot("/var/logs/modperl.error.log")." -k graceful";
    }
    my $count = 0;
    my $success = 0;
    `$cmd`; # catch command line output
    while ($count < 10 && $success == 0) {
        sleep(1);
        eval {$success = $self->ping};
        $count++;
    }
    return $success;
}

#-------------------------------------------------------------------

=head killRunaways () 

Kills any processes that are larger than the maxMemory setting in the config file. Returns the number of processes
killed.

=cut

sub killRunaways {
    my $self = shift;
    eval { require Proc::ProcessTable; };
    if ($@) { # can't check if this module doesn't exist (eg: windows)
        return 0;
    }
    my $killed = 0;
    my $processTable = Proc::ProcessTable->new;
    my $maxMemory = $self->wreConfig->get("apache/maxMemory");
    foreach my $process (@{$processTable->table}) {
        next unless ($process->cmndline =~ /httpd.* -D WRE-modperl /);
        if ($process->size >= $maxMemory) {
            $killed += $process->kill(9);
        }
    }
    return $killed;
}


#-------------------------------------------------------------------

=head2 ping ( )

Returns a 1 if Modperl is running, or a 0 if it is not.

=cut

sub ping {
    my $self = shift;
    my $apache = $self->wreConfig->get("apache");
    my $userAgent = LWP::UserAgent->new;
    $userAgent->agent("wre/1.0");
    $userAgent->timeout($apache->{connectionTimeout});
    my $header = HTTP::Headers->new;
    my $url = "http://".$apache->{defaultHostname}.":".$apache->{modperlPort}."/";
    my $request = HTTP::Request->new( GET => $url, $header);
    my $response = $userAgent->request($request);
    if ($response->is_success || $response->code eq "401") {
        return 1;
	} 
    croak "Modperl received error code ".$response->code." with message ".$response->error_as_HTML;
    return 0;
}

#-------------------------------------------------------------------

=head2 start ( )

Returns a 1 if the start was successful, or a 0 if it was not.

Note: The process that runs this command must be either root or the user specified in the WRE config file.

=cut

sub start {
    my $self = shift;
    my $count = 0;
    my $success = 0;
    my $config = $self->wreConfig;
    $config->set("wreMonitor/modperlAdministrativelyDown", 0);
    my $host = WRE::Host->new(wreConfig=>$config);
    unless ($config->get("apache/modperlPort") > 1024 || $host->isPrivilegedUser) {
        croak "You are not an administrator on this machine so you cannot start services with ports 1-1024.";
    }
    my $cmd = "";
    if ($host->getOsName eq "windows") {
        $cmd = "net start WREmodperl";
    }
    else {
        $cmd = $config->getRoot("/prereqs/bin/apachectl")." -f ".$config->getRoot("/etc/modperl.conf") 
            ." -D WRE-modperl -E ".$config->getRoot("/var/logs/modperl.error.log")." -k start";
    }
    `$cmd`; # catch command line output
    while ($count < 10 && $success == 0) {
        sleep(1);
        eval {$success = $self->ping };
        $count++;
    }
    return $success;
}

#-------------------------------------------------------------------

=head2 stop ( )

Returns a 1 if the stop was successful, or a 0 if it was not.

Note: The process that runs this command must be either root or the user specified in the WRE config file.

=cut

sub stop {
    my $self = shift;
    my $count = 0;
    my $success = 1;
    my $config = $self->wreConfig;
    $config->set("wreMonitor/modperlAdministrativelyDown", 1);
    my $host = WRE::Host->new(wreConfig=>$config);
    unless ($config->get("apache/modperlPort") > 1024 || $host->isPrivilegedUser) {
        croak "You are not an administrator on this machine so you cannot stop services with ports 1-1024.";
    }
    my $cmd = "";
    if ($host->getOsName eq "windows") {
        $cmd = "net stop WREmodperl";
    }
    else {
        $cmd = $config->getRoot("/prereqs/bin/apachectl")." -f ".$config->getRoot("/etc/modperl.conf")
            ." -D WRE-modperl -k stop";
    }
    `$cmd`; # catch command line output
    while ($count < 10 && $success == 1) {
        eval { $success = $self->ping };
        $count++;
    }
    return $success;
}




} # end inside out object

1;
