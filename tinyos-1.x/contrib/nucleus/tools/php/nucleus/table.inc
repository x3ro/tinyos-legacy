<?php

//include "util.inc";
//include "header.inc";
include "motelist.inc";

$nonContourColumns = 3;

if (!isset($_SESSION['motelist'])) {
  $motelist = get_motelist();
  if (isset($motelist)) {
    $_SESSION['motelist'] = $motelist;
  }
}

if (isset($_SESSION['motelist'])) {
  $posHeaders = array("X", "Y");
  $nonContourColumns += 2;
} else {
  $posHeaders = array();
}

$cols = array_merge( array("&nbsp;", "&nbsp;", "MoteID"),
		     $posHeaders,
		     array("Response%", "Last Response"),
                     array_keys($_SESSION['params']['names']));

$table_header = "<tr bgcolor=\"#cccccc\">\n";
$table_header .= "<form name=\"attributes\">";
$index = 0;
foreach( $cols as $name)
{
  $focus = false;
  if(isset($_SESSION['params']['sortby']) 
     && $_SESSION['params']['sortby'] == $name)
     {
       $focus = true;
     }
  if($focus)
  {
    $table_header.="<th bgcolor=\"#ffffcc\">";
  }
  else
  {
    $table_header.="<th>";
  }

  if ($index >= $nonContourColumns) {
    $table_header .= "<input type=\"radio\" name=\"attr_action_target\" value=\"$name\"";
    if ($index == $nonContourColumns) { $table_header .= "checked>"; } 
    else { $table_header .= ">"; }
  }

  $table_header .= "<a href=\"sort_set.php?sortby=$name\">$name</a>";

  if (isset($_SESSION['schema']['attributeProps'][$name]['list'])) {
    $table_header.="&nbsp; idx:<input size=\"1\" name=\"${name}\" type=\"text\" value=\"" .
      $_SESSION['params']['names'][$name]['listItem'] . "\" ";
    $table_header.="onChange=\"set_listItem('$name', this.value);\">";
  }

  if (isset($_SESSION['schema']['attributeProps'][$name]['set'])) {
    $table_header .= "&nbsp; set:<input size=\"1\" name=\"${name}\" type=\"text\" value=\"\" ";
    $table_header .= "onChange=\"set_value(65534, '$name', this.value);\">";
  }
  $table_header.="</th>";
  $index++;
}
$table_header .= "</form>";
$table_header .= "</tr>\n";

// Sort the data
function datacmp($a, $b)
{
  $sort_key = $_SESSION['params']['sortby'];
  switch($sort_key)
  {
  case "MoteID":
    $av = $a;
    $bv = $b;
    break;
  case "X":
    $av = $_SESSION['motelist'][$a]['x'];
    $bv = $_SESSION['motelist'][$b]['x'];
    if ($av == $bv) {
      $av = $_SESSION['motelist'][$a]['y'];
      $bv = $_SESSION['motelist'][$b]['y'];
    }
    break;
  case "Y":
    $av = $_SESSION['motelist'][$a]['y'];
    $bv = $_SESSION['motelist'][$b]['y'];
    if ($av == $bv) {
      $av = $_SESSION['motelist'][$a]['x'];
      $bv = $_SESSION['motelist'][$b]['x'];
    }
    break;
  case "Response%":
    $av = $_SESSION['motes']['responses'][$a];
    $bv = $_SESSION['motes']['responses'][$b];
    break;
  case "Last Response":
    $av = $_SESSION['motes']['last'][$a];
    $bv = $_SESSION['motes']['last'][$b];
    break;
  default:
    $lastResponseTime = $_SESSION['query']['last'];	
    $av = isset($_SESSION['query']['data'][$a][$lastResponseTime])? 
      $_SESSION['query']['data'][$a][$lastResponseTime][$sort_key]: null;
    $bv = isset($_SESSION['query']['data'][$b][$lastResponseTime])?
      $_SESSION['query']['data'][$b][$lastResponseTime][$sort_key]: null;
  }
  if($av == $bv || (!isset($av) && !isset($bv)))
  {
    return 0;
  }
  if($_SESSION['params']['sortasc'])
  {
    if (!isset($av)) {
      return 1;
    }
    if (!isset($bv)) {
      return -1;
    }
    return $av > $bv? -1: 1;
  }
  if (!isset($av)) {
    return -1;
  }
  if (!isset($bv)) {
    return 1;
  }
  return $av < $bv? -1: 1;
}

if(isset($_SESSION['params']['sortby']))
{
  uksort(&$_SESSION['motes']['responses'], "datacmp");
}
?>

<script>
function set_listItem(name, value)
{
  load_action("set_listItem.php?var=" + name + "&index=" + value);
}
</script>

<script>
function set_value(mote, name, val)
{
  load_action("set.php?mote=" + mote + "&var=" + name + "&value=" + val);
}
</script>

<script>
function apply_action(obj)
{
  checkedIndex = -1;
  if (obj.selectedIndex > 0) {
    for(i = 0; i < document.motes.actionTarget.length; i++) {
      if (document.motes.actionTarget.actionTarget[i].checked) {
	checkedIndex = i;
      }
    }
    if (checkedIndex != -1) {
      load_action("action.php?mote=" + 
		  document.motes.actionTarget[checkedIndex].value +
		  "&action=" + obj.options[obj.selectedIndex].value);
    }
  }
  obj.selectedIndex = 0;
}
</script>

<script>
function apply_attribute_action(obj)
{
  checkedIndex = -1;
    
  if (obj.selectedIndex > 0) {
    for(i = 0; i < document.attributes.attr_action_target.length; i++) {
      if (document.attributes.attr_action_target.attr_action_target[i].checked) {
	checkedIndex = i;
      }
    }

    if (checkedIndex != -1) {

      if (obj.options[obj.selectedIndex].value == "spatial_values") {
	show_spatial_values(document.attributes.attr_action_target[checkedIndex].value);
      } else if (obj.options[obj.selectedIndex].value == "spatial_dots") {
	show_spatial_dots(document.attributes.attr_action_target[checkedIndex].value);
      } else if (obj.options[obj.selectedIndex].value == "tree") {
	show_tree(document.attributes.attr_action_target[checkedIndex].value);
      }
    }
  }

  obj.selectedIndex = 0;
}
</script>

<script>
function show_spatial_values(name)
{
  newWindow = window.open("spatial.php?mode=values&name=" + name, 'spatial_values', 
			  'height=400, width=400, resizable=yes');
}

function show_spatial_dots(name)
{
  newWindow = window.open("spatial.php?mode=dots&name=" + name, 'spatial_dots', 
			  'height=400, width=400, resizable=yes');
}

function show_tree(name)
{
  newWindow = window.open("tree.php?name=" + name, 'tree', 
			  'height=400, width=400, resizable=yes');
}
</script>

<select name="action" onChange="apply_action(this)">
<option>Mote Actions ...</option>
<optgroup>
<option value="remove">Remove</option>
</optgroup>
<optgroup>
<?php

include "moteactions.inc";

$moteactions = get_moteactions();

foreach($moteactions as $name => $moteaction) {
  print "<option value=\"set(" . $moteaction['attr'] . "," . $moteaction['value'] . ")\">" . "$name</option><br>";
}

?>
</optgroup>
</select>

<select name="action" onChange="apply_attribute_action(this)">
<option>Attribute Actions ...</option>
<optgroup>
<option value="spatial_values">Spatial Values</option>
<option value="spatial_dots">Spatial Dots</option>
<option value="tree">Tree Plot</option>
</optgroup>
</select>

<?php
print "<table border=\"1\">\n";
print "<style type=\"text/css\">";
print "table { border-collapse: collapse; border-color: black; }";
print "th { border-collapse: collapse; border-color: black; }";
print "td { border-collapse: collapse; border-color: black; }";
print "</style>";
$row =0;
foreach( $_SESSION['motes']['responses'] as $moteid => $responses )
{
  if($row == 0) //!($row % 25))
  {
  print $table_header;
  print "<form name=\"motes\">\n";
  }

  $hit_rate = sprintf("%.0f", 100 * ($responses / $_SESSION['motes']['queries'] ));
  print "<tr align=\"right\">";
  print "<th bgcolor=\"#cccccc\"><b>".($row++ + 1)."</th>";
  print "<td><input type=\"radio\" name=\"actionTarget\" value=\"$moteid\""; 
  if ($row == 1) { print "checked>"; } else { print ">"; }
  print "<td>" . ($moteid) . "</td>";

  if (isset($_SESSION['motelist'])) {
    print "<td>" . $_SESSION['motelist'][$moteid]['x'] . "</td>";
    print "<td>" . $_SESSION['motelist'][$moteid]['y'] . "</td>";
  }

  print "<td>$hit_rate%</td>";
  print "<td>".date("H:i:s", $_SESSION['motes']['last'][$moteid])."</td>";

  $lastResponseTime = $_SESSION['query']['last'];

  foreach($_SESSION['params']['names'] as $name => $data)
  {
    if(!isset($_SESSION['query']['data'][$moteid][$lastResponseTime]))
    {
      // We have no query data for this mote although we've heard from it before
      $value = "???";

      print "<td bgcolor=\"#ff0000\">";
    } else {
      if (isset($_SESSION['query']['data'][$moteid][$lastResponseTime][$name])) { 
	$value = $_SESSION['query']['data'][$moteid][$lastResponseTime][$name];
      } else {
	$value = "???";
      }

      if(isset($_SESSION['params']['sortby']) && 
	 $name == $_SESSION['params']['sortby']) {
	print "<td bgcolor=\"#ffffcc\">";
      } else {
	print "<td>";
      }
#      print "<img src=\"attrline.php?m=$moteid&n=$name\">";
    }

    if(isset($_SESSION['schema']['attributeProps'][$name]['set'])) {
      // read-write
      print "<input size=\"" . strlen($value) . "\" name=\"${moteid}_${name}\" type=\"text\" value=\"$value\" ";
      print "onChange=\"set_value('$moteid', '$name', this.value);\">";
    }
    else {
      // read-only
      print "<font face=\"courier, fixed\">";
      print $value;
      print "</font>";
    }
    print "</td>";
  }
  print "</tr>\n";
}
print "</table>\n";
print "</form>\n";
?>
