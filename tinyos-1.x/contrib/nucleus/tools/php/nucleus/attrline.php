<?php 

include "util.inc";

$moteid = $_GET['m'];
$name = $_GET['n'];
if (isset($_GET['t'])) {
  $text = true;
}

require_once('sparkline/Sparkline_Line.php');

$sparkline = new Sparkline_Line();
$sparkline->SetDebugLevel(DEBUG_NONE);
//$sparkline->SetDebugLevel(DEBUG_ERROR | DEBUG_WARNING | DEBUG_STATS | DEBUG_CALLS | DEBUG_DRAW | DEBUG_SET, '../log2.txt');

$x = 0;
foreach($_SESSION['query']['data'][$moteid] as $responseTime => $theName) {
  $value = $_SESSION['query']['data'][$moteid][$responseTime][$name];
  if (isset($lastValue) && $value != $lastValue) {
    $hasChange = true;
  }
  if (!isset($baseTime)) {
    $baseTime = $responseTime;
  }
  $scaledTime = $responseTime - $baseTime;
  
  $scaledTime = $x;

  if ($text) {
    print "$scaledTime - $value<br>";
  } else {
    $sparkline->SetData($scaledTime, $value);
  }
  $x += 1;
  $lastValue = $value;
}

if (!$text) {
  if ($hasChange) {
    $sparkline->Render(100, 15);
    $sparkline->Output();
  } else {
    $im = imagecreate(1,1);
    $white = imagecolorallocate($im, 0xFF, 0xFF, 0xFF);
    imagesetpixel($im, 1, 1, $white);
    imagegif($im);
    imagedestroy($im);
  }
}


?>


