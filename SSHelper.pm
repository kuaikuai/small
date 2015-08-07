#!/usr/bin/perl
package SSHelper;
use Expect;
use warnings;
#$Expect::Log_Stdout = 1;
#$Expect::Debug = 1;
$ENV{TERM} = "vt100";
$Expect::Multiline_Matching=1;
$Expect::IgnoreEintr=1;

sub load_conf {
    my ($file_name) = @_;
    my %hash = ();
    open FILE, "< $file_name" or die "cannot open $file_name";
    while (<FILE>) {
        if (/(\S+)\s+(\S+)/) {
            my ($host, $pass) = ($1, $2);
            $hash{$host} = $pass;
        }
        elsif (/(\S+)/) {
            $hash{$1} = undef;
        }
    }
    return \%hash;
}

sub run_cmd {
    my ($ip, $usr, $pass, $cmd) = @_;
    my $exp = Expect->new;
    $exp->log_stdout( 1 );
    $exp = Expect->spawn("ssh -l $usr $ip");
    $exp->log_file("output.log");
    $exp->expect(30,
                 [
                  qr/password: /i,
                  sub {
                      my $self = shift ;
                      $self->send("$pass\n");
                      sleep(1);
                      exp_continue;   
                  }
                 ],
                 [
                  'connecting (yes/no)? ',
                  sub {
                      my $self = shift ;
                      $self->send_slow("yes\n");
                      sleep(1);
                      exp_continue;
                  }
                 ],
                 [ qr/[\]\$\>\#]/,
                   sub {
                       print "ok";
                   }
                 ]
        );
    if($exp->exp_error()) {
        return -1;
    }
    # todo timeout
    $exp->send($cmd . "\n");
    if($exp->exp_error()) {
        print "run command '$cmd' error:", $exp->exp_error(), "\n";
        return -1;
    }
    $exp->send("exit\n") if ($exp->expect(10,'#'));
    $exp->soft_close();
    return 0;
}

sub copy_file {
    my ($ip, $usr, $pass, $file, $dst_dir) = @_;
    print "copy $file to $ip:$dst_dir\n";
    my $exp = Expect->new;
    $exp->match_max(4096);
    $exp = Expect->spawn("scp  -o StrictHostKeyChecking=no  $file $usr" . "@" . "$ip:$dst_dir\n");
    my $r;
    if ($pass) {
        $r = $exp->expect(30,
                 [
                  'Are you sure you want to continue connecting (yes/no)?',
                  sub {
                      my $self = shift;
                      $self->send("yes\n");
                      sleep(1);
                      exp_continue;
                  }
                 ],
                 [
                  qr/password:/i,
                  sub {
                      my $self = shift;
                      $self->send("$pass\n");
                      sleep(1);
                  }
                 ],
        );
     }

    $exp->soft_close();
    if ($pass && !$r) {
        print "copy file $ip failed\n";
        return -1;
    }
    return 0;
}	

sub run {
    my %args = @_;
    my $rc = 0;
    if ($args{src} && $args{dst}) {
       $rc = copy_file ($args{ip}, $args{user}, $args{password}, $args{src}, $args{dst});
    }
    if ($rc < 0) { return $rc; }
    if (exists $args{command}) {
        return run_cmd($args{ip}, $args{user}, $args{password}, $args{command});
    }
    return $rc;
}

sub batch {
   my ($conf, $f) = @_;
   my $hosts = load_conf($conf);
   if (! $hosts ) {
      print "load conf error\n";
      return -1;
   }
   return grep { $f->($_, $hosts->{$_}) == 0 } keys %$hosts;
}

sub batch_run {
  my ($conf_name, $cmd, $src, $dst) = @_;
  @ok = batch( $conf_name, sub { return SSHelper::run(ip=>$_[0],
                                                    user=>"root",
                                                    password=>$_[1],
                                                    src=>$src,
                                                    dst=>$dst,
                                                    command=>$cmd); } );
  print @ok;
}

1;
