<html>
<head><title>CRL/Harvard EKG Sensor</title></head>
<body>
<h1>This is an 802.15.4 EKG sensor.</h1>
<table>
<% ekg_lock(); %>
<tr><th>UID</th><td><% 
for ( i = 0 ; i < 6 ; i+=1 ) {
    if (i != 0) {
      print ":";
    }
    print ekg_uid_byte(i);
}
print "::", ekg_uid_family(); 
print "::", ekg_uid_crc(); 
%></td></tr>
<tr><th>Sample</th><td><% print ekg_number(); %></td></tr>
</table>
<table>
<h2>EKG value</h2>
<table><tr>
<% 
for ( i = 0 ; i < 25 ; i+=1 ) {
  print "<td>", ekg_sample(i), "</td>";
}
%>
<% ekg_unlock(); %>
</tr></table>
</body>
</html>