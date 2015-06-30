/* TinyDB Attribute - Total merge since the accounting start */

configuration AttrMerge
{ 
	provides interface StdControl;
}
implementation
{
  components AttrMergeM, Attr, TinyDBShimM;

  StdControl = AttrMergeM;
  AttrMergeM.AttrRegister -> Attr.Attr[unique("Attr")];
  AttrMergeM.HSNValue -> TinyDBShimM.HSNValueAttrMerge;
}
