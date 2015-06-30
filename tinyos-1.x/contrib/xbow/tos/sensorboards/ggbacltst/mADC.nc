// $Id: mADC.nc,v 1.1 2004/11/22 14:33:34 husq Exp $
interface mADC {
  async command result_t getData(uint16_t *data_buffer);
}

