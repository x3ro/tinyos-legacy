<html><head><title>HTML Encoding test</title></head><body>
<p>This page tests HTML encoding modes</p>
<p>
<%
 print "<span style='color: #aaaaaa'><b>Un-encoded text & markup</b></span><br>";
 pmode(1);
 print "<span style='color: #aaaaaa'><b>Encoded text & markup</b></span><br>";
 pmode(0);
%>
</p>
<p style='background-color: #eeeeee'>
 print "&lt;span style='color: #aaaaaa'&gt;&lt;b&gt;Un-encoded text & markup&lt;/b&gt;&lt;/span&gt;&lt;br&gt;";
<br />
 pmode(1);
<br />
 print "&lt;span style='color: #aaaaaa'&gt;&lt;b&gt;Encoded text & markup&lt;/b&gt;&lt;/span&gt;&lt;br&gt;";
<br />
 pmode(0);
</p>
</body></html>