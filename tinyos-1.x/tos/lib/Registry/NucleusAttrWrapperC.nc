includes Attrs;

generic module NucleusAttrWrapperC(typedef attr_type)
{
  provides interface Attr<attr_type>;
  provides interface AttrSet<attr_type>;
  uses interface Attribute<attr_type>;
}
implementation
{
  command result_t Attr.get( attr_type* buf )
  {
    if( call Attribute.valid() )
    {
      attr_type stackHolder = call Attribute.get();
      memcpy(buf, &stackHolder, sizeof(attr_type));
      signal Attr.getDone(buf);
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }

  event void Attribute.updated( attr_type val )
  {
    signal Attr.changed(&val);
  }

  default event result_t Attr.getDone( attr_type* buf )
  {
    return SUCCESS;
  }

  default event result_t Attr.changed( attr_type* buf )
  {
    return SUCCESS;
  }

  command result_t AttrSet.set( attr_type* buf )
  {
    result_t result;
    attr_type stackHolder;
    memcpy(&stackHolder, buf, sizeof(attr_type));
    result = call Attribute.set(stackHolder);
    signal AttrSet.setDone(buf);
    return result;
  }

  default event result_t AttrSet.setDone( attr_type* buf )
  {
    return SUCCESS;
  }
}

