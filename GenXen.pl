#!/usr/bin/perl -w
use strict;
use Text::Template;

my $template = Text::Template->new(SOURCE => 'basevm.cfg.tmpl')
          or die "Couldn't construct template: $Text::Template::ERROR";
my $domainsdir = "/var/virt-machines/domains/";

userinput();

sub userinput {
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
    if ((my $answer = <STDIN>) =~ /^y$/i) {
        print "\n*bzzt* host building bot now proceeding - please haz cup of tea while i work *zzzt*\n\n";
        build_config($hostname,$vcpu,$memory,$ip);
        exit;
    } else {
        print "\n*bzzt* host building bot now terminating due to luser error *bzzztq**\n\n";
        exit;
    }
}

sub build_config {
    my($hostname,$vcpu,$memory,$ip) = @_;
    my $mac = gen_mac_address();
    print "\nBuilding COnfig..\n\n";
    my %vars = (domainsdir => $domainsdir, hostname => $hostname, vcpu => $vcpu, memory => $memory, ip => $ip, mac => $mac);
    my $outputconfigfile = $template->fill_in(HASH => \%vars);
    print $outputconfigfile . "\n";

}

sub gen_mac_address {
    # 00:16:3e is the OUI for Xen - http://standards.ieee.org/develop/regauth/oui/oui.txt
    my $rand_hex = join ":", map { unpack "H*", chr(rand(256)) } 1..3;
    my $xen_mac="00:16:3e" . ":" . $rand_hex;
    return($xen_mac);
}
