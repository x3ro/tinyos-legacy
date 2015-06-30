#!/usr/bin/perl
use FindBin qw($Bin);

$basedir = $Bin."../..";

push @messages, (
  {class=>'BVRRawMessage'            ,extends=>'none'         ,struct=>'BVR_Raw_Msg',file=>"$basedir/contrib/bvr/bvr/BVR.h"},
  {class=>'BVRBeaconMessage'         ,extends=>'BVRRawMessage',struct=>'BVR_Beacon_Msg',file=>"$basedir/contrib/bvr/bvr/BVR.h"},
  {class=>'BVRAppMessage'            ,extends=>'BVRRawMessage',struct=>'BVR_App_Msg',file=>"$basedir/contrib/bvr/bvr/BVR.h"},
  {class=>'BVRCommandMessage'        ,extends=>'BVRRawMessage',struct=>'BVR_Command_Msg',file=>"$basedir/contrib/bvr/command/BVRCommand.h"},
  {class=>'BVRCommandResponseMessage',extends=>'BVRRawMessage',struct=>'BVR_Command_Response_Msg',file=>"$basedir/contrib/bvr/command/BVRCommand.h"},
  {class=>'BVRReverseLinkMessage'    ,extends=>'BVRRawMessage',struct=>'LE_Reverse_Link_Estimation_Msg',file=>"$basedir/contrib/bvr/linkestimator/ReverseLinkInfo.h"},
  {class=>'BVRLogMessage'            ,extends=>'BVRRawMessage',struct=>'BVR_Log_Msg',file=>"$basedir/contrib/bvr/util/Logging.h"}
);

$template_cmd = "mig -I $basedir/contrib/bvr/bvr -I $basedir/contrib/bvr/command -I $basedir/contrib/bvr/commstack -I $basedir/contrib/bvr/linkestimator -I $basedir/contrib/bvr/util -java-classname=net.tinyos.bvr.messages.%s -o $basedir/tools/java/net/tinyos/bvr/messages/%s.java -target=mica2 java %s %s";
for $message (@messages) {
  $cmd = sprintf $template_cmd, $message->{class},$message->{class},$message->{file},$message->{struct};
  print "Running $cmd\n";
  `$cmd`;
  `javac $basedir/tools/java/net/tinyos/bvr/messages/$message->{class}.java`;
}

