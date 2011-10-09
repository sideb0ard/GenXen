#!/usr/bin/perl -w
use strict;
use Text::Template;
use File::Path qw(make_path remove_tree);
use File::Copy;

# CHANGE THESE VARIABLES TO MATCH YOUR NEEDS ############################################################
#
# DIRECTORIES AND FILE VARIABLES
my $domainsdir = "/var/virt-machines/domains"; # output destination directory - hostname will be appended
my $xenconfigdir = "/etc/xen/"; # Xen default

# SOURCE IMG FILES YOU HAVE CREATED
my $srcdisk_img = "/var/virt-machines/remote-domains/xen-squeeze-base/disk.img";
my $srcswap_img = "/var/virt-machines/remote-domains/xen-squeeze-base/swap.img";
my $destdisk_img;

# TEMPLATES
my $xentemplate = Text::Template->new(SOURCE => 'basevm.cfg.tmpl')
          or die "Couldn't construct host template: $Text::Template::ERROR";
my $hostnametemplate = Text::Template->new(SOURCE => 'hostname.tmpl')
          or die "Couldn't construct hostname template: $Text::Template::ERROR";
my $hoststemplate = Text::Template->new(SOURCE => 'hosts.tmpl')
          or die "Couldn't construct hostname template: $Text::Template::ERROR";
my $interfacestemplate = Text::Template->new(SOURCE => 'interfaces.tmpl')
          or die "Couldn't construct network template: $Text::Template::ERROR";

# LOCAL NETWORK VARIABLES
my $netmask = "255.255.0.0";
my $defaultgw = "10.1.255.254";
#
# END OF VARIABLES ##################################################
#########################################################################################################

# OK, GO GEN-XEN-BOT, GO, GO!!
genxen();

print "\n\n*************************************************************************************\n";
print "**zzt* GenXen-bot haz finished - new VM created as desired - *zzt*thnkyouhazniceday**\n";
print "*************************************************************************************\n";


############################ THA SUB CLUB #####################################

sub genxen {
    system("clear");
    print "***************************************************************\n";
    print "**GenXen, the interactive muy fantastic Xen Host building bot**\n";
    print "***************************************************************\n\n";
    print "What is the hostname for the new Xen VM? ";
    chomp (my $hostname=<>);
    print "How many VCPU's should it have? ";
    chomp (my $vcpu=<>);
    print "How much memory?(GB) ";
    chomp (my $memory=<>);
    $memory = $memory * 1024;
    print "What is the IP address for the host? ";
    chomp (my $ip=<>);

    print "\n##################\n";
    print "HOSTNAME: $hostname\nVCPU: $vcpu\nMEMORY(MiB): $memory\nIP: $ip\n";
    print "##################\n\n";
    print "Is this correct? [y/n] ";
    if ((my $answer = <STDIN>) =~ /^y$/i) {
        print "\n*bzzt* host building bot now proceeding - please haz cup of tea while i work *zzzt*\n\n";
        copy_base_img($hostname);
        build_config($hostname,$vcpu,$memory,$ip);
        mount_loopback($hostname,$ip,$defaultgw,$netmask,$destdisk_img);
        exit;
    } else {
        print "\n*bzzt* host building bot now terminating due to luser error *bzzztq**\n\n";
        exit;
    }
}

sub copy_base_img {
    my $hostname = shift;
    my $destdir = $domainsdir . "/" . $hostname;
    $destdisk_img = $destdir . "/" . "disk.img";
    my $destswap_img = $destdir . "/" . "swap.img";
    unless ( -d $destdir) {
        make_path("$destdir") || die "*bzzk* Couldn't create $destdir - $!\n";
        print "**zzt* host building bot haz now created $destdir.. *zz*\n";
    }
        
    if ( -e $destdisk_img ) {
        die "*bbzzt* - encountered error - $destdisk_img already exists.. now exiting .. *zz*";
    }

    print "\nCopying $srcdisk_img to *bzz* $destdisk_img *..\n";
    copy("$srcdisk_img","$destdisk_img") || die "**malfunction - $!\n";
    print "\nCopying *zz* $srcswap_img to $destswap_img ..\n";
    copy("$srcswap_img","$destswap_img") || die "**malfunction - $!\n";
}

sub build_config {
    my($hostname,$vcpu,$memory,$ip) = @_;
    my $mac = gen_mac_address();
    print "\n*Bzz*uilding COnfig..\n\n";
    my %vars = (domainsdir => $domainsdir, hostname => $hostname, vcpu => $vcpu, memory => $memory, ip => $ip, mac => $mac);
    my $outputconfigfile = $xentemplate->fill_in(HASH => \%vars);
    print $outputconfigfile . "\n";
    my $hostconfig = "$xenconfigdir" . "$hostname" . ".cfg";
    open(CONFIG,">$hostconfig") || die "*zzbt* malfunction - can't open $hostconfig for writing - $!\n";
    print CONFIG $outputconfigfile;

}

sub mount_loopback {
    my ($hostname,$ip,$defaultgw,$netmask,$dskimg) = @_;
    my %vars = (hostname => $hostname, ip => $ip, defaultgw => $defaultgw, netmask => $netmask);

    my $mntpoint = "/tmp/" . $hostname;
    make_path("$mntpoint") || die "*malfunctionzzz - mount point $mntpoint exists..\n";
    print "Mounting $dskimg at $mntpoint\n\n";
    system("mount -o loop $dskimg $mntpoint");

    my $vmetcdir = $mntpoint . "/" . "etc/";

    if( !-d  $vmetcdir ) {
        system("umount $mntpoint");
        remove_tree($mntpoint);
        die "**zzvt* Malfunction - Mount point does not seem to exist\n";
    }

    my $vmhosts = $vmetcdir . "hosts";
    my $vmhostname = $vmetcdir . "hostname";
    my $vminterfaces = $vmetcdir . "network/" . "interfaces";

    print "\n**Generat*ing VM /etc/hosts file..\n\n";
    my $outputhosts = $hoststemplate->fill_in(HASH => \%vars);
    print $outputhosts . "\n";
    open(VMHOSTS, ">$vmhosts") || die "*zzt* malfunction - cannot open $vmhosts - $!\n";
    print VMHOSTS $outputhosts;
 
    print "Gener*ting VM /etc/hostname file..\n\n";
    my $outputhostname = $hostnametemplate->fill_in(HASH => \%vars);
    print $outputhostname . "\n";
    open(VMHOSTNAME, ">$vmhostname") || die "*zzt* malfunction - cannot open $vmhostname - $!\n";
    print VMHOSTNAME $outputhostname;

    print "Gen*rating VM /etc/network/interfaces file..\n\n";
    my $outputinterfaces = $interfacestemplate->fill_in(HASH => \%vars);
    print $outputinterfaces . "\n";
    open(VMINTERFACES, ">$vminterfaces") || die "*zzt* malfunction - cannot open $vminterfaces - $!\n";
    print VMINTERFACES $vminterfaces;

    system("umount $mntpoint");
#    remove_tree($mntpoint);
}

sub gen_mac_address {
    # 00:16:3e is the OUI for Xen - http://standards.ieee.org/develop/regauth/oui/oui.txt
    my $rand_hex = join ":", map { unpack "H*", chr(rand(256)) } 1..3;
    my $xen_mac="00:16:3e" . ":" . $rand_hex;
    return($xen_mac);
}
