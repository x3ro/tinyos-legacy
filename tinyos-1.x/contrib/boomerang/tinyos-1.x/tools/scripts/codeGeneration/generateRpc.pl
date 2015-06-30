#!/usr/bin/perl -w

# "Copyright (c) 2000-2003 The Regents of the University of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement
# is hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
# OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
# @author Kamin Whitehouse 
#

use XML::Simple;
use strict;
use FindBin;
use lib $FindBin::Bin;
use AtTags;
use NescParser;

my $DestDir = "";
my $useLeds = 0;

#get rid of extraneous arguments
my @args = @ARGV;
@ARGV = ();
while (@args){
    my $arg = shift @args;
    if ($arg eq "-DRPC_LEDS"){
	$useLeds = 1;
    }
    elsif ($arg eq "-d") {
        $DestDir = shift @args;
        $DestDir .= "/" unless $arg =~ m{/$}; 
    } elsif ($arg !~ m/^-[^I]/) {
	push @ARGV, $arg;
    }
}

#}
#add a few more directories that should always be on the search path
unshift ( @ARGV, "-I".$ENV{'TOSDIR'}."/types/" );
unshift ( @ARGV, "-I".$ENV{'TOSDIR'}."/interfaces/" );
unshift ( @ARGV, "-I".$ENV{'TOSDIR'}."/system/" );
unshift ( @ARGV, "-I".$ENV{'PWD'}."/" );


#make sure the user knows what's going on:
my $s = "generateRpc.pl ";
for my $arg (@ARGV) {
    $s = sprintf "%s %s", $s, $arg;
}
print $s, "\n";

my $nescXml = pop(@ARGV);

##############################
# look through the @rpc tags to find all unique rpc instances
##############################

my ($taggedInterfaces, $includes) = AtTags::getTaggedInterfaces(@ARGV, "rpc", ());
my ($taggedFunctions, $includesB) = AtTags::getTaggedFunctions(@ARGV, "rpc", ());

for my $include (keys %$includesB){
    $includes->{$include} = 1;
}

##############################
# look through the code and get definitions of all interfaces
##############################

my $interfaces = NescParser::getInterfaces($nescXml);

##############################
# load the struct definitions 
##############################

#my $structs = NescParser::getStructs($nescXml);
#print "there are %d structs\n\n",scalar keys %$structs;

##############################
# go through all tagged interfaces and functions and come up with
# complete list of rpc functions
#
# The desired structure is the following, and will be used to create
# rpc.schema 
#
# %rpcFunctions--->fullName--->commandNumber
#                           |->componentName
#                           |->interfaceName
#                           |->functionName
#                           |->provided
#                           |->functionType
#                           |->returnType
#                           |->%params
#
# where "fullName" is either moduleM.interface.func or moduleM.func.
#
# while creating this structure, we also check the validity criteria below:
##############################

my %rpcFunctions;
my %requiredFunctions;
my $fullName;
my $shouldDie=0;

# add each tagged function
for my $taggedFunction (@$taggedFunctions){
    $fullName = $taggedFunction->{'componentName'}.".".$taggedFunction->{'functionName'};
    checkRpcFunction($taggedFunction, $fullName);
    $rpcFunctions{$fullName} = $taggedFunction;
}

# add each function in each tagged interface
for my $taggedInterface (@$taggedInterfaces){
    my $interface;
    my $functions;
    if ($interfaces->{$taggedInterface->{'interfaceType'}}){
	$interface = $interfaces->{$taggedInterface->{'interfaceType'}};
	$functions = $interface->{'functions'};
    }
    else{
	print "WARNING: rpc interface $taggedInterface->{'interfaceType'} not found.";
    }
    while (my ($functionName, $function) = each (%$functions) ){
	my %rpc;
	$rpc{'componentName'} = $taggedInterface->{'componentName'};
	$rpc{'interfaceType'} = $taggedInterface->{'interfaceType'};
	$rpc{'interfaceName'} = $taggedInterface->{'interfaceName'};
	$rpc{'functionName'} = $functionName;
	$rpc{'provided'} = $taggedInterface->{'provided'};
	$rpc{'functionType'} = $function->{'functionType'};
	$rpc{'returnType'} = $function->{'returnType'};
	$rpc{'params'} = $function->{'params'};
	if ($interface->{'abstract'}==1){
	    $rpc{'gparams'} = $taggedInterface->{'gparams'};
	    $rpc{'returnType'} = &substituteAbstractTypes($rpc{'returnType'},
							  $interface->{'gparams'}, 
							  $taggedInterface->{'gparams'});
	    $rpc{'params'} = &substituteAbstractParams($rpc{'params'},
						       $interface->{'gparams'}, 
						       $taggedInterface->{'gparams'});
	}
	$rpc{'numParams'} = $function->{'numParams'};
	$fullName = $rpc{'componentName'}.".".$rpc{'interfaceName'}.".".$rpc{'functionName'};
	if (checkRpcFunction(\%rpc, $fullName)){
	    $requiredFunctions{$fullName} = \%rpc;
	}
	else{
	    $rpcFunctions{$fullName} = \%rpc;
	}
    }
}
    
#The following variable is set in the checkRpcFunction subroutine.
#We wait until after all functions are checked before dieing so that
#we can get all error messages at once
if ($shouldDie == 1) { die "Too many errors.";}
    




##############################
# Number the rpc functions alphabetically
##############################

my $count = 0;
my $rpc;
for $fullName (sort keys %rpcFunctions ) {
    $rpc = $rpcFunctions{$fullName};
    $rpc->{'commandID'} = $count++;
}



##############################
# print out the parsed info for debugging/user knowledge.
# Simultaneously, generate each rpc function signature.
##############################
my $params;
my $bspace = sprintf "\b";

if (keys %rpcFunctions){
    $s = "Adding rpc functions:\n"; 
    for $fullName (sort keys %rpcFunctions ) {
	$rpc = $rpcFunctions{$fullName};
	my $signature = sprintf "%25s %s ( ", "$rpc->{'functionType'} $rpc->{'returnType'}->{'typeDecl'}", $fullName;
	my $sigLength = length($signature);
	$params = $rpc->{'params'};
	for ($count=0; $count < $rpc->{'numParams'} ; $count++,)
	{
	    if ($count>0){
		$signature .= sprintf "\n%${sigLength}s%s,","",
		$params->{"param$count"}->{'type'}->{'typeDecl'}." ".$params->{"param$count"}->{'name'}; 
	    }
	    else{
		$signature .= sprintf "%s %s,",
		$params->{"param$count"}->{'type'}->{'typeDecl'},
		$params->{"param$count"}->{'name'};
	    }
	}
	$signature .= sprintf "\b )\n";	
	$s .= $signature;
	$signature =~ s/\s+/ /g;
	$signature =~ s/.$bspace/ /g;
	$rpc->{'signature'} = $signature;
    }
    print "$s\n"; 
}
else{
    print "** Warning: no RPC functions found.\n\n"; 
}	


##############################
# print out in XML format for the PC-side tools
##############################


my $xs1 = XML::Simple->new();

my %xmlOutHash = ();
$xmlOutHash{'rpcFunctions'} = \%rpcFunctions;
my %tmpHash = ();
#$tmpHash{'struct'} = $structs;
#$xmlOutHash{'structs'} = \%tmpHash;
my $str = $xs1->XMLout(\%xmlOutHash, RootName=>"rpcSchema", KeyAttr=>{'attribute'=>'name', 'event'=>'name', 'symbol'=>'name'}, XMLDecl=>1);

SlurpFile::dump_file( "${DestDir}rpcSchema.xml", "$str" );

##############################
# Create a warning at the top of each generated file
##############################

my $G_warning =<< 'EOF';
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***
// ***                                                                     ***
// *** This file was automatically generated by generateRpc.pl.   ***
// *** Any and all changes made to this file WILL BE LOST!                 ***
// ***                                                                     ***
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***

EOF


my $yellowToggle = "";
my $greenToggle = "";
my $redToggle = "";
my $Leds = "";
my $LedsC = "";
my $ledsWiring = "";
if ($useLeds) {
    $yellowToggle = "call Leds.yellowToggle();";
    $greenToggle = "call Leds.greenToggle();";
    $redToggle = "call Leds.redToggle();";
    $Leds = "interface Leds;";
    $LedsC = "LedsC,";
    $ledsWiring = "RpcM.Leds -> LedsC;"
}
##############################
# Generate the RpcM.nc file
##############################

$includes->{'#ifndef RPC_NO_DRAIN
includes Drain; 
#endif // !RPC_NO_DRAIN'}=1;
$includes->{'includes Rpc;'}=1;

$s = "";
for my $include (keys %$includes){
    $s .= "$include\n";
}

$s .= "
module RpcM {
  provides {
    interface StdControl;

    /*** events that are rpc-able ***/
";

my $componentName="";
my $interfaceName="";
my $gparams = "";

# generate the "provides" declarations of rpc-able events
for $fullName (sort keys %rpcFunctions ) {
    $rpc = $rpcFunctions{$fullName};
    if ($rpc->{'provided'} == 1){
	next;
    }

    if ($rpc->{'interfaceName'}){
	if ( $componentName ne $rpc->{'componentName'} ||
	     $interfaceName ne $rpc->{'interfaceName'} ) {
	    $componentName = $rpc->{'componentName'};
	    $interfaceName = $rpc->{'interfaceName'};
	    $gparams = "";
	    if ($rpc->{'gparams'}){
		$gparams = "<";
		for my $gparam (@{$rpc->{'gparams'}}) {
		    $gparams .= $gparam;
		}		
		$gparams .= ">";
	    }
	    $s = sprintf "%s    interface $rpc->{'interfaceType'}$gparams as $componentName\_$interfaceName;\n", $s;
	}
    }
    else{
	print keys %$rpc;
	$params = $rpc->{'params'};
	$s = sprintf "%s    $rpc->{'functionType'} $rpc->{'returnType'}->{'typeDecl'} $rpc->{'componentName'}_$rpc->{'functionName'} (  ", $s;
	for ($count=0; $count < $rpc->{'numParams'} ; $count++)
	{
	    $s = sprintf "%s %s %s,", $s, $params->{"param$count"}->{'type'}->{'typeDecl'},  $params->{"param$count"}->{'name'};
	}
	$s = sprintf "%s\b );\n", $s;	
    }
}

$s = sprintf "%s  }
  uses {
    interface StdControl as SubControl;
    $Leds

    interface ReceiveMsg as CommandReceiveLocal;

    interface SendMsg as ResponseSendMsg;
#ifndef RPC_NO_DRAIN
    interface Send as DrainSend; // only used for the getBuffer(), when we are using Drain
#endif // !RPC_NO_DRAIN
//    interface SendMsg as ErrorSendMsgDrain;


#ifndef RPC_NO_DRIP
    interface Receive as CommandReceiveDrip;
    interface Drip as CommandDrip;
    interface Dest;
#endif // !RPC_NO_DRIP

    /*** commands that are rpc-able ***/

", $s;

# generate the "uses" declarations of rpc-able commands
for $fullName (sort keys %rpcFunctions ) {
    $rpc = $rpcFunctions{$fullName};
    if ($rpc->{'provided'} == 0){
	next;
    }

    if ($rpc->{'interfaceName'}){
	if ( $componentName ne $rpc->{'componentName'} ||
	     $interfaceName ne $rpc->{'interfaceName'} ) {
	    $gparams = "";
	    if ($rpc->{'gparams'}){
		$gparams = "<";
		for my $gparam (@{$rpc->{'gparams'}}) {
		    $gparams .= $gparam;
		}		
		$gparams .= ">";
	    }
	    $componentName = $rpc->{'componentName'};
	    $interfaceName = $rpc->{'interfaceName'};
	    $s = sprintf "%s    interface $rpc->{'interfaceType'}$gparams as $componentName\_$interfaceName;\n", $s;
	}
    }
    else{
	$params = $rpc->{'params'};
	$s = sprintf "%s    $rpc->{'functionType'} $rpc->{'returnType'}->{'typeDecl'} $rpc->{'componentName'}_$rpc->{'functionName'} (  ", $s;
	for ($count=0; $count < $rpc->{'numParams'} ; $count++)
	{
	    $s = sprintf "%s %s %s,", $s, $params->{"param$count"}->{'type'}->{'typeDecl'},  $params->{"param$count"}->{'name'};
	}
	$s = sprintf "%s\b );\n", $s;	
    }
}


# build lists of the arguments and return sizes
my $num_rpcs = keys %rpcFunctions;
my @rpc_args_sizes = ();
my @rpc_return_sizes = ();
for $fullName (sort keys %rpcFunctions) {
  $rpc = $rpcFunctions{$fullName};
  my @as = ();
  for( my $n=0; $n < $rpc->{numParams} ; $n++ ) {
    my $p = $rpc->{params}{"param$n"}{type}{typeName};
    push( @as, "sizeof($p)" );
  }    
  push( @rpc_args_sizes, join("+",@as) || "0" );
  push( @rpc_return_sizes, "sizeof($rpc->{returnType}{typeName})" );
}
my $rpc_args_elems = "    " . join( ",\n    ", @rpc_args_sizes );
my $rpc_return_elems = "    " . join( ",\n    ", @rpc_return_sizes );

my $d = '%d';
$s .=<<"EOF";
  }
}
implementation {

  TOS_Msg dripStore;
  TOS_Msg cmdStore;
  TOS_Msg responseMsgBuf;
  TOS_MsgPtr responseMsgPtr;
  uint16_t dripStoreLength;
  uint16_t cmdStoreLength;
  uint16_t queryID;
  uint16_t returnAddress;
  bool processingCommand;
  bool sendingResponse;

  static const uint8_t args_sizes[$num_rpcs] = {
$rpc_args_elems
  };

  static const uint8_t return_sizes[$num_rpcs] = {
$rpc_return_elems
  };

  command result_t StdControl.init() {
    responseMsgPtr = &responseMsgBuf;
    processingCommand=FALSE;
    sendingResponse=FALSE;
    call SubControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
#ifndef RPC_NO_DRIP
    call CommandDrip.init();
#endif // !RPC_NO_DRIP
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void processCommand(){
    RpcCommandMsg* msg = (RpcCommandMsg*)cmdStore.data;
    uint8_t* byteSrc = msg->data;
    uint16_t maxLength;
    uint16_t id = msg->commandID;
#ifdef RPC_NO_DRAIN    
    RpcResponseMsg *responseMsg = (RpcResponseMsg*)(responseMsgPtr->data);
    maxLength = TOSH_DATA_LENGTH;
#else 
    RpcResponseMsg *responseMsg = (RpcResponseMsg*)call DrainSend.getBuffer(responseMsgPtr, &maxLength);
#endif // RPC_NO_DRAIN    

    dbg(DBG_USR2, "processing command id %d, transaction %d\\n", msg->commandID, msg->transactionID);
    $greenToggle

    if ( sendingResponse == TRUE ) {
      dbg(DBG_USR2, "stopped processing because sending\\n");
      post processCommand();
      $yellowToggle
      return;
      
    }

    if ( processingCommand == TRUE ) {
      dbg(DBG_USR2, "stopped processing because already processing\\n");
      $yellowToggle
      return;
    }
    else {
      processingCommand = TRUE;
    }

    /*fill in the response message headers*/
    responseMsg->transactionID = msg->transactionID;
    responseMsg->commandID = msg->commandID;
    responseMsg->sourceAddress = TOS_LOCAL_ADDRESS;
    responseMsg->errorCode = RPC_SUCCESS;
    responseMsg->dataLength = 0;

    if( (id < $num_rpcs) && (msg->dataLength != args_sizes[id]) ) {
      responseMsg->errorCode = RPC_GARBAGE_ARGS;
      dbg(DBG_USR2, "param size doesn't match\\n");
    } else if( (id < $num_rpcs) && (return_sizes[id] + sizeof(RpcResponseMsg) > maxLength) ) {
      responseMsg->errorCode = RPC_RESPONSE_TOO_LARGE;
      dbg(DBG_USR2,"Return type is too large for the response packet");
    } else switch( id ) {
EOF

#this is the heart of rpc: parse the args, call the func, pack the return
for $fullName (sort keys %rpcFunctions ) {
    $rpc = $rpcFunctions{$fullName};
    $params = $rpc->{'params'};
    $s = sprintf "%s\n      /*** $fullName ***/\n", $s;
    $s = sprintf "%s  case $rpc->{'commandID'}: {\n", $s;

    #get ready with a returnVal decl if necessary
    if ( $rpc->{'returnType'}->{'typeName'} ne 'void') {
        my $ptr = $rpc->{returnType}{typeClass} eq 'pointer' ? "*" : "";
	$s .= "    $rpc->{returnType}{typeName}$ptr RPC_returnVal;\n";
    }

    #setup the parameters
    for ( $count=0 ; $count < $rpc->{'numParams'} ; $count++)
    {
	$s = sprintf "%s    %s RPC_%s;\n", $s,
	$params->{"param$count"}->{'type'}->{'typeName'}, $params->{"param$count"}->{'name'};
    }    

    $s = sprintf "%s      dbg(DBG_USR2, \"handling commandId $rpc->{'commandID'}\\n\");\n",$s;

    for ( $count=0 ; $count < $rpc->{"numParams"} ; $count++)
    {
        my $name = "RPC_" . $params->{"param$count"}{name};
        my $type = $params->{"param$count"}{type}{typeName};
        $s .= "    memcpy( &$name, byteSrc, sizeof($type) );\n";
	$s .= "    byteSrc += sizeof($type);\n" if $count != ($rpc->{numParams}-1);
    }    

    #store the return value appropriately
    $s = sprintf "%s    ", $s;

    if ( $rpc->{'returnType'}->{'typeName'} ne 'void') {
	$s .= "RPC_returnVal = ";
    }

    #"call" commands or "signal" events
    if ($rpc->{'functionType'} eq "command"){
	$s = sprintf "%scall", $s;
    }
    elsif ($rpc->{'functionType'} eq "event"){
	$s = sprintf "%ssignal", $s;
    }

    #actually invoke the function with arguments
    $s = sprintf "%s $rpc->{'componentName'}_",$s;
    if ( $rpc->{'interfaceName'} ){
	$s = sprintf "%s$rpc->{'interfaceName'}.", $s;
    }
    $s = sprintf "%s$rpc->{'functionName'}( ", $s;
    for ( $count=0; $count < $rpc->{'numParams'} ; $count++)
    {
	my $str = "RPC_".$params->{"param$count"}->{'name'};
	$str = "&$str" if $params->{"param$count"}{type}{typeClass} eq "pointer";
	$s .= " $str,";
    }
    $s = sprintf "%s\b );\n", $s;

    #store the return value, if necessary
    if ( $rpc->{returnType}{typeName} ne 'void') {
      my $rvArg = ($rpc->{returnType}{typeClass} eq 'pointer' ? "" : "&") . "RPC_returnVal";
      $s .= "    memcpy( &responseMsg->data[0], $rvArg, sizeof($rpc->{returnType}{typeName}) );\n";
    }

    $s = sprintf "%s      dbg(DBG_USR2, \"done calling the functions\\n\");\n",$s;

    #mark the size of the return value
    if ( $rpc->{'returnType'}->{'typeName'} ne 'void' ){
	$s = sprintf "%s    responseMsg->dataLength = sizeof ( %s );
      dbg(DBG_USR2, \"responseMsg->dataLength = %s\\n\", responseMsg->dataLength);
      dbg(DBG_USR2, \" sizeof ( %s )= %s\\n\", sizeof ( %s ));
  } break;
", $s, $rpc->{'returnType'}->{'typeName'}, $d,
    $rpc->{'returnType'}->{'typeName'}, $d,
    $rpc->{'returnType'}->{'typeName'};
    }
    else {
	$s = sprintf "%s      dbg(DBG_USR2, \"not packing void return value\\n\");
  } break;
", $s;
    }
}
#phew!

$s = sprintf "%s
    default:
        dbg(DBG_USR2, \"found no rpc function\\n\");
      responseMsg->errorCode = RPC_PROCEDURE_UNAVAIL;
    }
    /*** now send the response message off if necessary ***/
    dbg(DBG_USR2, \"errorCode=%s,dataLength=%s\\n\",responseMsg->errorCode, responseMsg->dataLength);
    dbg(DBG_USR2, \"sizeof( RpcResponseMsg ) = %s, data-transactionID= %s\\n\",sizeof (RpcResponseMsg),((uint32_t)&(responseMsg->data[0]) - (uint32_t)&(responseMsg->transactionID)));
 /*   if (responseMsg->errorCode == RPC_SUCCESS && responseMsg->dataLength==0){
      dbg(DBG_USR2, \"done processing, no return args\\n\");
      processingCommand=FALSE;
    }
    else if (responseMsg->errorCode == RPC_SUCCESS){
      //calculate the size to be the size of the data I just added 
      //plus the size of the responseMsg less the data array (the data array 
      //can sometimes take space due to compiler packing)
      if (call ResponseSendMsgDrain.send(msg->returnAddress,
				    responseMsg->dataLength + ( (uint32_t)&(responseMsg->data[0]) - (uint32_t)&(responseMsg->transactionID)),
				    responseMsgPtr) ){
        dbg(DBG_USR2, \"sending response\\n\");
        sendingResponse=TRUE;
      }
      else{
        dbg(DBG_USR2, \"sending response failed\\n\");
        processingCommand=FALSE;
      }
    }
    else{*/
      if (msg->responseDesired == 0){
        dbg(DBG_USR2, \"no response desired; not sending response message\");
        processingCommand=FALSE;
      }
      else if (call ResponseSendMsg.send(msg->returnAddress,
				         responseMsg->dataLength + sizeof(RpcResponseMsg),
				         responseMsgPtr) ){
        dbg(DBG_USR2, \"sending response\\n\");
        sendingResponse=TRUE;
        $redToggle
      }
      else{
        dbg(DBG_USR2, \"sending response failed\\n\");
        processingCommand=FALSE;
        $yellowToggle
      }
//    }
    dbg(DBG_USR2, \"done processing.\\n\");
  }

#ifndef RPC_NO_DRIP
  event TOS_MsgPtr CommandReceiveDrip.receive(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLength) {
    RpcCommandMsg* msg = (RpcCommandMsg*)payload;

    dbg(DBG_USR2, \"received drip command message\\n\");

    //store the drip message for later drip rebroadcasting
    memcpy(dripStore.data, payload, payloadLength);
    dripStoreLength = payloadLength;

    //if it is destined to us, post a task to process it
    if (msg->address == TOS_LOCAL_ADDRESS || msg->address == TOS_BCAST_ADDR ) {
      //store another copy for later processing
      memcpy(cmdStore.data, payload, payloadLength);
      cmdStoreLength = payloadLength;

      if (post processCommand() == SUCCESS){
        dbg(DBG_USR2, \"posted task\\n\");
      } 
      else{
        dbg(DBG_USR2, \"failed to post task\\n\");
      }
    }
    else {
      dbg(DBG_USR2, \"not posting task because not for me\\n\");
    }

    return pMsg;
  }
#endif // !RPC_NO_DRIP

  event TOS_MsgPtr CommandReceiveLocal.receive(TOS_MsgPtr pMsg) {
    //store the message for later processing
    dbg(DBG_USR2, \"received local command message, len=%s\\n\",pMsg->length);
    memcpy(cmdStore.data, pMsg->data, pMsg->length);
    cmdStoreLength = pMsg->length;
    if (post processCommand() == SUCCESS){
      dbg(DBG_USR2, \"posted task\\n\");
    } 
    else{
      dbg(DBG_USR2, \"failed to post task\\n\");
    }
    return pMsg;
  }

#ifndef RPC_NO_DRIP
  event result_t CommandDrip.rebroadcastRequest(TOS_MsgPtr msg, void *payload) {
    dbg(DBG_USR2, \"drip rebroadcast request\\n\");
    memcpy(payload, dripStore.data, dripStoreLength);
    call CommandDrip.rebroadcast(msg, payload, dripStoreLength);    
    return SUCCESS;
  }
#endif // !RPC_NO_DRIP

#ifndef RPC_NO_DRAIN
  event result_t DrainSend.sendDone(TOS_MsgPtr pMsg, result_t success) {
    dbg(DBG_USR2, \"wtf!!  drainSend send done\\n\");
    return SUCCESS;
  }
#endif // !RPC_NO_DRAIN
  event result_t ResponseSendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (success == SUCCESS) {
      dbg(DBG_USR2, \"drain send done: SUCCESS\\n\");
    }
    else{
      dbg(DBG_USR2, \"drain send done: FAIL\\n\");
    }
    processingCommand = FALSE;
    sendingResponse = FALSE;
    return SUCCESS;
  }
/*  event result_t ErrorSendMsgDrain.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (success == SUCCESS) {
      dbg(DBG_USR2, \"drain error send done: SUCCESS\\n\");
    }
    else{
      dbg(DBG_USR2, \"drain error send done: FAIL\\n\");
    }
    processingCommand = FALSE;
    sendingResponse = FALSE;
    return SUCCESS;
  }*/

", $s, $d, $d, $d, $d, $d;

#now, print out all the provided events or uses commands that are required
for my $requiredFunc (values %requiredFunctions) {
    $s .= sprintf("  %s %s %s.%s( ", $requiredFunc->{functionType},
		  $requiredFunc->{returnType}->{typeDecl},
		  $requiredFunc->{componentName}."_".$requiredFunc->{interfaceName},
		  $requiredFunc->{functionName});
    for my $param (values %{$requiredFunc->{params}}) {
	$s .= " $param->{type}->{typeDecl} $param->{name},";
    }
    $s .= "\b) { }\n";
}

$s .= "\n}
";

#send the generated code out to a file
my $backsp = sprintf "\b";
$s =~ s/.$backsp//g;
open(RPCM, ">${DestDir}RpcM.nc");
print RPCM "$G_warning$s";
close(RPCM);



##############################
# Generate the RpcC.nc file
##############################

$s = "includes Rpc;

configuration RpcC {
  provides {
    interface StdControl;
  }
}
implementation {

  components 
    $LedsC
    RpcM,
    GenericComm;
#ifndef RPC_NO_DRIP
  components
    DripC, 
    DripStateC,
    DestC;
#endif // !RPC_NO_DRIP
#ifndef RPC_NO_DRAIN
  components
    DrainC;
#endif // !RPC_NO_DRAIN
";

# generate the declarations of each rpc interface or function:
my %components;
for $fullName (sort keys %rpcFunctions ) {
    $rpc = $rpcFunctions{$fullName};
    if (! $components{$rpc->{'componentName'}}){
	$components{$rpc->{'componentName'}} = 1;
	$s = sprintf "%s\n    components $rpc->{'componentName'};", $s;
    }
}

my %componentInterfaces;
for $fullName (sort keys %rpcFunctions ) {
    my $rpc = $rpcFunctions{$fullName};
    if ( $rpc->{'interfaceName'} ){
	if (! $componentInterfaces{$rpc->{'componentName'}.$rpc->{'interfaceName'}}){
	    $componentInterfaces{$rpc->{'componentName'}.$rpc->{'interfaceName'}} = 1;
	    $s = sprintf "%s\n    RpcM.$rpc->{'componentName'}_$rpc->{'interfaceName'}", $s;
	    if ($rpc->{'provided'}==1){
		$s = sprintf "%s -> ", $s;
	    }
	    else{
		$s = sprintf "%s <- ", $s;
	    }
	    $s = sprintf "%s$rpc->{'componentName'}.$rpc->{'interfaceName'};", $s;
	}
    }
    else{
	$s = sprintf "%s\n    RpcM.$rpc->{'componentName'}_$rpc->{'functionName'}", $s;
	if ($rpc->{'provided'}==1){
	    $s = sprintf "%s -> ", $s;
	}
	else{
	    $s = sprintf "%s <- ", $s;
	}
	$s = sprintf "%s$rpc->{'componentName'}.$rpc->{'functionName'};", $s;
    }
}


$s = sprintf "%s

  //now do all the wiring for the rpc communication:
  StdControl = RpcM;
  $ledsWiring
  
  RpcM.SubControl -> GenericComm;
#ifndef RPC_NO_DRAIN
  RpcM.SubControl -> DrainC;
#endif //!RPC_NO_DRAIN
#ifndef RPC_NO_DRIP
  RpcM.SubControl -> DripC;
#endif // !RPC_NO_DRIP

  //genericComm wiring
  RpcM.CommandReceiveLocal -> GenericComm.ReceiveMsg[AM_RPCCOMMANDMSG];

#ifndef RPC_NO_DRIP
  //drip wiring
  RpcM.CommandReceiveDrip -> DripC.Receive[AM_RPCCOMMANDMSG];
  RpcM.CommandDrip -> DripC.Drip[AM_RPCCOMMANDMSG];
  DripC.DripState[AM_RPCCOMMANDMSG] -> DripStateC.DripState[unique(\"DripState\")];
  RpcM.Dest -> DestC;
#endif // !RPC_NO_DRIP

  //drain wiring
#ifndef RPC_NO_DRAIN
  RpcM.ResponseSendMsg -> DrainC.SendMsg[AM_RPCRESPONSEMSG];
  RpcM.DrainSend -> DrainC.Send[AM_RPCRESPONSEMSG];
#else
  RpcM.ResponseSendMsg -> GenericComm.SendMsg[AM_RPCRESPONSEMSG];
#endif // !RPC_NO_DRAIN

//  RpcM.ErrorSendMsgDrain -> DrainC.SendMsg[AM_RPCERRORMSG];


}
", $s;

#send the generated code out to a file
$s =~ s/.$backsp//g;
open(RPCC, ">${DestDir}RpcC.nc");
print RPCC "$G_warning$s";
close(RPCC);


############################
# Substitute abstract params
# This function is only here to pass a hashref by value
############################
sub substituteAbstractParams{
    my ($params, $typeNames, $typeVals) = @_;
    my %newParams = ();
    my $i = 0;
    for my $name (keys %{$params}) {
	my $param = $params->{$name};
	my %newParam = ();
	$newParam{'name'} = $param->{'name'};
	$newParam{'type'} = &substituteAbstractTypes($param->{'type'},
						     $typeNames,
						     $typeVals);
	$newParams{$name} = \%newParam;
	$i++;
    }
    return \%newParams;
}
    

############################
# Match a type with an abstract type definition and, if it matches
# substitute the type parameter used when the interface was declared
############################
sub substituteAbstractTypes{
    my ($type, $typeNames, $typeVals) = @_;
    my $i = 0;
    for my $typeName (@{$typeNames}) {
	if ( $type->{typeName} eq $typeName ) {
	    return &NescParser::parseType($typeVals->[$i]);
	}
	$i++;
    }
    return $type
}

#############################
# check the following criteria of any rpc function:
# 1.  any provided rpc interface has only commands
# 2.  any used rpc interface has only events
# 3.  all rpc commands and events are provided
# 4.  no rpc function has void* param or return types
# 5.  no rpc function defined in generic modules
##############################

sub checkRpcFunction {
    my ($rpc, $fullName) = @_;
    #if this is an interface function, provided/used depends on command/event
    if ( $rpc->{'interfaceName'}){
	if ($rpc->{'provided'}==1 &&
	    $rpc->{'functionType'} eq 'event'){
	    print "WARNING: rpc function $fullName is an event in a provided interface; it is now being handled by RpcM.\n";
	    return 1;
	}
	elsif ( $rpc->{'provided'}==0 &&
		$rpc->{'functionType'} eq 'command'){
	    print "WARNING: rpc function $fullName is a command in a used interface; it is now being handled by RpcM.\n";
	    return 1;
	}
    }
    #if this is a function not in an interface, it must be provided
    else{
	if ($rpc->{'provided'}==0 ){
	    print "ERROR: rpc function $fullName is used; it cannot be tagged \@rpc.\n";
	    $shouldDie = 1;
	}
    }
    if ( $rpc->{'returnType'}->{'typeName'} eq 'void' &&
	 $rpc->{'returnType'}->{'typeClass'} eq 'pointer'){
	print "ERROR: rpc function $fullName returns a void*.\n";
	$shouldDie = 1;
    }
    for my $param (values %{$rpc->{'params'}}){
	if ($param->{'type'}->{'typeName'} eq 'void' &&
	    $param->{'type'}->{'typeClass'} eq 'pointer'){
	    print "ERROR: rpc function $fullName has a void* parameter.\n";
	    $shouldDie = 1;
	}
    }
}


