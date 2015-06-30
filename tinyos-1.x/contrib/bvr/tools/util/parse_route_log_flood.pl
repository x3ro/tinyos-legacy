#!/usr/bin/perl -w

#$Id: parse_route_log_flood.pl,v 1.2 2005/11/19 03:00:45 rfonseca76 Exp $
#Author: Rodrigo Fonseca
#Date Last Modified: 2005/11/08

# Description:
# This script parses the output of a network running BVR for sending messages.
# It works with UART messages collected from a testbed OR with DBG_USR3
# messages output by a TOSSIM simulation.
# It is ugly, sorry.

# Changelog
# 20050612 - Changed format of routes output file to include destination and
#            number of hops
# 20050414 - Changed to parse scoped flood logs
# 20050304 - Changed to new coordinates format.
#            The old format has a byte with valid flags for each of at most
#            8 beacons. The new format has no flag, and just considers 255
#            to be an invalid coordinate.
#            To parse old logs, use the flag -o


use Statistics::Descriptive;
use Getopt::Std;

my %opts = ();
getopts('l:c:hr:xos:e:',\%opts);
$GZIP = 0;

($progname) = $0 =~ m|([^/]+)$|;

$usage = "$progname -l <log> [-c <config string> -r <MAX_ROOT_BEACONS (not N_BEACONS)> -o <flag to parse old coords> -s <start time(s)> -e <end time(s)>] | -h\n";
$usage .= " config string is prepended to the output summary line, to name or identify the test\n";
$usage .= " old coordinates allows parsing of logs with the old coordinates format\n" ;
$usage .= "   in which there is a byte with valid flags preceeding the coordinates\n";
die $usage if (defined $opts{h} || !defined $opts{l});
if ($opts{l} =~ /\.gz$/) {
  $GZIP = 1;
  ($log_name) = $opts{l} =~ /(.*)\.gz$/;
}
$log_name = $opts{l};
if (defined $opts{r}) {
	$MAX_ROOT_BEACONS = $opts{r};
} else {
	$MAX_ROOT_BEACONS = 8;
}
$config = $opts{c};
if (defined $opts{s}) {
	$START_TIME = $opts{s};
	$START_TIMEms = $START_TIME*1000;
}
if (defined $opts{e}) {
	$END_TIME = $opts{e};
	$END_TIMEms = $END_TIME*1000;
}

#This considers beacon failure with scope 1 to be a success with one more
#hop. The rationale is that this is equivalent to having a beacon send a
#message, even if it does not have the node in its coordinate table, in 
#case the destination address says it is one hop away.


$PARSE_OLD_COORDS = (defined $opts{o});

$INVALD_COORD = 255;

$INF = 255;
  #Names
  $name{'27'} = 'START';
  $name{'28'} = 'FAIL_STUCK_0';
  $name{'2A'} = 'FAIL_STUCK';          
  $name{'29'} = 'FAIL_BEACON';         
  $name{'2B'} = 'SUCCESS';             
  $name{'2C'} = 'FAIL_NO_LOCAL_BUFFER';
  $name{'2D'} = 'FAIL_NO_QUEUE_BUFFER';
  $name{'2E'} = 'INVALID_STATUS';      
  $name{'2F'} = 'TO_SELF';             
  $name{'26'} = 'STATUS_NEXT_ROUTE';   
  $name{'25'} = 'BUFFER_ERROR';        
  $name{'20'} = 'SENT_NORMAL_OK';      
  $name{'21'} = 'SENT_FALLBACK_OK';    
  $name{'22'} = 'RECEIVED_OK';         
  $name{'23'} = 'RECEIVED_DUPLICATE';         

  $name{'40'} = 'BCAST_START';
  $name{'41'} = 'STATUS_BCAST_RETRY';
  $name{'42'} = 'STATUS_BCAST_FAIL';
  $name{'43'} = 'SENT_BCAST_OK';
  $name{'44'} = 'RECEIVED_BCAST_OK';
  $name{'45'} = 'BCAST_END_SCOPE';
  $name{'46'} = 'BCAST_ERROR_TIMER_FAILED';
  $name{'47'} = 'BCAST_ERROR_TIMER_PENDING';

  #Is terminal

  $is_terminal{'27'} = 0; 
  $is_terminal{'28'} = 1; 
  $is_terminal{'2A'} = 1; 
  $is_terminal{'29'} = 1; 
  $is_terminal{'2B'} = 1; 
  $is_terminal{'2C'} = 1; 
  $is_terminal{'2D'} = 1; 
  $is_terminal{'2E'} = 1; 
  $is_terminal{'2F'} = 1; 
  $is_terminal{'26'} = 0; 
  $is_terminal{'25'} = 1; 
  $is_terminal{'20'} = 0; 
  $is_terminal{'21'} = 0; 
  $is_terminal{'22'} = 0; 
  $is_terminal{'23'} = 1; 

  $is_terminal{'40'} = 0;
  $is_terminal{'41'} = 0;
  $is_terminal{'42'} = 1;
  $is_terminal{'43'} = 0;
  $is_terminal{'44'} = 0;
  $is_terminal{'45'} = 1;
  $is_terminal{'46'} = 1;
  $is_terminal{'47'} = 1;



  $AM_LOG_MSG = 60;   #0x3C
  #$AM_APP_MSG = 55;   #0x37

$scope_dist = Statistics::Descriptive::Full->new();
for ('ALL','SUCCESS','SUCCESS_FLOOD') {
  $path_length{$_} = Statistics::Descriptive::Full->new();
  $transmissions{$_} = Statistics::Descriptive::Full->new();
}

if ($GZIP) {
  open FIN,"gunzip -c $log_name|" or die "Can't open $log_name.gz!\n";
} else {
  open FIN,"$log_name" or die "Can't open $log_name!\n";
}

my $line;
while (<FIN>) {
  chomp;
  next if (! /^[\d]+ /); #ignore any messages that don't have only digits in the first field
  ($mote,$time,@packet) = split;

  next if (defined $START_TIME && $time < $START_TIMEms);
  last if (defined $END_TIME   && $time > $END_TIMEms);

  print STDERR "." if !($line++ % 1000);   
  
  $am = hex($packet[2]);
  #$last_hop = hex($packet[6].$packet[5]);
  $seq_no = hex($packet[8].$packet[7]);
  #$dest = hex($packet[1].$packet[0]);

  if ($am eq $AM_LOG_MSG) {
    #print STDERR "$_\n";
    $hex_type = $packet[9];
    next if ($hex_type eq "32");
    #Gaps:
    if (defined $last_packet{$mote} && 
        ($gap = $seq_no - $last_packet{$mote}) != 1 ) {
          printf "GAP: mote $mote at $time gap %d packets\n",($gap-1);
    }
    $last_packet{$mote} = $seq_no;
    $hex_type = $packet[9];

    if (defined $name{$hex_type}) {
    $app_seqno = hex($packet[11].$packet[10]);
    $origin = hex($packet[13].$packet[12]);
    if (!defined $wrap_seqno{$origin}) {
        $wrap_seqno{$origin} = 0;
    }
    if (defined $last_app_seqno{$origin} && $app_seqno < $last_app_seqno{$origin}) {
	$wrap_seqno{$origin}++;
    }
    $last_app_seqno{$origin} = $app_seqno;
    $eff_app_seqno = $wrap_seqno{$origin}*256 + $app_seqno;
    $dest_id= hex($packet[15].$packet[14]);
    $hopcount = hex($packet[16]);
    $route_uid = sprintf("%03d.%05d",$origin,$eff_app_seqno);

    #Read coordinates from packet
    if ($PARSE_OLD_COORDS) {
      $valid = hex($packet[17]);  
      #Read dest coordinates
      undef @valid; undef @coords;
      for ($i=0; $i<$MAX_ROOT_BEACONS;$i++) {
        $mask = 1<<$i;
        $v = $valid & $mask;
        push @valid, ($v)?1:0;
        $c = ($v)?hex($packet[18+$i]):'-';
        push @coords,$c;
      }
      #Read my coordinates
      $start = 17 + $MAX_ROOT_BEACONS + 1;
      $valid = hex($packet[$start]);
      undef @valid; undef @my_coords;
      for ($i=0; $i<$MAX_ROOT_BEACONS;$i++) {
        $mask = 1<<$i;
        $v = $valid & $mask;
        push @valid, ($v)?1:0;
        $c = ($v)?hex($packet[$start + 1 +$i]):'-';
        push @my_coords,$c;
      }
    } else {  #Parse new coordinates
      #Read dest coordinates
      undef @coords;
      for ($i=0; $i<$MAX_ROOT_BEACONS;$i++) {
        $c = hex($packet[17+$i]);
        $c = ($c == $INVALD_COORD)?'-':$c;
        push @coords,$c;
      }
      #Read my coordinates
      $start = 17 + $MAX_ROOT_BEACONS + 1;
      undef @my_coords;
      for ($i=0; $i<$MAX_ROOT_BEACONS;$i++) {
        $c = hex($packet[$start+$i]);
        $c = ($c == $INVALD_COORD)?'-':$c;
        push @my_coords,$c;
      }
    }
    
    $coords = join ",",@coords;
    $my_coords = join ",",@my_coords;
    
    #print STDERR "  route uid $route_uid\n";
    
    if (!defined $route_msgs{$route_uid}) {
      push @ordered_route_msgs,$route_uid;
    }
    if ($hex_type eq '27') {
      $time_start{$route_uid} = $time;
    }
    if ($hex_type eq '26' || $hex_type eq '2A') {
      $reroute{$route_uid} = 1;
    }
    $dest_coords{$route_uid} = $coords;
    $dest{$route_uid} = $dest_id;
    push @{$route_msgs{$route_uid}{$hopcount}{$mote}},{'status'=>$hex_type,'seq_no'=>0,'my_coords'=>'-'};

    &update_status($route_uid,$hex_type,$hopcount);

    if ($name{$hex_type} eq 'BCAST_START') {
      $scope{$route_uid} = &get_scope(\@coords);
      if ($scope{$route_uid} == 1) {
	print "Route $route_uid has flood scope of 1: dest not a neighbor of root\n";
      }
    }
    if ($name{$hex_type} eq 'SENT_BCAST_OK' ||
        $name{$hex_type} eq  'BCAST_FAIL') {
      $sent_bcast{$route_uid}++;
    }
    if ($name{$hex_type} eq 'SENT_NORMAL_OK' || 
        $name{$hex_type} eq 'SENT_FALLBACK_OK' ||
        $name{$hex_type} eq 'STATUS_NEXT_ROUTE' || 
        $name{$hex_type} eq 'FAIL_STUCK') {
      $sent{$route_uid}++;
    } 
    #if ($name{$hex_type} eq 'FAIL_BEACON') {
    #  $scope{$route_uid} = &get_scope(\@coords);
    #  if ($beacon1hop_hack && $scope{$route_uid} == 1) {
    #    push @{$route_msgs{$route_uid}{$hopcount+1}{$dest_id}},{'status'=>'2B','seq_no'=>$seq_no,'my_coords'=>$my_coords};
    #	&update_status($route_uid, '2B',$hopcount+1);
    #  }
    #}



   }
  }

}

$t_suffix = "";
if (defined $START_TIME) {
  $t_suffix = "s$START_TIME";
}
if (defined $END_TIME) {
  $t_suffix .= "e$END_TIME";
}
if ($t_suffix) {
  $t_suffix .= ".";
}

open SUM,">$log_name.".$t_suffix."summary" or die "Can't open summary file\n";
open ROUTES,">$log_name.".$t_suffix."routes" or die "Can't open routes file\n";
open BAD,">$log_name.".$t_suffix."bad_routes" or die "Can't open bad routes file\n";
open GOOD,">$log_name.".$t_suffix."good_routes" or die "Can't open good routes file\n";
open FLOOD,">$log_name.".$t_suffix."flood_routes" or die "Can't open flood routes file\n";

#Loop to count route outcomes and print route per route information
for ('SUCCESS','SUCCESS_FLOOD','CONTENTION','STUCK','FLOOD_FAIL') {
  $count_routes{$_} = 0;
} 
for $route_uid (@ordered_route_msgs) {
  $status = &get_status($route_uid);
  if ($status eq 'SUCCESS_FLOOD' || $status eq 'FLOOD_FAIL') {
    print FLOOD &route_to_string($route_uid);
  }
  if ($status eq 'SELF' || $status eq 'UNDEF' || $status eq 'ERROR') {
    print BAD &route_to_string($route_uid);
    next;   #don't count these
  }
  if (! (defined $time_start{$route_uid}) ) {
    print BAD &route_to_string($route_uid);
    next;  #likewise
  }
  #we are left with SUCCESS, BEACON, CONTENTION, STUCK
  if ($status eq 'CONTENTION' || $status eq 'STUCK' || $status eq 'FLOOD_FAIL') {
    print BAD &route_to_string($route_uid);
  } else {
    print GOOD &route_to_string($route_uid);
  }
  $count_routes++;
  $count_routes{$status}++;

  $ntx = (defined $sent{$route_uid})?$sent{$route_uid}*1:0;
  $ftx = (defined $sent_bcast{$route_uid})?$sent_bcast{$route_uid}*1:0;
  $ttx = $ntx + $ftx;
 
  $transmissions{ALL}->add_data($ttx);
  $transmissions{SUCCESS}->add_data($ttx) if ($status eq 'SUCCESS');
  $transmissions{SUCCESS_FLOOD}->add_data($ttx) if ($status eq 'SUCCESS_FLOOD');

  #print "Route $route_uid Status $status Xmit $ttx\n";

  if ($status eq 'FLOOD_FAIL' || $status eq 'SUCCESS_FLOOD') {
    $scope_dist->add_data($scope{$route_uid});
  }
  print ROUTES &route_summary_to_string($route_uid);
}

printf SUM "$config routes: $count_routes succ: %d %.3f path_l_s: %.3f sd %.3f avg_xmit_s: %.2f | success_flood: %d %.3f path_l_f: %.3f sd %.3f avg_xmit_f: %.2f | flood_fail: %d %.3f | contention %d %.3f | stuck %d %.3f | scope: %.3f sd %.3f avg_xmit_all %.2f routes_with_reroute %d %.3f\n",
  $count_routes{SUCCESS}, $count_routes{SUCCESS}/$count_routes,
  $path_length{SUCCESS}->mean(), $path_length{SUCCESS}->standard_deviation(),
  $transmissions{SUCCESS}->mean(), 
  $count_routes{SUCCESS_FLOOD} , $count_routes{SUCCESS_FLOOD} /$count_routes,
  $path_length{SUCCESS_FLOOD}->mean(), $path_length{SUCCESS_FLOOD}->standard_deviation(),
  $transmissions{SUCCESS_FLOOD}->mean(),
  $count_routes{FLOOD_FAIL}, $count_routes{FLOOD_FAIL}/$count_routes,
  $count_routes{CONTENTION}, $count_routes{CONTENTION}/$count_routes,
  $count_routes{STUCK}, $count_routes{STUCK}/$count_routes,
  $scope_dist->mean(), $scope_dist->standard_deviation(),
  $transmissions{ALL}->mean(),
  scalar(keys %reroute ), scalar(keys %reroute)/$count_routes;


#n $nodes d $density b $beacons p $placement ts $seed routes $total_routes 
close BAD; close ROUTES; close SUM; close GOOD; close FLOOD;

#print diameter
($p98,undef) = $path_length{SUCCESS}->percentile(98);
($p95,undef) = $path_length{SUCCESS}->percentile(95);
$max = $path_length{SUCCESS}->max();

print "Diameter Estimation: max path: $max p98: $p98 p95:$p95\n";


#1 line summary to allow for temporal estimation
#route_summary_to_string($route_uid)
sub route_summary_to_string {
  my $r = "";
  $time = $time_start{$route_uid} if (defined $time_start{$route_uid});
  $status = &get_status($route_uid);
  $scope = (defined $scope{$route_uid})?"$scope{$route_uid}":"-";
  $dest = $dest{$route_uid};
  $normal_hopcount = (defined ($greedy_hopcount{$route_uid}))
                        ? $greedy_hopcount{$route_uid}
                        :  $max_hopcount{$route_uid};
  $ntx = (defined $sent{$route_uid})?$sent{$route_uid}*1:0;
  $ftx = (defined $sent_bcast{$route_uid})?$sent_bcast{$route_uid}*1:0;
  $ttx = $ntx + $ftx;
  $r = " $time Route: $route_uid status: $status dest: $dest normal_hpcnt: $normal_hopcount scope: $scope ttx: $ttx normal_tx: $ntx flood_tx: $ftx\n";
}

#route_to_string($route_uid) 
sub route_to_string {
  my $r = '';
  my $time = 'NO_START';
  $time = $time_start{$route_uid} if defined $time_start{$route_uid};
  my $status = &get_status($route_uid);
  my $scope = (defined $scope{$route_uid})?"$scope{$route_uid}":"-";
  $ntx = (defined $sent{$route_uid})?$sent{$route_uid}*1:0;
  $ftx = (defined $sent_bcast{$route_uid})?$sent_bcast{$route_uid}*1:0;
  $ttx = $ntx + $ftx;
  $r = " Route: $route_uid to mote $dest{$route_uid} ($dest_coords{$route_uid}) start: $time status: $status scope: $scope ttx: $ttx normal_tx: $ntx flood_tx: $ftx\n";
  for my $hop (sort {$a <=> $b} keys %{$route_msgs{$route_uid}}) {
    $r .= "  hopcount: $hop";
    my $s = "  ";
    for $mote (keys %{$route_msgs{$route_uid}{$hop}}) {
      $r .= "$s$mote:";
      $s = "              ";
      my $msgs = $route_msgs{$route_uid}{$hop}{$mote};
      for $route_entry (sort {$a->{seq_no} <=> $b->{seq_no}} @{$msgs}) {
        $status = $route_entry->{status};
        $status .= "*" if $is_terminal{$status};
        $status .= "($route_entry->{my_coords})" if ($status eq '2A*' || $status eq '28*');
        $r .= " $status"; 
      }
      $r .= "\n";
    }
  }
  return $r;
}

#output
#total_routes success % beacon % scope 

#update_status(route_uid,type)
sub update_status {
  my ($route_uid,$type,$hopcount) = @_;
  my $status = $name{$type};
 
  if ($status eq 'SUCCESS') {
    $status{$route_uid}{SUCCESS} = 1;
    if (exists $scope{$route_uid}) {
      $path_length{'SUCCESS_FLOOD'}->add_data($hopcount);
    } else {
      $path_length{'SUCCESS'}->add_data($hopcount);
    } 
    $path_length{'ALL'}->add_data($hopcount);
  } elsif ($status eq 'BCAST_END_SCOPE') {
    $status{$route_uid}{FLOOD_FAIL} = 1;
  } elsif ($status eq 'BCAST_FAIL') {
    $status{$route_uid}{FLOOD_FAIL} = 1;
  } elsif ($status eq 'BCAST_ERROR_TIMER_FAILED' ||
           $status eq 'BCAST_ERROR_TIMER_PENDING') {
    $status{$route_uid}{CONTENTION} = 1;
  } elsif ($status eq 'FAIL_NO_LOCAL_BUFFER' || 
           $status eq 'FAIL_NO_QUEUE_BUFFER') {
    $status{$route_uid}{CONTENTION} = 1;
  } elsif ($status eq 'FAIL_STUCK' ||
           $status eq 'FAIL_STUCK_0') {
    $status{$route_uid}{STUCK} = 1;
  } elsif ($status eq 'INVALID_STATUS' ||
           $status eq 'BUFFER_ERROR') {
    $status{$route_uid}{ERROR} = 1;
  } elsif ($status eq 'TO_SELF') {
    $status{$route_uid}{SELF} = 1;
  }

  if (!defined $max_hopcount{$route_uid} ||
       $hopcount > $max_hopcount{$route_uid}) {
	$max_hopcount{$route_uid} = $hopcount;
  }
  if ($status eq 'BCAST_START') {
    $greedy_hopcount{$route_uid} = $hopcount;
  }
}

#get_status(route_uid)

sub get_status {
	my $route_uid = shift;
  if ($status{$route_uid}{SELF}) {
    return 'SELF';
  } elsif ($status{$route_uid}{ERROR}) {
    return 'ERROR';
  } elsif ($status{$route_uid}{SUCCESS}) {
    if (exists $scope{$route_uid}) {
      return 'SUCCESS_FLOOD'; 
    } else {
      return 'SUCCESS';
    }
  } elsif ($status{$route_uid}{FLOOD_FAIL}) {
    return 'FLOOD_FAIL';
  } elsif ($status{$route_uid}{CONTENTION}) {
    return 'CONTENTION';
  } elsif ($status{$route_uid}{STUCK}) {
    return 'STUCK';
  } else {
    return 'UNDEF';
  }
}

#get_scope(\@coords)
sub get_scope {
  my $coords = shift;
  $closest = $INF;
  for my $coord (@$coords) {
    if ($coord ne '-' && $coord < $closest) {
      $closest = $coord;
    }
  }
  return $closest;
}


#For a given route, returns the number of hops
#And the number of hops in fallback


#Each route is a tree rooted at the start, with branches ending in the
#terminal states. How to reconstruct the tree in face of missing packets?
#Sentok and received ok

