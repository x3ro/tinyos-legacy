<?php

include "util.inc";

if(!isset($_SESSION['schema']))
{
  print "Going home!";
  go_home();
}

if (isset($_SESSION['params']) && isset($_SESSION['params']['names'])) {
  unset($_SESSION['params']['names']);	
}

//print_r($_POST);

$_SESSION['params']['type'] = "attribute";
foreach($_POST['nucleusAttrs'] as $name) {
  $_SESSION['params']['names'][$name] = array();
  $_SESSION['params']['names'][$name]['listItem'] = 0;
}
//print_r($_SESSION);

go_query();

?>
