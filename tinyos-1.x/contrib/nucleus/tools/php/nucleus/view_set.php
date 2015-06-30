<?php

include "util.inc";

if(!isset($_SESSION['query']) || !isset($_GET['view']))
{
  go_home();
}

$_SESSION['view'] = $_GET['view'];

go_home();



?>
