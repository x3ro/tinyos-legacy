<?php

function
get_moteactions()
{
  $moteactions = array();
  $fp = fopen("moteactions", "r");
  if (!$fp) {
    return null;
  }
  while(!feof($fp))
  {
    $info = explode(",", fgets($fp, 4096));
    if(count($info)==3)
    {
      $moteactions[ chop($info[0]) ] =
        array( "attr"  => chop($info[1]),
	       "value"  => chop($info[2]) );
    }
  }
  return $moteactions; 
}


?>
