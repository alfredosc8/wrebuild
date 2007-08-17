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

use lib '/data/wre/lib';
use strict;
use GetOpt::Long;
use WRE::Config;
use WRE::Site;

$| = 1; 

my $config = WRE::Config->new();
my ($var1, $var2, $var3, $var4, $var5, $var6, $var7, $var8, $var9, $var0, $sitename, $adminPassword, 
    $dbUser, $dbPassword, $help) = "";
GetOptions(
    "help"                  => \$help,
    "var1=s"                => \$var1,    
    "var2=s"                => \$var2,    
    "var3=s"                => \$var3,    
    "var4=s"                => \$var4,    
    "var5=s"                => \$var5,    
    "var6=s"                => \$var6,    
    "var7=s"                => \$var7,    
    "var8=s"                => \$var8,    
    "var9=s"                => \$var9,    
    "var0=s"                => \$var0,    
    "sitename=s"            => \$sitename,
    "adminPassword=s"       => \$adminPassword,
    "databaseUser=s"        => \$dbUser,
    "databasePassword=s"    => \$dbPassword, 
    );

my $dbAdminUser = $config->get("mysql")->{adminUser};

if ($help || $adminPassword eq "" || $sitename eq "") {
    print <<STOP;
Usage: perl $0 --sitename=www.example.com --adminPassword=123qwe

Options:

 --adminPassword    The password for the "$dbAdminUser" in your MySQL database.

 --databaseUser     The username you'd like created to access this site's database.

 --databasePassword The password you'd like created to access this site's database.

 --help             This message.

 --sitename         The name of the site you'd like to create. For example: www.example.com 
                    or intranet.example.com

 --var0-9           A series of variables you can use to arbitrary information into the site
                    creation process. These variables will be exposed to all templates used to
                    create this site.

STOP
}


my $site = WRE::Site->new(
    wreConfig       => $config,
    sitename        => $sitename,
    adminPassword   => $adminPassword,
    );
if (eval {$site->checkCreationSanity}) {
    $site->create({
        siteDatabaseUser        => $databaseUser,
        siteDatabasePassword    => $databasePassword,
        var0                    => $var0,
        var1                    => $var1,
        var2                    => $var2,
        var3                    => $var3,
        var4                    => $var4,
        var5                    => $var5,
        var6                    => $var6,
        var7                    => $var7,
        var8                    => $var8,
        var9                    => $var9,
        });
    print $site->getSitename." was created. Don't forget to restart the web servers and Spectre.\n";
} 
else {
    print $site->getSitename." could not be created because: ".$@."\n";
}



