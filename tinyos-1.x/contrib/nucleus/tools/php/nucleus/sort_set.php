<?php

include "util.inc";

if(!isset($_SESSION['query']) || !isset($_GET['sortby']))
{
  go_home();
}

$new_sortby = $_GET['sortby'];

if(!isset($_SESSION['params']['sortasc'])) {
  $_SESSION['params']['sortasc'] = false;
}

if (isset($_SESSION['params']['sortby']) &&
    $_SESSION['params']['sortby'] == $new_sortby) {
  
  $_SESSION['params']['sortasc'] = !$_SESSION['params']['sortasc'];
}

$_SESSION['params']['sortby'] = $new_sortby;

go_home();



?>
