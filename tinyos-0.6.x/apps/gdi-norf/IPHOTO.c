/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * IPHOTO - 
 *
 */

#include "tos.h"
#include "IPHOTO.h"
#include "sensorboard.h"

char TOS_COMMAND(IPHOTO_INIT)()
{
    ADC_PORTMAP_BIND(TOS_ADC_PORT_1, PHOTO_PORT);
    return(TOS_CALL_COMMAND(IPHOTO_SUB_ADC_INIT)());
}

char TOS_COMMAND(IPHOTO_GET_DATA)()
{
    MAKE_PHOTO_CTL_OUTPUT();
    SET_PHOTO_CTL_PIN();

    return(TOS_CALL_COMMAND(IPHOTO_SUB_ADC_GET_DATA)(TOS_ADC_PORT_1));
}

char TOS_EVENT(IPHOTO_SUB_ADC_DONE)(short data)
{
    MAKE_PHOTO_CTL_OUTPUT();
    CLR_PHOTO_CTL_PIN();

    TOS_SIGNAL_EVENT(IPHOTO_DATA_READY)(data);
    return(0);
}
