<?php

include "util.inc";
include "motelist.inc";

if(!isset($_SESSION['query']))
{
  go_home();
}

$motelist = get_motelist();
$name = $_GET['name'];
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
$fontNum = 4;

foreach($_SESSION['query']['data'] as $moteid => $moteinfo)
{
  if (isset($_SESSION['query']['data'][$moteid][$lastResponseTime])) {
    $value = $_SESSION['query']['data'][$moteid][$lastResponseTime][$name];
    if (strlen("$value") > $maxValueLen) {
      $maxValueLen = strlen("$value");
    }
  }
}

$cellWidth = (imagefontwidth($fontNum) * ($maxValueLen + 1));
$cellHeight = imagefontheight($fontNum);
$width = $cellWidth * ($maxX + 2);
$height = $cellHeight * ($maxY + 2);

$im = imagecreate($width, $height);
$white = imagecolorallocate($im, 255,255,255);
$black = imagecolorallocate($im, 0,0,0);

imagerectangle($im, 0, 0, $width-1, $height-1, $black);

function arrow($im, $x1, $y1, $x2, $y2, $alength, $awidth, $color) {

   $distance = sqrt(pow($x1 - $x2, 2) + pow($y1 - $y2, 2));

   if ($distance == 0) { $distance = 1; }

   $dx = $x2 + ($x1 - $x2) * $alength / $distance;
   $dy = $y2 + ($y1 - $y2) * $alength / $distance;

   $k = $awidth / $alength;

   $x2o = $x2 - $dx;
   $y2o = $dy - $y2;

   $x3 = $y2o * $k + $dx;
   $y3 = $x2o * $k + $dy;

   $x4 = $dx - $y2o * $k;
   $y4 = $dy - $x2o * $k;

   imageline($im, $x1, $y1, $dx, $dy, $color);
   imageline($im, $x3, $y3, $x4, $y4, $color);
   imageline($im, $x3, $y3, $x2, $y2, $color);
   imageline($im, $x2, $y2, $x4, $y4, $color);
} 

foreach($_SESSION['query']['data'] as $moteid => $moteinfo)
{
  if (isset($_SESSION['query']['data'][$moteid][$lastResponseTime])) {
    $value = $_SESSION['query']['data'][$moteid][$lastResponseTime][$name];

    if (isset($motelist[$value])) {
      arrow($im, 	      
	    $motelist[$moteid]['x'] * $cellWidth + 
	    imagefontwidth($fontNum) * strlen("$value") / 2,
	    
	    $motelist[$moteid]['y'] * $cellHeight + $cellHeight/2,
	    
	    $motelist[$value]['x'] * $cellWidth + 
	    imagefontwidth($fontNum) * strlen("$value") / 2,
	    
	    $motelist[$value]['y'] * $cellHeight + $cellHeight/2,
	    
	    10, 2,
	    
	    $black);
    }
  }

  imagestring($im, $fontNum, 
	      $motelist[$moteid]['x'] * (imagefontwidth($fontNum) * 
					 ($maxValueLen + 1)), 
	      $motelist[$moteid]['y'] * (imagefontheight($fontNum)),
	      $moteid, $black);

//  print "$moteid (" . $motelist[$moteid]['x'] . "," . $motelist[$moteid]['y'] . ")" . ": " . $_SESSION['query']['data'][$moteid][$lastResponseTime][$name] . " <br>";
}

imagepng($im);
?>
