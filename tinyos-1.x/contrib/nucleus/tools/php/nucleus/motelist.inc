<?php

function
get_motelist()
{
  $motelist = array();
  $fp = fopen("motelist", "r");
  if (!$fp) {
    return false;
  }
  while(!feof($fp))
  {
    $info = explode("\t", fgets($fp, 4096));
    if(count($info)==3)
    {
      $motelist[ $info[0] ] =
        array( "x"  => chop($info[1]),
	       "y"  => chop($info[2]) );
    }
  }
  return $motelist; 
}


?>
