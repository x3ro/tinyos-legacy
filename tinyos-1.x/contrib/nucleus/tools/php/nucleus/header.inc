<?php
ob_start()
?>
<html>
<head>
<title>Nucleus Console (omega)</title>
</head>
<body>
<style>body{ margin: 10px; }</style>
<script>
function load_action(url)
{
  showIt('loading');
  window.location = url;
}
function showIt(name)
{
  document.getElementById(name).style.display = 'inline';
}
</script>
