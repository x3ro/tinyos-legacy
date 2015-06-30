<html><head><title>Temperature page</title></head><body>
<p>This is a dynamic page that shows the current device
temperature.</p>
<table>
<tr><th>Temperature</th><td><% print temp_as_string(); %></td><td><%
print temp_as_int(); %></td></tr>
<tr><th>Voltage</th><td><% print volt_as_string(); %></td><td><%
print volt_as_int(); %></td></tr>
</table>
</body></html>