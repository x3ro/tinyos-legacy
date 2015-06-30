<?php

include "util.inc";

$field = $_GET['field'];
$value = $_GET['value'];

//print "Setting $field to value $value <br>";

if ($field == "destAddr") {
  $_SESSION['network']['sendQuery'] = $value;
} else if ($field == "respAddr") {
  $_SESSION['network']['receiveResults'] = $value;
} else if ($field == "respDelay") {
  $_SESSION['network']['interval'] = $value;
}

go_query();
//print_r($_SESSION);
?>
