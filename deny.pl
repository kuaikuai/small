#!/usr/bin/perl

# a very simple WAF
# usage: nohup perl deny.pl &

$|=1;

# base64_decode for php
$keyword = 'union|null|webscan|information_schema|chr\(|char\(|concat\(|\bselect\b|count\(|base64_decode|eval\(';
$white_list = '192.168.255|219.147.31.2';
print "deny $keyword\n";

%deny=();
%memo=();

system "iptables -F";

sub remove {
    my $ip = shift;
    print "remove $ip\n";
    my @str = `iptables -L --line-number`;
    for(@str) {
        # (/1    DROP       all  --  10.0.64.18
        if(/(\d+)\s+DROP\s+all\s+--\s+$ip/){
            system "iptables -D INPUT $1";
        }
    }
}
$last = time();
$count = 0;
sub flush {
    #print "flush\n";
    if ( time() < $last + 60) {
        return;
    }
    $count ++;
    $last = time();
    my @done = ();
    for my $ip (keys %deny) {
        #print "ip:$ip\n";
        my $now = time();
        # deny one ip in 30 min
        if ($now > $deny{$ip} + 1800) {
            remove $ip;
            push @done, $ip;
        }
    }
    for my $ip (@done) {
        delete $deny{$ip};
        delete $memo{$ip};
    }
    # empty %memo every 120 min
    if ($count % 120 == 0) {
        %memo = ()
    }
}


open FILE, "tcpdump -nn -i any -s 0 -A tcp dst port 80 |";
#open my $f, '-|', "tcpdump -nn -i eth1 -s 0 -A tcp port 80";
my $ip;
while($line = <FILE>) {
    # 172.16.132.234.80 > 219.146.73.5.65025:
    if ($line =~ /(\d+\.\d+\.\d+\.\d+)\.\d{3,} >/) {
        $ip = $1;
    }
    if ($ip and $line=~ /$keyword/i) {
        print "catch you $ip\n";
        $memo{$ip}++;
        if( $ip !~ /$white_list/ && $memo{$ip} >= 3 ) {
            unless (exists $deny{$ip}) {
                system "iptables -A INPUT -s $ip/32  -j DROP";
                $deny{$ip} = time();
            }
        }
    }
    flush();
}
