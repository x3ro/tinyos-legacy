<?php

include "util.inc";

if(!isset($_SESSION['query']))
{
  go_home();
}

$TOSBase_Drain_id = 834;
$TOSBase_id = 4001;

include "motelist.inc";

$motelist = get_motelist();

//$options = getopt("i:o:");
//$inputfile = $options['i']? $options['i']: "draintree.txt";
//$outputfile = $options['o']? $options['o']: "graph.gif";

$floorplan = "Soda-4.png";

$im = @imagecreatefrompng($floorplan);
$white = imagecolorallocate($im, 255,255,255);
$black = imagecolorallocate($im, 0,0,0);
$red   = imagecolorallocate($im, 255, 0, 0);
$green = imagecolorallocate($im, 0, 255, 0);
$blue  = imagecolorallocate($im, 0, 0 , 255);

if(!$im)
{
  $im = imagecreate(150, 30);
  imagefilledrectangle($im, 0, 0, 150, 30, $white);
  imagestring($im, 1, 5, 5, "Error loading $floorplan", $black);
}

imagesetthickness($im, 2);

header("Content-type: image/png");
$datestr = date("r", $_SESSION['query']['last']);
imagestring($im, 5, 15, 5, "$datestr", $black);

foreach ($motelist as $id => $info)
{
  /* Mark all the motes at being down ...*/
  imageellipse($im, $info["x"], $info["y"], 40, 40, $red);
}

foreach($_SESSION['query']['data'] as $id => $moteinfo)
{
  $parentid = trim($moteinfo["DrainNextHop"]);
  if($parentid == $TOSBase_Drain_id)
  {
    $parentid = $TOSBase_id;
  }
  imageellipse($im, $motelist[ $id ][ "x" ], $motelist[ $id ][ "y" ], 40, 40, $green);
  imageline($im, $motelist[$id]["x"], $motelist[$id]["y"],
                 $motelist[$parentid]["x"], $motelist[$parentid]["y"], $blue);
}

imagePng($im);
?>
