<?php

include "util.inc";
include "config.inc";
include "xmlrpc.inc";

$error=false;
$data = array();

$method = "nucleus.set";

// Build the message
$msg = new xmlrpcmsg($method,
		     array(new xmlrpcval($_GET['mote'], "i4"),
			   new xmlrpcval($_GET['var'], "string"),
			   new xmlrpcval(0, "i4"),
			   new xmlrpcval($_GET['value'], "string")));


// Create the client
$client = new xmlrpc_client(NUCLEUS_XMLRPC_SERVER_PATH, 
                            NUCLEUS_XMLRPC_SERVER, 
                            NUCLEUS_XMLRPC_SERVER_PORT);

//print "<pre> ".htmlspecialchars($msg->serialize());
// Send the message to the server and get a response
$response=$client->send($msg, NUCLEUS_XMLRPC_SERVER_TIMEOUT);
//print "-------------\n".htmlspecialchars($response->serialize())."</pre>";

// Check for errors
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
else
{
  $data = internal_xmlrpc_decode($response->value());
}

if(!$error)
{
  go_query();
}

?>
