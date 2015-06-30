<?php

include "util.inc";

$_SESSION['params']['names'][$_GET['var']]['listItem'] = $_GET['index'];

go_query();

//print "Setting " . $_GET['var'] . " to list index " . $_GET['index'] . "<br>";
//print_r($_SESSION);
?>
