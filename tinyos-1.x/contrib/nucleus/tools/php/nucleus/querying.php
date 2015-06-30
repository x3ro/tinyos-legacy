<html>
<head>
<title>Running Nucleus Query</title>
<script>
var x = <?php print isset($_GET['secs'])? $_GET['secs']: 10;?>;
var y = 1;
function startClock(){
  x = x-y;
  document.frm.clock.value = x;
  setTimeout("startClock()", 1000);
}
</script>
</head>
<body onLoad="startClock()">
<center>
<span class="popuphead"><font size="+1">Nucleus Query In Progress</font></span>
<p>
<span class="popup">
<form name="frm">
<b>This query completes in <input type="text" name="clock" size="4"> seconds.<br />Please be patient!</b>
<p>
<table border=0 cellpadding=0 cellspacing=0>
<tr>
<td> <img src="computer.gif" width="31" height="32"> </td>
<td> <img src="querying.gif" width="160" height="11"> </td>
<td> <img src="computer.gif" width="31" height="32"> </td>
</tr>
</table>

</center>

</span>
</body>
</html>
