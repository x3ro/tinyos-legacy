<?php

error_reporting(E_ALL);

session_start();

function home()
{
  return "http://" . $_SERVER['HTTP_HOST']
                     . dirname($_SERVER['PHP_SELF'])
                     . "/";
}

function go_home()
{
  header("Location: ".home()."");
  exit();
}

function go_query()
{
  header("Location: query.php");
  exit();
}

function bar()
{
  print "&nbsp;&nbsp;<b>|</b>&nbsp;&nbsp;";
}

function start_over()
{
  print "<a href=\"del.php\">Continue</a>";
  exit();
}


?>
