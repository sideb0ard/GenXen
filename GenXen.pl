#!/usr/bin/perl -w
use strict;
use Text::Template;

my $template = Text::Template->new(TYPE => 'FILE',  SOURCE => 'basevm.cfg.tmpl');

system("clear");
print "***************************************************************\n";
print "**GenXen, the interactive muy fantastic Xen Host building bot**\n";
print "***************************************************************\n\n";
print "What is the hostname for the new Xen VM? ";
chomp (my $hostname=<>);
print "How many VCPU's should it have? ";
chomp (my $vcpu=<>);
print "How much memory?(MiB) ";
chomp (my $memory=<>);
print "What is the IP address for the host? ";
chomp (my $ip=<>);

print "\n##################\n";
print "HOSTNAME: $hostname\nVCPU: $vcpu\nMEMORY: $memory\nIP: $ip\n";
print "##################\n\n";
print "Is this correct? [y/n] ";
while(1) {
    if ((my $answer = <STDIN>) =~ /^y$/i) {
        print "\n*bzzt* host building bot now proceeding - please haz cup of tea while i work *zzzt*\n\n";
        exit;
    } else {
        print "\n*bzzt* host building bot now terminating due to luser error *bzzztq**\n\n";
        exit;
    }
}
