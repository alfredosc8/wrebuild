package Hoster::WebGUIDemo;

use lib ('/data/wre/lib','/data/WebGUI/lib');
use strict;
use Apache2::Const;
use DBI;
use Parse::PlainConfig;
use WebGUI;

#-------------------------------------------------------------------
sub handler {   
        my $r = shift;
        my $config = Parse::PlainConfig->new('DELIM' => '=', 'FILE' => '/data/wre/etc/demo.conf', 'PURGE'=>1);
	$r->pnotes('masterDemoConfig' => $config);
	my $sites = $config->get('sites');
	my $id = $r->uri;
	$id =~ s/^\/(demo[0-9\_]+).*$/$1/;
	if ($sites->{$id}) {
		return WebGUI::handler($r,$id.".conf");
	} elsif ($r->uri =~ /^\/extras/) {
		# just pass it on thru
	} elsif ($r->uri eq "/create") {
                $r->set_handlers(PerlResponseHandler => \&createDemo);
                $r->set_handlers(PerlTransHandler => sub { return Apache2::Const::OK });
	} else {
                $r->set_handlers(PerlResponseHandler => \&promptDemo);
                $r->set_handlers(PerlTransHandler => sub { return Apache2::Const::OK });
	}	
        return Apache2::Const::DECLINED;
}

sub gotHere {
	my $r = shift;
	$r->print('got here');
	return Apache2::Const::OK;
}

#-------------------------------------------------------------------
sub promptDemo {
	my $r = shift;
	my $config = $r->pnotes('masterDemoConfig');
	$r->content_type("text/html");
	$r->print(q|<html><head><title>WebGUI Demo</title></head><body>
<div style="width: 300px; margin-top: 20%; text-align: left; margin-left: 35%; margin-bottom: 10px; background-color: #cccccc; border: 1px solid #800000; padding: 10px; color: #000080;">If you'd like your own personal demo of the <a style="color: #ff2200;" href="http://www.spreadwebgui.com/">WebGUI</a> application framework click the button below. Your demo will last for |.$config->get("duration").q| day(s), then will be deleted.</div> 
<div style="text-align: center; width: 300px; margin-left: 35%;"><form action="/create" method="post"><input onclick="this.value='Please wait while we create your demo!'" type="submit" value="Create My Personal WebGUI Demo" /></form></div>
</body></html>|);
	return Apache2::Const::OK;
}

#-------------------------------------------------------------------
sub createDemo {
	my $r = shift;
	srand;
	my $now = time();
	my $demoId = "demo".$now."_".int(rand(999));
	createConfig($demoId);
	createFilesystem($demoId);
	createDatabase($r,$demoId);
	updateDemoConfig($r,$demoId,$now);
	$r->headers_out->set(Location => "/".$demoId."/");
        $r->status(301);
	return Apache2::Const::OK;
}

#-------------------------------------------------------------------
sub updateDemoConfig {
	my $r = shift;
	my $demoId = shift;
	my $now = shift;
	my $config = $r->pnotes('masterDemoConfig');
	my $sites = $config->get('sites');
	$sites->{$demoId} = $now;
	$config->set(sites=>$sites);
	$config->write;
}

#-------------------------------------------------------------------
sub createConfig {
        my $demoId = shift;
        my $config = Parse::PlainConfig->new('DELIM' => '=',
                'FILE' => '/data/WebGUI/etc/WebGUI.conf.original',
                'PURGE' => 1);
        $config->set(
                dsn => "DBI:mysql:".$demoId.";host=".$config->get("mysqlhost"),
                dbuser => "demo",
                dbpass => "demo",
                sitename => "demo",
		gateway => "/".$demoId,
                uploadsURL => "/".$demoId."/uploads",
                uploadsPath => "/data/domains/demo/".$demoId."/uploads"
                );
        $config->write("/data/WebGUI/etc/".$demoId.".conf");
}

#-------------------------------------------------------------------
sub createFilesystem {
        my $demoId = shift;
        system("mkdir -p /data/domains/demo/".$demoId."/uploads");
}

#-------------------------------------------------------------------
sub createDatabase {
	my $r = shift;
        my $demoId = shift;
	my $config = $r->pnotes('masterDemoConfig');
        my $dbh = DBI->connect("DBI:mysql:test;host=".$config->get("mysqlhost"),$config->get("adminuser"),$config->get("adminpass"));
        $dbh->do("create database ".$demoId);
        $dbh->do("grant all privileges on ".$demoId.".* to demo\@localhost identified by 'demo'");
        $dbh->do("flush privileges");
        $dbh->disconnect;
        system("/data/wre/prereqs/mysql/bin/mysql --host=".$config->get("mysqlhost")." -udemo -pdemo ".$demoId." < ".$config->get("createScript"));
}


1;
