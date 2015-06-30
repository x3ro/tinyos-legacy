<script type="text/javascript">
<!--

  function setList(list, state)
  {
    for(i=0; i< list.length; i++)
      list[i].checked = state;
  }

  function setSelect(select, state)
  {
    for(i=0; i< select.length; i++)
      select[i].selected = state;
  }

  function selectAllAttrs(form)
  {
    setSelect(form.elements['nucleusAttrs[]'], form.allAttrs.checked);
    setSelect(form.elements['nucleusSymbols[]'], false);
    form.allSymbols.checked = false;
    form.queryType[0].checked = true;
  }

  function selectAllSymbols(form)
  {
    setSelect(form.elements['nucleusSymbols[]'], form.allSymbols.checked);
    setSelect(form.elements['nucleusAttrs[]'], false);
    form.allAttrs.checked = false;
    form.queryType[1].checked = true;
  }

  function ensureState(option, state)
  {
    if(state == false)
    {
      alert("Nucleus currently cannot query Attribute and RAM symbols simultaneously");
      option.selected = false;
    }
  }

  function checkInterval(interval)
  {
    if(interval.value <= 0)
    {
      alert("The query interval must be greater than zero");
      interval.value = NUCLEUS_DEFAULT_QUERY_DELAY;
    }
    if(interval.value > 600)
    {
      alert("The Nucleus XMLRPC server currently only supports up to 60 second query intervals");
      interval.value = NUCLEUS_DEFAULT_QUERY_DELAY;
    }
  }

//-->
</script>

<form action="params_set.php" method="POST">
<input type="reset" value="Reset Parameters">
<input type="submit" value="Submit Parameters">
<p>
<font size="+2">Nucleus Attributes & RAM Symbols</font>
<br/>
<?php
$i = 0;
$numAttrs = count($_SESSION['schema']['symbols']) + count($_SESSION['schema']['attributes']);
print "<select name=\"nucleusAttrs[]\" multiple=\"multiple\" size=\""
        .$numAttrs."\">\n";
foreach($_SESSION['schema']['attributes'] as $attr)
{
  print "<option value=\"" . $attr['name'] . "\">";
  print $attr['name'] . "</option>\n";
  $i++;
}
foreach($_SESSION['schema']['symbols'] as $sym)
{
  print "<option value=\"$sym\">";
  print "$sym\n</option>\n";
  $i++;
}
?>
</form>
