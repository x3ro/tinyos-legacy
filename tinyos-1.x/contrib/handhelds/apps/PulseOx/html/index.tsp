<html>
<head><title>CRL PulseOx Sensor</title></head>
<body>
<h1>This is an 802.15.4 pulse ox sensor.</h1>
<table>
<% pox_lock(); %>
<tr><th>Sample</th><td><% print pox_number(); %></td></tr>
<tr>
 <th>Heart rate</th>
 <td><% print pox_heartrate(); %></td>
 <td><% print pox_heartrate_display(); %></td>
</tr>
<tr>
 <th>Extended Heart rate</th>
 <td><% print pox_ext_heartrate(); %></td>
 <td><% print pox_ext_heartrate_display(); %></td>
</tr>
<tr>
 <th>Sp02</th>
 <td><% print pox_spo2(); %></td>
 <td><% print pox_spo2_display(); %></td>
</tr>
<tr>
 <th>Sp02 slew/beat to beat</th>
 <td><% print pox_spo2_slew(); %></td>
 <td><% print pox_spo2_beat_to_beat(); %></td>
</tr>
</table>
<table>
<h2>Plethysmographic pulse value</h2>
<table><tr>
<% 
for ( i = 0 ; i < 25 ; i+=1 ) {
  print "<td bgcolor='", pox_perfusion(i), "'>", pox_pleth(i), "</td>";
}
%>
<% pox_unlock(); %>
</tr></table>
</body>
</html>