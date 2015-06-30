#!/usr/bin/perl
#$Id: generate_topology.pl,v 1.1 2005/11/09 05:32:31 rfonseca76 Exp $
use strict;

my $USE_GNUPLOT = 1;

# Updated to the release version of BVR, changed the format of topology.h
# Rodrigo Fonseca. 

my $usage;
my $RETRIES = 30;
my $INF = 1000000;
my $DEGREE_LIMIT = $INF;
my $degree_name = ($DEGREE_LIMIT == $INF)?"":$DEGREE_LIMIT;
my %beacon_placement = (
  'edges' => {function=>\&pick_n_roots_edges, name=>'4 beacons, corners'},
  'random'  => {function=>\&pick_roots_randomly,  name=>'4 beacons, random'}
);
my $EmpiricalModelConstant = 22.5; #the size of a reasonable circle in lossybuilder, in feet...
my $build_graph = \&build_fixed_radius_graph; #(graph,n,density)

$usage  = "generate_topology.pl v0.8.1 - generate topologies for BVR\n";
$usage .= "args: <number of nodes> <exp. density (neighs/node)> <num_roots> <'edges|random'> <seed>\n";
$usage .= "      where edges means the beacons are in the edges, as evenly spaced as possible\n";
$usage .= "            random means the beacons are randomly placed in the network\n";


die $usage if (scalar @ARGV) != 5;

if ($USE_GNUPLOT) {
  use Chart::Graph::Gnuplot qw(gnuplot);
}
my ($nnodes,$density,$nroots,$root_type,$seed) = @ARGV;
my ($bkey);

if ($root_type =~ /edges/) {
  $bkey = 'edges';
} elsif ($root_type =~ /random/) {
  $bkey = 'random';
} else {
  die $usage;
}
die "Density should not exceed number of nodes!\n" if ($density > $nnodes);;

srand $seed;

my $g = {};
print STDERR "Building graph...";
if (! &$build_graph($g,$nnodes,$density,$bkey)) {
  print STDERR "Could not create graph with (n,d) = ($nnodes,$density)\n";
  die "Could not create your graph, sorry...\n";
}
print STDERR "Picking roots ($bkey) ...";
&{$beacon_placement{$bkey}->{function}}($g,$nroots);
print STDERR "Writing Lossy builder file ...";
&write_lossy_builder_file($g);
die "Problem running LossyBuilder\n"if (!(-e "$g->{name}.pkt_loss"));

&read_lossy_builder_file("$g->{name}.pkt_loss");
&write_lossless_tossim_file($g);
print STDERR "Creating config file\n";
&output_testbed_config($g);
print STDERR "Creating topology header file\n";
&output_nogeo_h($g);

print STDERR "Drawing the graph...\n";
&draw_neighbor_tables($g);




printf STDERR "Generated graph. Maximum node degree:%d Average node degree:%f...\n",$g->{max_degree},$g->{avg_degree};



#output
sub write_lossy_builder_file {
  my $graph = shift;
  my $n;
  my $cmd;
  my $scaling = $EmpiricalModelConstant/$graph->{range};
  open FOUT,">$graph->{name}.pos" or return 0;
  for $n (@{$graph->{nodes}}) {
	printf FOUT "%f %f\n",$scaling*$n->{x},$scaling*$n->{y};
  }
  close FOUT;
  print STDERR "Generating lossy model\n";
  $cmd = "java net.tinyos.sim.LossyBuilder -packet -i $graph->{name}.pos -o $graph->{name}.pkt_loss";
  print STDERR "running $cmd\n";
  `$cmd`;
}

sub read_lossy_builder_file {
  my $name = shift;
  my @line;
  my (%edges,%nodes,$nodes);
  my $total_edges = 0;
  open FIN,"$name" or return;
  while (<FIN>) {
    chomp;
    @line = split;
    #Each line is <node from> <node to> <loss probability>
    $nodes{$line[0]}++;
    $nodes{$line[1]}++;
    $edges{$line[2]}++;
    $total_edges++;
  }
  close FIN;
  $nodes = scalar(keys %nodes);
  my $ccount = 0;
  my (@x,@y);
  my $loss;
  for $loss(sort {$a <=> $b} keys %edges) {
     $ccount += $edges{$loss};  
     push @x,$loss;
     push @y,$ccount/$nodes; #The average degree is the number of edges over the number of nodes
  }
  #do a plot of the average degree versus the loss threshold
  if ($USE_GNUPLOT) {
    gnuplot ({
      "output type"=> "eps",
      "output file" => "$name.avg_degree.eps",
      "title" => "",
      "x-axis label" => "Loss Threshold",
      "y-axis label" => "Average degree",
     },
     [{title=>"", type=>'columns',style=>'linespoints',using=>'1:2'},\@x,\@y]
    );
  }
  

}

#graph
sub build_fixed_radius_graph {
  my $dbg = 0;
  my ($graph,$n,$density,$prefix) = @_;

  my ($i,$j);
  my ($l,$r,$b,$t);
  my ($x,$y,$xj,$yj);

  #get radius for target density
  my $frac = $density/$n;
  my $range = &get_range($frac);
  my $range2 = $range**2;
  my ($nodes,$min_x,$min_y,$max_x,$max_y);
  my $connected = 0;
  my $retries = $RETRIES;
  
  print STDERR  "build_fixed_radius_graph: $n nodes, density $density\n" if $dbg;
  $graph->{name} = "graph-n$n-d$density-r$nroots-sd$seed-$prefix";
  $graph->{range} = $range;
  
  do {
    #place the nodes
    $nodes = [];
    $min_x = $min_y = 1; $max_x = $max_y = 0;
    for ($i = 0; $i<$n; $i++) {
        $nodes->[$i]{'x'} = rand;
        $nodes->[$i]{'y'} = rand;
        print "\t node $i: ($nodes->[$i]{x},$nodes->[$i]{y})\n" if $dbg;
        $min_y = ($min_y > $nodes->[$i]{'y'})?$nodes->[$i]{'y'}:$min_y;
        $min_x = ($min_x > $nodes->[$i]{'x'})?$nodes->[$i]{'x'}:$min_x;        
        $max_y = ($max_y < $nodes->[$i]{'y'})?$nodes->[$i]{'y'}:$max_y;
        $max_x = ($max_x < $nodes->[$i]{'x'})?$nodes->[$i]{'x'}:$max_x;
    }
    #build the links
    # We will get the $DEGREE_LIMIT closest links
    for ($i = 0; $i<$n; $i++) {
      $x = $nodes->[$i]{'x'};
      $y = $nodes->[$i]{'y'};
    
      #get bounding box
      $l = $nodes->[$i]{'x'} - $range; if ($l < 0) {$l = 0;}
      $r = $nodes->[$i]{'x'} + $range; if ($r > 1) {$r = 1}
      $b = $nodes->[$i]{'y'} - $range; if ($b < 0) {$b = 0;}
      $t = $nodes->[$i]{'y'} + $range; if ($t > 1) {$t = 1;}
      for ($j = $i+1; $j < $n; $j++) {
        $xj = $nodes->[$j]{'x'};
        $yj = $nodes->[$j]{'y'};
        if ($xj >= $l && $xj <= $r &&
            $yj >= $b && $yj <= $t &&
            ((($x-$xj)*($x-$xj) + ($y-$yj)*($y-$yj)) <= $range2)
            && $nodes->[$i]->{'links'} < $DEGREE_LIMIT
            && $nodes->[$j]->{'links'} < $DEGREE_LIMIT
        ) {
          $nodes->[$i]->{'neighbors'}->[$j] = 1;
          $nodes->[$j]->{'neighbors'}->[$i] = 1;
          $nodes->[$i]->{'distance'}->[$j] = 1;
          $nodes->[$j]->{'distance'}->[$i] = 1;
          $nodes->[$i]->{'links'}++;
          $nodes->[$j]->{'links'}++;
        } else {
          $nodes->[$i]->{'neighbors'}->[$j] = 0;
          $nodes->[$j]->{'neighbors'}->[$i] = 0;
          $nodes->[$i]->{'distance'}->[$j] = $INF;
          $nodes->[$j]->{'distance'}->[$i] = $INF;

        }
      }
    }
    
    #check if connected
    $connected = &is_connected($nodes);
    $retries--;
    printf STDERR "Created graph with $n nodes. %sconnected. (retries left %d)\n",(($connected)?"It is ":"Not "),$retries;
  } while ($retries && !$connected);
  print STDERR  "done.\n";
  if (!$connected) {
    print STDERR "Giving up. Graph is not connected, increase density\n";
    return 0;
  }
  my $avg_degree = &get_average_degree($nodes);
  my $max_degree = &get_max_degree($nodes);
  printf STDERR "Average degree: %f, Max degree: %d, Desired: %d\n",$avg_degree,$max_degree,$density;
  print "x: [$min_x,$max_x] y: [$min_y,$max_y]\n" if $dbg;
  $graph->{avg_degree} = $avg_degree;
  $graph->{max_degree} = $max_degree;
  $graph->{nodes} = $nodes;
  $graph->{n} = scalar(@$nodes);
  $graph->{min_x} = $min_x;
  $graph->{min_y} = $min_y;
  $graph->{max_x} = $max_x;
  $graph->{max_y} = $max_y;      
  return 1;
}

##############################
#pick roots randomly in the graph
sub pick_roots_randomly {
  my $dbg = 1;
  my ($graph,$nroots) = @_;
  my $pos;
  if ($nroots > $graph->{n}) {
    print STDERR "Random roots: roots ($nroots) > nodes ($graph->{n}!!\n";
    return 0;
  }
  my @nodes = (0..($graph->{n}-1));
  while ($nroots--) {
    #get a random node
    $pos = rand(scalar(@nodes));
    push @{$graph->{roots}}, splice (@nodes,$pos,1);
  }
  my $i;
  for ($i = 0; $i < scalar (@{$graph->{roots}}); $i++) {
    $graph->{root_id}->{$graph->{roots}->[$i]} = $i;
  }
  if ($dbg) {
    printf STDERR "pick random: nodes:$graph->{n}, roots:%s\n",(join ",",@{$graph->{roots}});
  }
}

#will pick n roots in sequence. At each step the root chosen is the node
#with the maximum smallest distance to any other root
#
#sub pick_n_roots_max_min {
#  my ($graph,$nroots) = @_;
#  find node closest to (1,0) corner
#  roots <- n
#  while (roots < nroots)
#    get distance from this root to all other nodes (run djikstra)
#    fill nodes->dists[root]
#    get the next beacon:
#    for $n ($nodes) 
#      next if node is a beacon
#      get smallest distance to any beacon
#      if $closest < smallest
#        smallest = closest
#        new_beacon = n
#    }
#    add root
#    roots++
#  } 
#}
#

sub pick_n_roots_edges {
  my $PI = 3.1415926;
  my $r = sqrt(2)/2;
  my $dbg = 1;
  my ($graph,$nroots) = @_;
  my ($n,@roots,$i,$j,@min_dist,@min_dist_node,$d,%uniq);
  my  $theta;
  my (@x,@y);
  
  #find n points equally spaced in the circle that circumscribes
  #the graph area: center at 0.5,0.5, radius sqrt(2)/2;
  # the first point will be at (1,0)
  for ($j = 0; $j < $nroots; $j++) {
    $theta = $PI*($j*2/$nroots - 0.25);
    $x[$j] = $r*cos($theta)+0.5;
    $y[$j] = $r*sin($theta)+0.5;
  }
  #find the nodes closest to each corner
  for ($i = 0; $i < $graph->{n}; $i++) {
    $n = $graph->{nodes}->[$i];
    for ($j = 0; $j < $nroots; $j++) {
      $d = ($n->{'x'} - $x[$j])**2 +
           ($n->{'y'} - $y[$j])**2;
      if (defined $min_dist[$j]) {
         if ($d < $min_dist[$j]) {
           $min_dist[$j] = $d;
           $min_dist_node[$j] = $i;
         }
      }
      else {
        $min_dist[$j] = $d;
        $min_dist_node[$j] = $i;
      }
    }
  }
  for $n (@min_dist_node) {
    push @roots,$n if !(defined $uniq{$n});
    $uniq{$n}=1;
  }
  $graph->{roots} = \@roots;
  for ($i = 0; $i < scalar (@roots); $i++) {
    $graph->{root_id}->{$roots[$i]} = $i;
  }
}

#Breadth first search
sub is_connected {
  #receives a reference to the nodes array
  my $n_ref = shift;
  my $n = scalar (@$n_ref);
  
  my @queue;
  my $node;
  my $color;
  my @color; #0 - white, 1 - gray, 2 - black
  my ($i,$j);
  
  for ($i = 0; $i < $n; $i++) {
    $color[$i] = 0;
  }
  
  push @queue, 0;
  while (scalar (@queue) > 0) {
    $i = shift @queue;
    for ($j = 0; $j < $n; $j++) {
      if ($n_ref->[$i]->{'neighbors'}->[$j] && $color[$j] == 0) {
        $color[$j] = 1;
        push @queue, $j;
      }
    }
    $color[$i] = 2;
  } 
  
  my $connected = 1;
  for $color (@color) {
    if ($color != 2) {
      $connected = 0;
      last;
    }
  }
  return $connected; 
}

sub get_average_degree($nodes) {
  my $dbg = 0;
  my ($nodes) = @_;
  my $n = scalar(@$nodes);
  my ($i,$j);
  my ($degree,$degree_sum);
  print "get_average_degree: n $n\n";
  for ($i = 0; $i < $n; $i++) {
    $degree = 0;
    for ($j = 0; $j < $n; $j++) {
      $degree += $nodes->[$i]->{'neighbors'}->[$j];
    }
    $degree_sum += $degree;
  }
  return $degree_sum/$n;
}
sub get_max_degree($nodes) {
  my $dbg = 0;
  my ($nodes) = @_;
  my $n = scalar(@$nodes);
  my ($i,$j);
  my ($degree,$max);
  $max = 0;
  print "get_average_degree: n $n\n";
  for ($i = 0; $i < $n; $i++) {
    $degree = 0;
    for ($j = 0; $j < $n; $j++) {
      $degree += $nodes->[$i]->{'neighbors'}->[$j];
    }
    $max = $degree if ($degree > $max);
  }
  return $max;
}

                                                           
#Returns the range for the radius of the motes over a unit square
#so that the expected number of neighbors is the given fraction of
#the total number of nodes                                 
sub get_range {                                            
  my $d = shift;                                           
  my ($a,$b,$m,$n);
                                                           
  my $limit = 0.18696866; #limit between the two functions 
                                                           
  #function 1 is the inverse of a quadratic (close to pi*r^2)
  #r = a/sqrt(pi)*d^(1/b)                                  
  $a = 0.7544141719; # a/sqrt(pi)                         
  $b = 0.5895840099; # 1/b                                
                                                           
  #function 2 is the inverse of a transformed logistic function
  #d = 1/(1+exp(-n(r-m))                                   
  #r = log( exp(m) * (d/(1-d))^(1/n) )                     
  $m = 1.6755158086;                                       
  $n = 0.1601629133;                                       
                                                           
  if ($d < 0 || $d > 1) {                                  
    warn("$d is out of range");                            
  }                                                        
                                                           
  if ($d==1) {return sqrt(2.0)};                           
  if ($d==0) {return 0.0};                                 
                                                           
  if ($d <= $limit) {                                      
     return $a*($d**$b);                                   
  } else {                                                 
     return log( $m * (($d/(1-$d)) ** $n) );               
  }                                                        
}

#format:
#mote <id> <ip> <x> <y>
sub output_testbed_config {
  my $graph = shift;
  my $i;
  open FH,">$graph->{name}.testbed.cfg" or return -1;
  for ($i = 0; $i < $graph->{n}; $i++) {
    print FH "mote $i 0.0.0.0 $graph->{nodes}->[$i]{x} $graph->{nodes}->[$i]{y}\n";
  }
  close FH;  
}


#header file (for static neighborhood information)
#format: define N_NODES, N_ROOT_BEACONS, and hc_is_root_beacon and hc_root_beacon_id
sub output_nogeo_h {
  my $graph = shift;
  my $n = $graph->{n};
  my $i;
  #print $graph->{roots};
  my $nbeacons = scalar(@{$graph->{roots}});

  my $diameter = POSIX::ceil(sqrt($n));
  my $INVALID_BEACON_ID = "0xff";
  
  open FH,">$graph->{name}.topology.h" or return -1;
  print FH <<EOT;
/* This file autogenerated by generate_topology.pl. Do not edit
 * Parameters: n:$nnodes density:$density roots:$nroots root placement:$root_type seed:$seed
 * Author: Rodrigo Fonseca
 */
#ifndef TOPOLOGY_H
#define TOPOLOGY_H
enum {
  N_NODES = $n,
  N_ROOT_BEACONS = $nbeacons,
  DIAMETER = $diameter, 
  INVALID_BEACON_ID = 0xff,
};

uint8_t hc_root_beacon_id[N_NODES] = {
EOT
  printf FH "  %4s",(defined $graph->{root_id}->{0})?$graph->{root_id}->{0}:$INVALID_BEACON_ID;
  for ($i = 1; $i < $n; $i++) {
    print FH ", ";
    print FH "\n  " if (($i % 10) == 0);
    printf FH "%4s",(defined $graph->{root_id}->{$i})?$graph->{root_id}->{$i}:$INVALID_BEACON_ID;
  }
  print FH "\n};\n";
  print FH "#endif\n";
  close FH;
  return 0;
}

sub write_lossless_tossim_file {
  my ($graph) = @_;
  my ($node,$other);
  open FH,">$graph->{name}.pkt_lossless" or die "Can't create pkt_lossless file\n";
	for ($node = 0; $node < $graph->{n}; $node++) {
	  for ($other = $node; $other < $graph->{n}; $other++) {
		#add edge: $node to its other and the symmetric one
			if ($graph->{nodes}->[$node]->{neighbors}->[$other]) {
		    printf FH "$node $other 0.0 0.0 0.0\n";
      }
			if ($graph->{nodes}->[$other]->{neighbors}->[$node]) {
		    printf FH "$other $node 0.0 0.0 0.0\n";
      }
	  }
	}
  close FH;
}

sub draw_neighbor_tables {
  my ($graph) = @_;
  my $GRAPH_SIZE = 8;

	#create a file with the root graph
	my $fname = "$graph->{'name'}.neighbor-tables.dot";
	my ($node,$coords,$look,$r,$other);
	open DOT,">$fname" or die "Can't open $fname\n";
	print DOT<<DOT_SETUP ;
graph G{
	size="$GRAPH_SIZE"
	bb="0,0,$GRAPH_SIZE,$GRAPH_SIZE"
	node [
		shape=circle
		fontsize=5
		height = 0.1
	]

DOT_SETUP
	#vertices
	for ($node = 0; $node < $graph->{n}; $node++) {
	  #$coords = join ",", @{$graph->{nodes}->[$node]->{'coords'}};
    $coords = "";
		$look = "";$r = "";
		if (exists $graph->{root_id}->{$node}) {
			$look = ",fontsize = 7,color=grey"; 
			$r = "($graph->{root_id}->{$node})";
		}
		printf DOT "\tnode$node [label = \"$node$r\\n$coords\",pos=\"%f,%f!\"%s]\n", 
		   $graph->{nodes}->[$node]->{'x'}*$GRAPH_SIZE, $graph->{nodes}->[$node]->{'y'}*$GRAPH_SIZE, $look;
	}
	#edges
	print DOT "\n";
	for ($node = 0; $node < $graph->{n}; $node++) {
	  for ($other = $node; $other < $graph->{n}; $other++) {
		#add edge: $node to its other
		printf DOT "\t \"node$node\" -- \"node$other\"\n"
			if ($graph->{nodes}->[$node]->{neighbors}->[$other]);
	  }
	}
	print DOT "}\n"; 
	close DOT;

	my $eps_name = "$fname.eps";
	my $png_name = "$fname.png";
	print "Running neato on $fname\n";
	`neato -T ps $fname -o $eps_name`;  
	#`convert -density 200 $eps_name $png_name`;
	#`rm $fname`;
}
################



