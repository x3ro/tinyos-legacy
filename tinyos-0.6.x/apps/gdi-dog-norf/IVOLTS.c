/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * IVOLTS -
 *
 */

#include "tos.h"
#include "IVOLTS.h"
#include "sensorboard.h"

char TOS_COMMAND(IVOLTS_INIT)()
{
    ADC_PORTMAP_BIND(TOS_ADC_PORT_3, VOLTAGE_PORT);
    return(TOS_CALL_COMMAND(IVOLTS_SUB_ADC_INIT)());
}

char TOS_COMMAND(IVOLTS_GET_DATA)()
{
    return(TOS_CALL_COMMAND(IVOLTS_SUB_ADC_GET_DATA)(TOS_ADC_PORT_3));
}
