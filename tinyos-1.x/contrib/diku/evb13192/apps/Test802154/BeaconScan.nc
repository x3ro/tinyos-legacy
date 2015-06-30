#include <Ieee802154Adts.h>
interface BeaconScan
{
	command void activeScan();
	command void passiveScan();
	event void done(result_t res, Ieee_PanDescriptor bestPanInfo);
}
