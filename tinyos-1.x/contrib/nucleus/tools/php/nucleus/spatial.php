<?php

include "util.inc";
include "motelist.inc";

if(!isset($_SESSION['query']))
{
  go_home();
}

$motelist = get_motelist();
$name = $_GET['name'];
$mode = $_GET['mode'];
$lastResponseTime = $_SESSION['query']['last'];

$maxX = 0;
$maxY = 0;
foreach($motelist as $moteid => $data)
{
  if ($motelist[$moteid]['x'] > $maxX) {
    $maxX = $motelist[$moteid]['x'];
  }
  if ($motelist[$moteid]['y'] > $maxY) {
    $maxY = $motelist[$moteid]['y'];
  }
}

$maxValueLen = 0;
$minValue = 2147483647;
$maxValue = -$minValue;
$fontNum = 4;

$maxDiam = 16;

if ($name == "Response%") {
  foreach( $_SESSION['motes']['responses'] as $moteid => $responses ) {
    $hit_rate = sprintf("%.0f", 100 * ($responses / $_SESSION['motes']['queries'] ));
    $maxValue = max($maxValue, $hit_rate);
    $minValue = min($minValue, $hit_rate);

    if (strlen("$hit_rate") > $maxValueLen) {
      $maxValueLen = strlen("$hit_rate");
    }
  }
} else {
  foreach($_SESSION['query']['data'] as $moteid => $moteinfo) {
    if (isset($_SESSION['query']['data'][$moteid][$lastResponseTime])) {
      $value = $_SESSION['query']['data'][$moteid][$lastResponseTime][$name];
    } else {
      $value = "???";
    }

    $maxValue = max($maxValue, $value);
    $minValue = min($minValue, $value);
    
    if (strlen("$value") > $maxValueLen) {
      $maxValueLen = strlen("$value");
    }
  }
}

switch($mode) {
 case "values":
   $width = (imagefontwidth($fontNum) * ($maxValueLen + 1)) * ($maxX + 2);
   $height = (imagefontheight($fontNum)) * ($maxY + 2);
   break;
 case "dots":
   $width = $maxDiam * ($maxX + 2);
   $height = $maxDiam * ($maxY + 2);
   break;
}

$im = imagecreate($width, $height);
$white = imagecolorallocate($im, 255,255,255);
$black = imagecolorallocate($im, 0,0,0);

imagerectangle($im, 0, 0, $width-1, $height-1, $black);

if ($name == "Response%") {
  foreach( $_SESSION['motes']['responses'] as $moteid => $responses ) {
    $hit_rate = sprintf("%.0f", 100 * ($responses / $_SESSION['motes']['queries'] ));

    print_val($im, $fontNum, $motelist, $moteid, $maxValueLen, $black, $hit_rate);
  }

} else {

  foreach($_SESSION['query']['data'] as $moteid => $moteinfo) {
    if (isset($_SESSION['query']['data'][$moteid][$lastResponseTime])) {
      $value = $_SESSION['query']['data'][$moteid][$lastResponseTime][$name];
    } else {
      $value = "???";
    }
    print_val($im, $fontNum, $motelist, $moteid, $maxValueLen, $black, $value);
  }
}

function print_val($im, $fontNum, $motelist, $moteid, $maxValueLen, $color, $value) {

  global $mode, $maxDiam, $maxValue, $minValue;
  $red = imagecolorallocate($im, 255,0,0);
 
  if (strcmp($value,"???") == 0) {
    $color = $red;
  }

  if ($mode == "values") {
    $x = $motelist[$moteid]['x'] * (imagefontwidth($fontNum) * 
				    ($maxValueLen + 1));
    $y = $motelist[$moteid]['y'] * (imagefontheight($fontNum));

    imagestring($im, $fontNum, 
		$x, $y,
		$value, $color);  

  } else if ($mode == "dots") {
    $x = $motelist[$moteid]['x'] * ($maxDiam + 1);
    $y = $motelist[$moteid]['y'] * ($maxDiam + 1);
    
    $diam = ceil($maxDiam * ($value - $minValue) / ($maxValue - $minValue));
    //    print "$minValue - $value - $maxValue<br>";
    //    print "$diam<br>";

    imageellipse($im, $x, $y, $maxDiam, $maxDiam,
		       $color);
    imagefilledellipse($im, $x, $y, $diam, $diam,
		       $color);
  }
}


imagepng($im);
?>

