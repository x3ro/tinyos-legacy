<?php

include "util.inc";

$state = isset($_GET['state']) ? $_GET['state'] : "schema";
switch($state)
{
  case "schema":
    if (isset($_SESSION['schema'])) {
      unlink($_SESSION['schema']['path']);
    }
    $_SESSION = array();
    if (isset($_COOKIE[session_name()])) {
      setcookie(session_name(), '', time()-42000, '/');
    }
    session_destroy();
    break;
  case "params":
    unset($_SESSION['params']);
    break;
  case "query":
    unset($_SESSION['query']);
    break;
}

go_home();


?>


















