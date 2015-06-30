<?php

include "util.inc";
include "config.inc";
include "xmlrpc.inc";
	
$action = $_GET['action'];
$default = false;
if (isset($_GET['default'])) {
  if ($_GET['default'] == "true") {
    $default = true;
    $_SESSION['network']['defaultRoute'] = true;
  }
}

switch ($action) {
 case "rebuild":
   $_SESSION['network']['drainInstance'] = rand(0,255);
//   print "Rebuilding drain tree - instance " . $_SESSION['network']['drainInstance'];
   break;
 case "refine":
//   print "Refining drain tree - instance " . $_SESSION['network']['drainInstance'];
   break;
}

$drainTreeDelay = 4;

$msg = new xmlrpcmsg("drain.buildTree",
		     array(new xmlrpcval($drainTreeDelay, "i4"),
			   new xmlrpcval($_SESSION['network']['drainInstance'], "i4"),
			   new xmlrpcval($_SESSION['network']['defaultRoute'], "boolean")));

$client = new xmlrpc_client(NUCLEUS_XMLRPC_SERVER_PATH, 
			    NUCLEUS_XMLRPC_SERVER, 
			    NUCLEUS_XMLRPC_SERVER_PORT);

$error = false;
$response=$client->send($msg, NUCLEUS_XMLRPC_SERVER_TIMEOUT);

if (!$response) 
{
  print "Unable to contact ".NUCLEUS_XMLRPC_SERVER.":".NUCLEUS_XMLRPC_SERVER_PORT.".";
  $error = true;
}

if(!$error && $response->faultCode())
{
  print "Nucleus XMLRPC Server returned error ("
    .$response->faultString().") code=".$response->faultCode().".";
  $error = true;
}

sleep($drainTreeDelay * 2);
go_query();

//print_r($_SESSION);
?>
