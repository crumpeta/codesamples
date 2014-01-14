#!/usr/bin/perl -w
use strict;
use File::Rsync;
use vars qw($verbose);

$verbose = 0;
my $local_dir       = '/home/alan/';
my $remote_user     = 'arodriguez';
my $remote_host     = 'moccasin';
my $remote_dir      = "$remote_user\@$remote_host:/data/access_logs/beige_apache_access_*";


print "Creating rsync object...\n" if $verbose;
my $rsync = File::Rsync->new( { compress => 1,
                rsh => '/usr/local/bin/ssh', 
                verbose => 1, debug => 0, progress => 1 } );

print "Running rsync command ...\n" if $verbose;
print "$remote_dir\n" if $verbose;
$rsync->exec( { src => $remote_dir, dest => $local_dir } ) or warn "rsync failed\n";
print "Rsync command completed." if $verbose;



# For each server in list,
#  log in
#  identify all web log files.
#  rsync them to moccasin
#  verify files xfer to moccasin ok.
#  delete files from server.
#  close connection

