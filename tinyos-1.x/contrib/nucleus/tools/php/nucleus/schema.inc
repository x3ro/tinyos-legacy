<?php

include "config.inc";
include "xmlrpc.inc";

function download_server_schema() {
  // load the schema file into the XML-RPC server
  $msg = new xmlrpcmsg("nucleus.getSchema", array());
  $client = new xmlrpc_client(NUCLEUS_XMLRPC_SERVER_PATH, 
			      NUCLEUS_XMLRPC_SERVER, 
			      NUCLEUS_XMLRPC_SERVER_PORT);
  $response=$client->send($msg, NUCLEUS_XMLRPC_SERVER_TIMEOUT);
  
  $error = 0;
  if (!$response) {
    print "Unable to contact ".NUCLEUS_XMLRPC_SERVER.":".NUCLEUS_XMLRPC_SERVER_PORT.".";
    $error = 1;
  } else if ($response->faultCode()) {
    print "Nucleus XMLRPC Server returned error ("
      .$response->faultString().") code=".$response->faultCode().".";
    $error = 1;
  }
  
  if ($error) {
    print "<a href=\"".home()."\"><br>Continue</a>\n";
    exit();
  }
  
  $data = internal_xmlrpc_decode($response->value());

  $uploadfile = NUCLEUS_UPLOAD_DIRECTORY . "/nucleusSchemaTmp.xml";
  $fp = fopen($uploadfile, "w");
  if (!$fp) {
    print "<p>Unable to open schema file=$uploadfile</p>\n";
    start_over();
  }
  if (!fwrite($fp, $data)) {
    print "<p>Unable to write schema file=$uploadfile</p>\n";
    start_over();
  }
  if (!fclose($fp)) {
    print "<p>Unable to close schema file=$uploadfile</p>\n";
    start_over();
  }

  load_schema();
}

function load_schema() {
  $uploadfile = NUCLEUS_UPLOAD_DIRECTORY . "/nucleusSchemaTmp.xml";

  // Open the uploaded schema file
  $fp = fopen($uploadfile, "r");
  if(!$fp)
    {
      print "<p>Unable to open schema file=$uploadfile</p>\n";
      start_over();
    }
  
// Read the entire file into a scalar
$xmldata="";
while(!feof($fp))
{
  $xmldata.=fgets($fp);
}
fclose($fp);

// Parse the schema contents
$xml_parser = xml_parser_create();
$vals = array();
$indx = array();
xml_parser_set_option($xml_parser, XML_OPTION_CASE_FOLDING,  0);
xml_parser_set_option($xml_parser, XML_OPTION_SKIP_WHITE, 1);
xml_parse_into_struct($xml_parser, $xmldata, &$vals, &$indx);
xml_parser_free($xml_parser);

// Basic check that this is indeed a nucleusSchema file
if(!isset($vals) || ($vals[0]['tag'] != 'nucleusSchema'))
{
  print "<p>The <b>Nucleus</b> schema file that you uploaded is not valid.</p>\n";
  start_over();
}

// Collect all the attributes and symbols
$attributes = array();
$symbols    = array();
foreach($vals as $entry)
{
  if( $entry['tag'] == "attribute")
  {
    $attribute = array();
    $attribute['name'] = $entry['attributes']['name'];
    if (isset($entry['attributes']['get-interface'])) {
      $attribute['get'] = true;
    }
    if (isset($entry['attributes']['set-interface'])) {
      $attribute['set'] = true;
    }
    if ($entry['attributes']['mode'] == "single") {
      $attribute['single'] = true;
    }
    if ($entry['attributes']['mode'] == "list") {
      $attribute['list'] = true;
    }
    $attributeProps[$attribute['name']] = $attribute;
    array_push( $attributes, $attribute );
  }
  else if( $entry['tag'] == "symbol")
  {
    array_push( $symbols, $entry['attributes']['name'] );
  }
}

if( count($attributes) == 0 && count($symbols) == 0)
{
  print "<p>The <b>Nucleus</b> schema file that you uploaded has no attributes or RAM symbols.</p>\n";
  start_over();
}

$_SESSION['schema']['path'] = $uploadfile;
$_SESSION['schema']['data'] = $xmldata;
$_SESSION['schema']['program'] = $vals[0]['attributes']['program_name'];
$_SESSION['schema']['user'] = $vals[0]['attributes']['user_id'];
$_SESSION['schema']['attributes'] = $attributes;
$_SESSION['schema']['symbols'] = $symbols;
$_SESSION['schema']['attributeProps'] = $attributeProps;
}

?>
