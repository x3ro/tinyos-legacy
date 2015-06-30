
module DisplayM{

    provides {
        interface StdControl;
    }
    uses {
        interface Timer;
        interface SSP;
        interface Leds;
        interface BulkTxRx as RawData;
    }
}

implementation {

#define DIS_CTL_PIN SSP2_RXD
#define RST_CTL_PIN (94)
#define DB_SIZE 4096 // Display RAM 128x64x4bit

    #include "image.h"

    TOSH_ASSIGN_PIN(DIS_CTL, A, DIS_CTL_PIN);
    TOSH_ASSIGN_PIN(RST_CTL, A, RST_CTL_PIN);

    uint8_t db[DB_SIZE];
    int ds = 1;
    int tim = 0;
    int ts;

    task void dis_init();
    task void dis_start();
    
    command result_t StdControl.init() {
        call Leds.init();
        call SSP.setMasterSCLK(TRUE);
        call SSP.setMasterSFRM(TRUE);
        call SSP.setSSPFormat(SSP_SPI);
        call SSP.setDataWidth(SSP_8bits);
        call SSP.enableInvertedSFRM(FALSE);
        call SSP.enableSPIClkHigh(TRUE);
        call SSP.shiftSPIClk(TRUE);
        call SSP.enableManualRxPinCtrl(TRUE);
        call SSP.setClkRate(1); // SPI clock = 13MHz / (x + 1)
        TOSH_MAKE_DIS_CTL_OUTPUT();
        TOSH_CLR_DIS_CTL_PIN();  // display command mode
        TOSH_MAKE_RST_CTL_OUTPUT();
        TOSH_CLR_RST_CTL_PIN();  // reset display
        return SUCCESS;
    }
 
    command result_t StdControl.start() {
        call Timer.start(TIMER_ONE_SHOT, 100); // wait 100ms
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call Timer.stop();
        return SUCCESS;
    }

    task void dis_reset() {
        TOSH_SET_RST_CTL_PIN();  // disable reset
        call Timer.start(TIMER_ONE_SHOT, 100); // wait 100ms
    }

    task void dis_clear() {
        int i, j, dx, ix;

        i = 0;
        ix = 0;
        for (dx = 0; dx < DB_SIZE; dx++) {
            if (i == 0) {
                db[dx] = (uint8_t)(ib[ix] & 0xff);
                i = 1;
            } else {
                db[dx] = (uint8_t)(ib[ix] >> 8);
                i = 0;
                j = dx % 64;
                if (j < 48) {
                    ix++;
                }
            }
            if (ix > 1535) {
                ix = 1535;
            }
        }
        TOSH_SET_DIS_CTL_PIN();  // data mode   
        if (call RawData.BulkTransmit(db, DB_SIZE) == FAIL) {
            trace(DBG_USR1, "Display init failed\r\n");
        } else {
            ;
        }
        ts = dx;
    }

    task void dis_init() {
        int ix;

        ix = 0;
        // SSD0323 Initialization Commands
        // Column Addressuint16_t ib[1536] = {
        db[ix++] = 0x15; /* Set Column Address */
        db[ix++] = 0x00; /* Start = 0 */
        db[ix++] = 0x3F; /* End = 127 */
        // Row Address
        db[ix++] = 0x75; /* Set Row Address */
        db[ix++] = 0x00; /* Start = 0 */
        db[ix++] = 0x3F; /* End = 63 */
        // Contrast Control
        db[ix++] = 0x81; /* Set Contrast Control */
        db[ix++] = 0x33; /* 0 ~ 127 */
        // Current Range
        db[ix++] = 0x86; /* Set Current Range 84h:Quarter, 85h:Half, 86h:Full*/
        // Re-map
        db[ix++] = 0xA0; /* Set Re-map */
        db[ix++] = 0x52; /* [0]:MX, [1]:Nibble, [2]:H/V address [4]:MY, [6]:Com Split Odd/Even "1000010"*/
        // Display Start Line
        db[ix++] = 0xA1; /* Set Display Start Line */
        db[ix++] = 0x00; /* Top */
        // Display Offset
        db[ix++] = 0xA2; /* Set Display Offset */
        db[ix++] = 0x40; /* No offset */
        // Display Mode
        db[ix++] = 0xA4; /* Set Display Mode, A4:Normal, A5:All ON, A6: All OFF, A7:Inverse */
        // Multiplex Ratio
        db[ix++] = 0xA8; /* Set Multiplex Ratio */
        db[ix++] = 0x3F; /* [6:0]16~128, 64 rows=3Fh*/
        // Phase Length
        db[ix++] = 0xB1; /* Set Phase Length */
        db[ix++] = 0x22; /* [3:0]:Phase 1 period of 1~16clocks [7:4]:Phase 2 period of 1~16 clocks POR = 0111 0100 */
        // Row Period
        db[ix++] = 0xB2; /* Set Row Period */
        db[ix++] = 0x46; /* [7:0]:18~255, K=P1+P2+GS15 (POR:4+7+29)*/
        // Display Clock Divide{
        db[ix++] = 0xB3; /* Set Clock Divide */
        db[ix++] = 0x41; /* [3:0]:1~16, [7:4]:0~16 POR = 0000 0001 */
        // VSL
        db[ix++] = 0xBF; /* Set VSL */
        db[ix++] = 0x0D; /* [3:0]:VSL */
        // CCOMH
        db[ix++] = 0xBE; /* Set VCOMH */
        db[ix++] = 0x00; /* [7:0]:VCOMH */
        // VP
        db[ix++] = 0xBC; /* Set VP */
        db[ix++] = 0x0B; /* [7:0]:VP */
        // Gamma
        db[ix++] = 0xB8; /* Set Gamma with next 8 bytes */
        db[ix++] = 0x01; /* L1[2:1] */
        db[ix++] = 0x11; /* L3[6:4], L2[2:0] 0001 0001 */
        db[ix++] = 0x22; /* L5[6:4], L4[2:0] 0010 0010 */
        db[ix++] = 0x32; /* L7[6:4], L6[2:0] 0011 1011 */
        db[ix++] = 0x43; /* L9[6:4], L8[2:0] 0100 0100 */
        db[ix++] = 0x54; /* LB[6:4], LA[2:0] 0101 0101 */
        db[ix++] = 0x65; /* LD[6:4], LC[2:0] 0110 0110 */
        db[ix++] = 0x76; /* LF[6:4], LE[2:0] 1000 0111 */
        // Set DC-DC
        db[ix++] = 0xAD; /* Set DC-DC */
        db[ix++] = 0x02; /* 03=ON, 02=Off */
        // Display ON/OFF
        db[ix++] = 0xAF; /* AF=ON, AE=Sleep Mode */

        TOSH_CLR_DIS_CTL_PIN();  // cmd mode
        if (call RawData.BulkTransmit(db, ix) == FAIL) {
            trace(DBG_USR1, "Display init failed\r\n");
        } else {
            ;
        }
        ts = ix;
    }

    async event uint8_t *RawData.BulkReceiveDone(uint8_t *RxBuffer, uint16_t NumBytes) {
        return NULL;
    }

    task void signalBulkTransmitFail() {
        trace(DBG_USR1, "BulkTransmit failed\r\n");
    }

    async event uint8_t *RawData.BulkTransmitDone(uint8_t *TxBuffer, uint16_t NumBytes) {
        if (NumBytes != ts) {
            call Leds.redOn();
        } else {
            // call Leds.greenOn();
        }
        if (ds == 1) {
            post dis_clear();
            ds = 0;
        }
        return NULL;
    }

    async event BulkTxRxBuffer_t *RawData.BulkTxRxDone(BulkTxRxBuffer_t *TxRxBuffer, uint16_t NumBytes) {
        return NULL;
    }

    event result_t Timer.fired() {
        // call Leds.redToggle();
        switch (tim) {
        case 0:
            post dis_reset();
            tim++;
            break;
        case 1:
            post dis_init();
            tim++;
            break;
        default:
            break;
        }
        return SUCCESS;
    }

}
