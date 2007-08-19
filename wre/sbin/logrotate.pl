#!/data/wre/prereqs/bin/perl

#-------------------------------------------------------------------
# WRE is Copyright 2005-2007 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com	            		info@plainblack.com
#-------------------------------------------------------------------
# based upon perl-logrotate.pl by Aki Tossavainen <cmouse@youzen.ext.b2.fi> (c) 2004

use strict;
use lib '/data/wre/lib';
use WRE::Config;

my $config = WRE::Config->new;
our $rotateFiles = $config->get("logs/rotations") || 3;

# locate log files to rotate
our @logfiles = ();
findLogFiles($config->getRoot("/var/logs"));
findLogFiles($config->getDomainRoot);

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
            while ( my $line = <$currentLog> ) {
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

# if stats are enabled let's compile them

if ($config->get("awstats/enabled")) {
    system($config->getRoot("/prereqs/tools/awstats_updateall.pl")
        ." now -awstatsprog=".$config->getRoot("/prereqs/wwwroot/awstats.pl")
        ." -configdir=".$config->getRoot("/etc")
        );
}


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
                unless ( $file =~ /public$/ 
                    || $file eq ".." 
                    || $file eq "." 
                    || $file =~ /setupfiles/ ) {
                    findLogFiles( $path . "/" . $file );
                }
            }
        }
    }
}


