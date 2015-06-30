// $Id: XnpConfig.nc,v 1.1.1.1 2007/11/05 19:10:05 jpolastre Exp $


// XnpConfig interface: allow querying of the current Xnp state without
// requiring a client module to respond to NPX_DOWNLOAD_REQ.

interface XnpConfig
{
  command uint16_t getProgramID();
  command void saveGroupID();
}

