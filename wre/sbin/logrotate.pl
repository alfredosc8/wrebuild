#!/data/wre/prereqs/bin/perl

#####
## logrotate.pl for the WebGUI Runtime Environment
## based upon perl-logrotate.pl by Aki Tossavainen <cmouse@youzen.ext.b2.fi> (c) 2004
##
# Does a log file rotation as defined by config file.
# Does not break open logfiles, just truncates them.
####

use strict;
use Config::JSON;

# Configuration file to use.
my $config = Config::JSON->new("/data/wre/etc/wre.conf")->get("logrotate");

# Init variables
our @logfiles;

# how many old files should we keep
our $rotateFiles = $config->{rotations} || 3;

#-------------------------------------------------------------------
sub findLogFiles {
    my $path = shift;
    if ( opendir( DIR, $path ) ) {
        my @filelist = readdir(DIR);
        closedir(DIR);
        foreach my $file (@filelist) {
            if ( $file =~ /\.log$/ ) {
                push( @logfiles, $path . "/" . $file );
            }
            else {
                findLogFiles( $path . "/" . $file )
                    unless ( $file =~ /public$/ || $file eq ".." || $file eq "." || $file =~ /setupfiles/ );
            }
        }
    }
}

#-------------------------------------------------------------------
# Main Program

findLogFiles("/data/wre/var");
findLogFiles("/data/domains");

# now that we know what we are expected to do, we'll start
for my $logfile (@logfiles) {
    # open file.
    if ( open my $currentLog, '<', $logfile ) {
        # juggle files
        for my $i ( 0 .. ( $rotateFiles - 2 ) ) {
            # to avoid making keep-files + 1 files...
            my $n = $rotateFiles - $i - 1;
            # and if not, this.
            if ( -e $logfile . '.' . $n ) {
                unlink $logfile . '.' . $n;
            }
            rename $logfile . '.' . ( $n - 1 ), $logfile . '.' . $n;
        }
        # move current log into log.0
        if ( open my $newLog, '>>', $logfile . '.0' ) {
            while ( my $line < $currentLog > ) {
                print {$newLog} $line;
            }
            close $newLog;
            close $currentLog;
            # truncate
            if ( open my $currentLog, '>', $logfile ) {
                print {$currentLog} '';
                close $currentLog;
            }
            else {
                print "Unable to truncate file $logfile\n";
            }
        }
        else {
            close $currentLog;
            print "Unable to create file for rotation " . $logfile . ".0\n";
        }
    }
    else {
        print "Unable to open file $logfile\n";
    }
}
