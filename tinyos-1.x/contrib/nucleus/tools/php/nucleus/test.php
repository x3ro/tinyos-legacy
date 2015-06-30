<?php

$data = array( "10" => array("a" => 1,
                             "b" => 2,
			     "c" => 3),
               "20" => array("a" => 2,
	                     "b" => 5,
			     "c" => 20));
print "<pre>";
print_r($data);
print "</pre>";

$data = sabsi($data, 'a', 'desc');

print "<pre>";
print_r($data);
print "</pre>";

?>
