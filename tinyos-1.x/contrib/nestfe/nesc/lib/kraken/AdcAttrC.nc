// $Id: AdcAttrC.nc,v 1.1 2005/06/19 01:52:39 cssharp Exp $

generic module AdcAttrC()
{
  provides interface StdControl;
  provides interface Attr<uint16_t>;
  uses interface ADC;
}
implementation
{
  uint16_t* m_buf;
  norace uint16_t m_data;

  task void adcDone();

  command result_t StdControl.init()
  {
    m_buf = NULL;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  command result_t Attr.get( uint16_t* buf )
  {
    if( (m_buf == NULL) && (call ADC.getData() == SUCCESS) )
    {
      m_buf = buf;
      return SUCCESS;
    }
    return FAIL;
  }

  async event result_t ADC.dataReady( uint16_t data )
  {
    m_data = data;
    post adcDone();
    return SUCCESS;
  }

  task void adcDone()
  {
    if( m_buf != NULL )
    {
      uint16_t* buf = m_buf;
      m_buf = NULL;
      memcpy( buf, &m_data, sizeof(uint16_t) );
      signal Attr.getDone( buf );
    }
  }

  default event result_t Attr.getDone( uint16_t* buf )
  {
    return SUCCESS;
  }
}

