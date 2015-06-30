<?php

include "util.inc";
include "config.inc";
include "schema.inc";
include "xmlrpc.inc";

$uploadfile = NUCLEUS_UPLOAD_DIRECTORY ."/". md5(uniqid(rand(), true));

if(!move_uploaded_file($_FILES['schemaFile']['tmp_name'], $uploadfile)) 
{
  print "Unable to upload schema.  Debug output below.";
  print "<pre>";
  print_r($_FILES);
  print "</pre>";
  print "<a href=\"".home()."\">Try again</a>";
  start_over();
}

load_schema();

if ($_POST['sendQuery'] == "drip") {
  $_SESSION['network']['sendQuery'] = 65534;
} else if ($_POST['sendQuery'] == "local") {
  $_SESSION['network']['sendQuery'] = 65535;
}

if ($_POST['receiveResults'] == "drain") {
  $_SESSION['network']['receiveResults'] = 0;
} else if ($_POST['receiveResults'] == "local") {
  $_SESSION['network']['receiveResults'] = 65535;
} else if ($_POST['receiveResults'] == "serial") {
  $_SESSION['network']['receiveResults'] = 126;
}

$_SESSION['network']['interval'] = NUCLEUS_DEFAULT_QUERY_DELAY;
$_SESSION['network']['defaultRoute'] = false;

go_home();

?>
