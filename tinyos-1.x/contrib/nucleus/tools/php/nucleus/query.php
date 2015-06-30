<?php

include "util.inc";
include "config.inc";
include "xmlrpc.inc";

if( !isset($_SESSION['schema']) || !isset($_SESSION['params']) )
{
  go_home();
}

$names = array();
$positions = array();
foreach( $_SESSION['params']['names'] as $name => $data )
{
  array_push( $names, new xmlrpcval($name) );
  array_push( $positions, new xmlrpcval($data['listItem']) );
} 

$method = "";
switch($_SESSION['params']['type'])
{
  case "symbol";
    $method = "nucleus.RAMQuery";
    break;
  case "attribute";
    $method = "nucleus.attrQuery";
    break;
  default:
    print "Error: unknown query type = ".$_SESSION['params']['type']." ...";
    start_over();
}

// Show the popup window letting them know there is a query goin' on...
/*
print "<html><head>";
print "<script>\n";
$secs = $_SESSION['params']['interval'] / 10;
print "queryWin = window.open('querying.php?secs=$secs', 'querying', 'menubar=0, resizable=1, width=350, height=240'  );";
print "</script>\n";
print "<title>Nucleus Query</title></head><body bgcolor=\"#ffffff\">\n";
flush();
*/

$error=false;
$data = array();

if(SIMULATED_QUERY)
{
  for($moteid = 1000; $moteid < (SIMULATED_MOTE_SIZE+1000); $moteid++)
  {
    if( rand(0,100) <= SIMULATED_MOTE_FAILURE)
    {
      continue; // simulate that a mote didn't respond
    }
    foreach($_SESSION['params']['names'] as $name)
    {
      $data[$moteid][$name] = rand();
    }
  }
  sleep(5);
}
else
{
  $method = "nucleus.get";
  
  // Build the message
  $msg = new xmlrpcmsg($method,
                        array(new xmlrpcval($_SESSION['network']['sendQuery'], "i4"),
			      new xmlrpcval($_SESSION['network']['receiveResults'], "i4"),
                              new xmlrpcval($_SESSION['network']['interval'], "i4"),
                              new xmlrpcval($names, "array"),
			      new xmlrpcval($positions, "array")));

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
}

$responseTime = time();
foreach($data as $moteid => $moteinfo)
{
  $_SESSION['query']['data'][$moteid][$responseTime] = $moteinfo;
}
$_SESSION['query']['last'] = $responseTime;

// Save information about mote responsiveness
if(!isset($_SESSION['motes']))
{
  $_SESSION['motes']['queries']=1;
  $_SESSION['motes']['responses'] = array();
}
else
{
  $_SESSION['motes']['queries']++;
}

foreach($data as $moteid => $moteinfo)
{
  if(!isset($_SESSION['motes']['responses'][$moteid]))
  {
    $_SESSION['motes']['responses'][$moteid] = 1;
  }
  else
  {
    $_SESSION['motes']['responses'][$moteid]++;
  }

  // Save the time this mote responded
  $_SESSION['motes']['last'][$moteid] = $_SESSION['query']['last'];
}

if(!$error)
{
  go_home();
//  print "Query was Successful!  ";
}

// Dats all folks
print "<a href=\"".home()."\">Continue</a>\n";

?>






