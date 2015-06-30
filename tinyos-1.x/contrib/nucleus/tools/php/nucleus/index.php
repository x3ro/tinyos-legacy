<?php

include "header.inc";
include "util.inc";
include "schema.inc";

?>

<style>#loading { display: none; position: absolute; z-index: 1; top: 0px; right: 0px; color: white; background-color: red; }</style>
<span id="loading">Loading...</span>

<table width=100% cellpadding=0 cellspacing=0>
<tr>
<td>
<font size="+1">Nucleus Web Console</font>
</td>
<td align=right>

<?php
if (!isset($_SESSION['schema'])) {
  download_server_schema();
}

if(!isset($_SESSION['schema'])) {
  print "No Schema Loaded";
} else {
  print "Current Application: <b>" . $_SESSION['schema']['program'] . "</b> " . 
    "Compiled By: <b>".$_SESSION['schema']['user']."</b> " .
    "<a href=\"del.php?state=schema\">Reload</a>";
}

if (!isset($_SESSION['network'])) {
  $_SESSION['network']['sendQuery'] = 65534;
  $_SESSION['network']['receiveResults'] = 0;
  $_SESSION['network']['interval'] = NUCLEUS_DEFAULT_QUERY_DELAY;
  $_SESSION['network']['defaultRoute'] = false;
}
?>

</td>
</tr>
</table>

<hr size="1" noshade="noshade">

<?php
if(!isset($_SESSION['schema']))
{
  include "schema_get.php";
  include "footer.inc";
  exit();
}

if(!isset($_SESSION['params']))
{
  include "params_get.php";
  include "footer.inc";
  exit();
}
?>

<script>
function set_network(field, val)
{
  load_action("set_network.php?field=" + field + "&value=" + val);
}
</script>

<?php
$secs = $_SESSION['network']['interval'] / 10;
print "<a href=\"javascript: load_action('query.php');\">Refresh Results (takes $secs seconds)</a>";
bar();
print "<a href=\"del.php?state=params\">Select New Attributes</a>";
print "<p>";

if (!isset($_SESSION['network']['drainInstance'])) {
  print "<a href=\"javascript: load_action('drain.php?action=rebuild');\">Build Tree</a>";
  bar();
  print "<a href=\"javascript: load_action('drain.php?action=rebuild&default=true');\">Build Default Tree</a>";
  bar();
  print "Refine Tree";
} else {
  print "<a href=\"javascript: load_action('drain.php?action=rebuild');\">Rebuild Tree</a>";
  bar();
  print "<a href=\"javascript: load_action('drain.php?action=refine');\">Refine Tree</a>";
}
bar();
print "<form name=\"network\" style=\"display: inline; margin: 0;\">";
print "Set Destination Address "; 
print "<input type=\"text\" size=\"3\" name=\"destAddr\" value=\"" 
. $_SESSION['network']['sendQuery'] . "\""
. "onChange=\"set_network(this.name, this.value);\">";
bar();
print "Set Response Address ";
print "<input type=\"text\" size=\"3\" name=\"respAddr\" value=\"" 
. $_SESSION['network']['receiveResults'] . "\""
. "onChange=\"set_network(this.name, this.value);\">"
. "</form>";
bar();
print "Set Response Delay ";
print "<input type=\"text\" size=\"3\" name=\"respDelay\" value=\"" 
. $_SESSION['network']['interval'] . "\""
. "onChange=\"set_network(this.name, this.value);\">"
. "</form>";
print "<br/>";
?>

<hr size="1" noshade="noshade">

<?php
if(!isset($_SESSION['query']))
{
  header("Location: query.php");
  exit();
}

/* No more potential headers .. so flush */
ob_end_flush();

if(isset($_SESSION['view']) && $_SESSION['view'] == "graph")
{
  print "<img src=\"graph.php\">";
}
else
{
  include "table.inc";
}
include "footer.inc";
?>




