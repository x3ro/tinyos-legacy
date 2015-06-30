/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * ITEMP - 
 *
 */

#include "tos.h"
#include "ITEMP.h"
#include "sensorboard.h"

char TOS_COMMAND(ITEMP_INIT)()
{
    ADC_PORTMAP_BIND(TOS_ADC_PORT_2, TEMP_PORT);
    return(TOS_CALL_COMMAND(ITEMP_SUB_ADC_INIT)());
}

char TOS_COMMAND(ITEMP_GET_DATA)()
{
    MAKE_TEMP_CTL_OUTPUT();
    SET_TEMP_CTL_PIN();

    return(TOS_CALL_COMMAND(ITEMP_SUB_ADC_GET_DATA)(TOS_ADC_PORT_2));
}

char TOS_EVENT(ITEMP_SUB_ADC_DONE)(short data)
{
    MAKE_TEMP_CTL_OUTPUT();
    CLR_TEMP_CTL_PIN();

    TOS_SIGNAL_EVENT(ITEMP_DATA_READY)(data);
    return(0);
}
