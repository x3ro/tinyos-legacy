<?php

include "util.inc";

$action = $_GET['action'];
$moteid = $_GET['mote'];

//print "Performing action " . $action . " on mote " . $moteid . "<br>";

$matches = array();
preg_match("/set\((.*),(.*)\)/", $action, $matches);
//print_r($matches);

if ($matches) {
  $url = home();
  $url .= "set.php?mote=$moteid&var=$matches[1]&value=$matches[2]";
  header("Location: ".$url."");
  exit();
}

if ($action == "remove") {
  unset($_SESSION['motes']['responses'][$moteid]);
  unset($_SESSION['motes']['last'][$moteid]);
  unset($_SESSION['query']['data'][$moteid]);
}

go_query();
?>

