/*  -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250 at the HPL layer for use with the MSP430 on the 
 * eyesIFX platforms, Configuration.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.19 $
 * $Date: 2005/10/25 14:43:33 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module HPLTDA5250M {
    provides {
        interface StdControl;
        interface HPLTDA5250Config;
        interface HPLTDA5250Data;
    }
    uses {
        interface HPLUSARTControl as USARTControl;
        interface HPLUSARTFeedback as USARTFeedback;
        interface TimerJiffy as SetupDelay;    
        interface TimerJiffy as ReceiverDelay;    
        interface TimerJiffy as RSSIDelay;    
        interface TimerJiffy as TransmitterDelay;    
        interface MSP430Interrupt as InterruptPort10;
    }
}

implementation {
    /****************************************************************
                       Global Variables Declared
    *****************************************************************/
    norace uint16_t currentConfig;
    uint8_t currentClockDiv;
    norace uint8_t currentLpf;

    /****************************************************************
                           Tasks Declared 
    *****************************************************************/
    task void ReceiverSetupDelayTask();
    task void TransmitterSetupDelayTask();
    task void SleepSetupDelayTask();
    task void RSSIStableDelayTask();
    task void SystemSetupDelayTask();
   
    /****************************************************************
                      Internal Functions Declared 
    *****************************************************************/
    void transmitByte(uint8_t data);
    void writeByte(uint8_t address, uint8_t data);
    void writeWord(uint8_t address, uint16_t data);
    uint8_t readByte(uint8_t address);

    /****************************************************************
                         async commands Implemented
    *****************************************************************/
    /**
     * Initializes the Radio, setting up all Pin configurations
     * to the MicroProcessor that is driving it and resetting
     * all Registers to their default values
     *
     * @return always returns SUCCESS
     */   
    command result_t StdControl.init() {
        // enabling pins for module / io function
        TOSH_SEL_TDA_BUSM_IOFUNC();
        TOSH_SEL_TDA_ENTDA_IOFUNC();
        TOSH_SEL_TDA_TXRX_IOFUNC();
        TOSH_SEL_TDA_DATA_IOFUNC();
        TOSH_SEL_TDA_PWDDD_IOFUNC();

        // setting direction
        TOSH_MAKE_TDA_BUSM_OUTPUT();
        TOSH_MAKE_TDA_ENTDA_OUTPUT();
        TOSH_MAKE_TDA_TXRX_OUTPUT();

        // Made into output to be cleared to have
        // no interference from timerA-pin     
        TOSH_MAKE_TDA_DATA_OUTPUT();

        // Default as output pin, but changes to input
        // with SELF_POLLING or TIMER modes
        TOSH_MAKE_TDA_PWDDD_OUTPUT();
     
        // initializing the radio
        TOSH_SET_TDA_BUSM_PIN();  // set busmode: SPI for TDA
        TOSH_SET_TDA_ENTDA_PIN();
        TOSH_SET_TDA_TXRX_PIN();
        TOSH_CLR_TDA_PWDDD_PIN();
     
        // Clearing of the TDA_DATA pin and resetting it to input
        // since default of the radio is receive.
        TOSH_CLR_TDA_DATA_PIN();
        TOSH_MAKE_TDA_DATA_INPUT();
     
        //Keep two state variables to know current value of 
        //config register and ClockDiv register
        currentConfig = DATA_CONFIG_DEFAULT;
        currentClockDiv = DATA_CLK_DIV_DEFAULT; 
        currentLpf = DATA_LPF_DEFAULT;    
     
        //Initializing interrupt for use in Timer and SelfPolling modes
        call InterruptPort10.clear();
        call InterruptPort10.edge(FALSE);
     
        //Start timer that expires once initilization of radio complete
        post SystemSetupDelayTask();
        return SUCCESS;
    }
   
    /**
     * Part of the StdControl Interface, but not used.
     * It is only present here because the <code>init()<\code>
     * command from the StdControl interface was required and
     * all commands from a given interface need to be implemented.
     *
     * @return always returns SUCCESS
     */      
    command result_t StdControl.start() {
        return SUCCESS;
    }
   
    /**
     * Part of the StdControl Interface, but not used.
     * It is only present here because the <code>init()<\code>
     * command from the StdControl interface was required and
     * all commands from a given interface need to be implemented.
     *
     * @return always returns SUCCESS
     */    
    command result_t StdControl.stop() {
        return SUCCESS;
    }

    /**
     * Reset all Radio Registers to the default values as defined
     * in the HPLTDA5250Const.h file
     */    
    command void HPLTDA5250Config.reset() {
        atomic {
            currentConfig = DATA_CONFIG_DEFAULT;
            currentClockDiv = DATA_CLK_DIV_DEFAULT; 
            currentLpf = DATA_LPF_DEFAULT;
        }
        writeWord(ADRW_CONFIG, DATA_CONFIG_DEFAULT);
        writeWord(ADRW_FSK, DATA_FSK_DEFAULT);
        writeWord(ADRW_XTAL_TUNING, DATA_XTAL_TUNING_DEFAULT);
        writeByte(ADRW_LPF, DATA_LPF_DEFAULT);
        writeWord(ADRW_ON_TIME, DATA_ON_TIME_DEFAULT);
        writeWord(ADRW_OFF_TIME, DATA_OFF_TIME_DEFAULT);
        writeWord(ADRW_COUNT_TH1, DATA_COUNT_TH1_DEFAULT);
        writeWord(ADRW_COUNT_TH2, DATA_COUNT_TH2_DEFAULT);
        writeByte(ADRW_RSSI_TH3, DATA_RSSI_TH3_DEFAULT);
        writeByte(ADRW_CLK_DIV, DATA_CLK_DIV_DEFAULT);
        writeByte(ADRW_XTAL_CONFIG, DATA_XTAL_CONFIG_DEFAULT);
        writeWord(ADRW_BLOCK_PD, DATA_BLOCK_PD_DEFAULT);
    }
   
    /**
     * Set the contents of the CONFIG register
     */    
    async command void HPLTDA5250Config.SetRegisterCONFIG(uint16_t value) {
        currentConfig = value;
        writeWord(ADRW_CONFIG, value);
    }
    /**
     * Set the contents of the FSK register
     */       
    async command void HPLTDA5250Config.SetRegisterFSK(uint16_t value) {
        writeWord(ADRW_FSK, value);
    }
    /**
     * Set the contents of the XTAL_TUNING register
     */      
    async command void HPLTDA5250Config.SetRegisterXTAL_TUNING(uint16_t value) {
        writeWord(ADRW_XTAL_TUNING, value);
    }
    /**
     * Set the contents of the LPF register
     */      
    async command void HPLTDA5250Config.SetRegisterLPF(uint8_t value) {
        currentLpf = value;
        writeByte(ADRW_LPF, value);
    }

    async command void HPLTDA5250Config.SetRegisterON_TIME(uint16_t value) {  
        writeWord(ADRW_ON_TIME, value);   
    }
    /**
     * Set the contents of the OFF_TIME register
     */      
    async command void HPLTDA5250Config.SetRegisterOFF_TIME(uint16_t value) {
        writeWord(ADRW_OFF_TIME, value);
    }
    /**
     * Set the contents of the COUNT_TH1 register
     */      
    async command void HPLTDA5250Config.SetRegisterCOUNT_TH1(uint16_t value) {   
        writeWord(ADRW_COUNT_TH1, value);
    }
    /**
     * Set the contents of the COUNT_TH2 register
     */      
    async command void HPLTDA5250Config.SetRegisterCOUNT_TH2(uint16_t value) {
        writeWord(ADRW_COUNT_TH2, value);
    }
    /**
     * Set the contents of the RSSI_TH3 register
     */      
    async command void HPLTDA5250Config.SetRegisterRSSI_TH3(uint8_t value) {
        writeByte(ADRW_RSSI_TH3, value);
    }
    /**
     * Set the contents of the CLK_DIV register
     */      
    async command void HPLTDA5250Config.SetRegisterCLK_DIV(uint8_t value) {
        writeByte(ADRW_CLK_DIV, value);
        currentClockDiv = value;
    }
   
    /**
     * Set the contents of the XTAL_CONFIG register
     */      
    async command void HPLTDA5250Config.SetRegisterXTAL_CONFIG(uint8_t value) {
        writeByte(ADRW_XTAL_CONFIG, value);
    }
    /**
     * Set the contents of the BLOCK_PD register
     */      
    async command void HPLTDA5250Config.SetRegisterBLOCK_PD(uint16_t value) {
        writeWord(ADRW_BLOCK_PD, value);  
    }  
    async command void HPLTDA5250Config.SetLowPassFilter(uint8_t data_cutoff) {
        currentLpf = (((data_cutoff << 4) | (currentLpf & 0x0F)));
        writeByte(ADRW_LPF, currentLpf);     
    }
    async command void HPLTDA5250Config.SetIQFilter(uint8_t iq_cutoff) {
        currentLpf = (((iq_cutoff & 0x0F) | (currentLpf & 0xF0)));
        writeByte(ADRW_LPF, currentLpf);         
    }
    async command void HPLTDA5250Config.UseRCIntegrator() {
        currentConfig = CONFIG_SLICER_RC_INTEGRATOR(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);     
    }
    async command void HPLTDA5250Config.UsePeakDetector() {
        currentConfig = CONFIG_SLICER_PEAK_DETECTOR(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);     
    }
    async command void HPLTDA5250Config.PowerDown() {
        currentConfig = CONFIG_ALL_PD_POWER_DOWN(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);     
    }
    async command void HPLTDA5250Config.PowerUp() {
        currentConfig = CONFIG_ALL_PD_NORMAL(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);     
    }
    async command void HPLTDA5250Config.RunInTestMode() {
        currentConfig = CONFIG_TESTMODE_TESTMODE(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig); 
    }
    async command void HPLTDA5250Config.RunInNormalMode() {
        currentConfig = CONFIG_TESTMODE_NORMAL(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.ControlRxTxExternally() {
        currentConfig = CONFIG_CONTROL_TXRX_EXTERNAL(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);  
    }
    async command void HPLTDA5250Config.ControlRxTxInternally() {
        /*    currentConfig = CONFIG_CONTROL_TXRX_REGISTER(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);
        */
    }
    async command void HPLTDA5250Config.UseFSK(uint8_t pos_shift, uint8_t neg_shift) {
        // this platform does not have a connection to the FSK pin
        currentConfig = CONFIG_ASK_NFSK_FSK(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);
        writeWord(ADRW_FSK, ((uint16_t)((((uint16_t)pos_shift) << 8) + neg_shift)));    
    }
    async command void HPLTDA5250Config.UseASK(uint8_t value) {
        // this platform does not have a connection to the FSK pin
        currentConfig = CONFIG_ASK_NFSK_ASK(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);
        writeWord(ADRW_FSK, (((uint16_t)value) << 8));    
    }
    async command void HPLTDA5250Config.SetClockOffDuringPowerDown() {
        currentConfig = CONFIG_CLK_EN_OFF(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);      
    }
    async command void HPLTDA5250Config.SetClockOnDuringPowerDown() {
        currentConfig = CONFIG_CLK_EN_ON(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.InvertData() {
        currentConfig = CONFIG_RX_DATA_INV_YES(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);      
    }
    async command void HPLTDA5250Config.DontInvertData() {
        currentConfig = CONFIG_RX_DATA_INV_NO(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {
        currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);   
        writeWord(ADRW_COUNT_TH1, lower_bound);  
        writeWord(ADRW_COUNT_TH2, upper_bound);
        writeByte(ADRW_RSSI_TH3, 0xC0 | value);
    }
   
    async command void HPLTDA5250Config.UseVCCDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound) {
        currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);   
        writeWord(ADRW_COUNT_TH1, lower_bound);
        writeWord(ADRW_COUNT_TH2, upper_bound);
        writeByte(ADRW_RSSI_TH3, 0x3F & value);
    }
   
    async command void HPLTDA5250Config.UseDataValidDetection() {
        currentConfig = CONFIG_D_OUT_IFVALID(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);       
    }
   
    async command void HPLTDA5250Config.UseDataAlwaysValid() { 
        currentConfig = CONFIG_D_OUT_ALWAYS(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.ADCContinuousMode() {
        currentConfig = CONFIG_ADC_MODE_CONT(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);       
    }
    async command void HPLTDA5250Config.ADCOneShotMode() {
        currentConfig = CONFIG_ADC_MODE_ONESHOT(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.DataValidContinuousMode() {
        currentConfig = CONFIG_F_COUNT_MODE_CONT(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);      
    }
    async command void HPLTDA5250Config.DataValidOneShotMode() {
        currentConfig = CONFIG_F_COUNT_MODE_ONESHOT(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.HighLNAGain() {
        currentConfig = CONFIG_LNA_GAIN_HIGH(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.LowLNAGain() {
        currentConfig = CONFIG_LNA_GAIN_LOW(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);   
    }
    async command void HPLTDA5250Config.EnableReceiverInTimedModes() {
        currentConfig = CONFIG_EN_RX_ENABLE(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);     
    }
    async command void HPLTDA5250Config.DisableReceiverInTimedModes() {
        currentConfig = CONFIG_EN_RX_DISABLE(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command void HPLTDA5250Config.UseHighTxPower() {
        currentConfig = CONFIG_PA_PWR_HIGHTX(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);     
    }
    async command void HPLTDA5250Config.UseLowTxPower() {
        currentConfig = CONFIG_PA_PWR_LOWTX(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);    
    }
    async command result_t HPLTDA5250Config.UseBipolarXTALTuning(bool fsk_ramp0, bool fsk_ramp1, uint8_t nom_freq) {
        uint8_t tempXTALConfig = ((((uint8_t)fsk_ramp0) << 2) + (((uint8_t)fsk_ramp1) << 1) + 1);
        writeByte(ADRW_XTAL_CONFIG, tempXTALConfig);
        writeWord(ADRW_XTAL_TUNING, ((uint16_t)nom_freq) & 0x003F);
    }
    async command result_t HPLTDA5250Config.UseFETXTALTuning(uint8_t nom_freq) {
        writeByte(ADRW_XTAL_CONFIG, 0x00);
        writeWord(ADRW_XTAL_TUNING, ((uint16_t)nom_freq) & 0x003F);        
    }
/**
   Set the mode of the radio 
   The choices are SLAVE_MODE, TIMER_MODE, SELF_POLLING_MODE
*/
    async command void HPLTDA5250Config.SetSlaveMode() {
        // this platform supports slave mode via pins
        call InterruptPort10.disable();    
        TOSH_MAKE_TDA_PWDDD_OUTPUT();
        TOSH_CLR_TDA_PWDDD_PIN();
    }
    async command void HPLTDA5250Config.SetTimerMode(float on_time, float off_time) {
        TOSH_SET_TDA_TXRX_PIN();
        writeWord(ADRW_ON_TIME, CONVERT_TIME(on_time));
        writeWord(ADRW_OFF_TIME, CONVERT_TIME(off_time));
        currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
        currentConfig = CONFIG_MODE_2_TIMER(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);
        TOSH_MAKE_TDA_PWDDD_INPUT();    
        call InterruptPort10.clear();
        call InterruptPort10.enable();
    }
    async command void HPLTDA5250Config.ResetTimerMode() {
        TOSH_SET_TDA_TXRX_PIN();
        currentConfig = CONFIG_MODE_1_SLAVE_OR_TIMER(currentConfig);
        currentConfig = CONFIG_MODE_2_TIMER(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);       
        TOSH_MAKE_TDA_PWDDD_INPUT();
        call InterruptPort10.clear();
        call InterruptPort10.enable();
    }
    async command void HPLTDA5250Config.SetSelfPollingMode(float on_time, float off_time) {
        TOSH_SET_TDA_TXRX_PIN();
        writeWord(ADRW_ON_TIME, CONVERT_TIME(on_time));
        writeWord(ADRW_OFF_TIME, CONVERT_TIME(off_time));
        currentConfig = CONFIG_MODE_1_SELF_POLLING(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);
        TOSH_MAKE_TDA_PWDDD_INPUT(); 
        call InterruptPort10.clear();
        call InterruptPort10.enable();
    }
    async command void HPLTDA5250Config.ResetSelfPollingMode() {
        TOSH_SET_TDA_TXRX_PIN();
        currentConfig = CONFIG_MODE_1_SELF_POLLING(currentConfig);
        writeWord(ADRW_CONFIG, currentConfig);          
        TOSH_MAKE_TDA_PWDDD_INPUT();
        call InterruptPort10.clear();
        call InterruptPort10.enable();
    }
/**
   Set the on time and off time of the radio
   (Only makes sense when in TIMER or SELF_POLLING Mode)
*/
    async command void HPLTDA5250Config.SetOnTime_ms(float time) {
        writeWord(ADRW_ON_TIME, CONVERT_TIME(time));
    }
    async command void HPLTDA5250Config.SetOffTime_ms(float time) {
        writeWord(ADRW_OFF_TIME, CONVERT_TIME(time));
    }
/**
   Set the frequency that the CLK_DIV outputs
   (Available frequencies given in TDA5250ClockFreq_t struct)
*/
    async command void HPLTDA5250Config.UseSetClock() {
        currentClockDiv &= 0x0F;
        writeWord(ADRW_CLK_DIV, currentClockDiv);  
    }
    async command void HPLTDA5250Config.Use18MHzClock() {
        currentClockDiv |= 0x10;
        currentClockDiv &= 0x1F;
        writeWord(ADRW_CLK_DIV, currentClockDiv); 
    }
    async command void HPLTDA5250Config.Use32KHzClock() {
        currentClockDiv |= 0x20;
        currentClockDiv &= 0x2F;
        writeWord(ADRW_CLK_DIV, currentClockDiv);    
    }
    async command void HPLTDA5250Config.UseWindowCountAsClock() {
        currentClockDiv |= 0x30;
        writeWord(ADRW_CLK_DIV, currentClockDiv);   
    }
    async command void HPLTDA5250Config.SetRadioClock(TDA5250ClockOutFreqs_t freq) {
        currentClockDiv = (currentClockDiv & 0x30) + freq;
        writeWord(ADRW_CLK_DIV, currentClockDiv);  
    }
/**
   Sets the threshold Values for internal evaluation
*/
    async command void HPLTDA5250Config.SetRSSIThreshold(uint8_t value) {
        writeByte(ADRW_RSSI_TH3, 0xC0 | value);
    }
    async command void HPLTDA5250Config.SetVCCOver5Threshold(uint8_t value) { 
        writeByte(ADRW_RSSI_TH3, 0x3F & value);      
    }
    async command void HPLTDA5250Config.SetLowerDataRateThreshold(uint16_t value) {
        writeWord(ADRW_COUNT_TH1, value);     
    }
    async command void HPLTDA5250Config.SetUpperDataRateThreshold(uint16_t value) {
        writeWord(ADRW_COUNT_TH2, value);     
    }
    /**
       Get the exact contents of the readable radio data 
       registers
    */   
    async command uint8_t HPLTDA5250Config.GetRegisterSTATUS() {
        return readByte(ADRR_STATUS);
    }
    async command uint8_t HPLTDA5250Config.GetRegisterADC() {
        return readByte(ADRR_ADC);
    }
    /**
       Get parts of certain registers according to their 
       logical functionality 
    */      
    async command uint8_t HPLTDA5250Config.GetRSSIValue() {
        return (0x3F & readByte(ADRR_ADC));
    }
    async command uint8_t HPLTDA5250Config.GetADCSelectFeedbackBit() {
        return ((0x40 & readByte(ADRR_ADC)) >> 6);
    }
    async command uint8_t HPLTDA5250Config.GetADCPowerDownFeedbackBit() {
        return ((0x80 & readByte(ADRR_ADC)) >> 7);
    }
    async command bool HPLTDA5250Config.IsDataRateLessThanLowerThreshold() {
        if((0x80 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }
    async command bool HPLTDA5250Config.IsDataRateBetweenThresholds() {
        if((0x40 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }   
    async command bool HPLTDA5250Config.IsDataRateLessThanUpperThreshold() {
        if((0x20 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }  
    async command bool HPLTDA5250Config.IsDataRateLessThanHalfOfLowerThreshold() {
        if((0x10 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }  
    async command bool HPLTDA5250Config.IsDataRateBetweenHalvesOfThresholds() {
        if((0x08 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }  
    async command bool HPLTDA5250Config.IsDataRateLessThanHalfOfUpperThreshold() {
        if((0x04 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }  
    async command bool HPLTDA5250Config.IsRSSIEqualToThreshold() {
        if((0x02 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }     
    async command bool HPLTDA5250Config.IsRSSIGreaterThanThreshold() {
        if((0x01 & readByte(ADRR_STATUS)) == TRUE)
            return TRUE;
        return FALSE;
    }

/**
   Switches radio between states when in SLAVE_MODE
*/
    async command void HPLTDA5250Config.SetTxState() {
//        if (currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) {
//             currentConfig = CONFIG_RX_NTX_TX(currentConfig);
//             writeWord(ADRW_CONFIG, currentConfig);
//         } else {
            TOSH_CLR_TDA_TXRX_PIN();
//        }
        post TransmitterSetupDelayTask();
    }
    async command void HPLTDA5250Config.SetRxState() {
//         if(currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) {
//             currentConfig = CONFIG_RX_NTX_RX(currentConfig);
//             writeWord(ADRW_CONFIG, currentConfig);
//         } else {
            TOSH_SET_TDA_TXRX_PIN();
//        }
        post ReceiverSetupDelayTask();
    }
    async command void HPLTDA5250Config.SetSleepState() {
        TOSH_SET_TDA_TXRX_PIN();
        TOSH_SET_TDA_PWDDD_PIN();
/*        if(currentConfig | MASK_CONFIG_CONTROL_TXRX_REGISTER) {
            currentConfig = CONFIG_ALL_PD_POWER_DOWN(currentConfig);
            writeWord(ADRW_CONFIG, currentConfig);
        }
*/
        post SleepSetupDelayTask();
    }
    /****************************************************************
                          Events Implemented
    *****************************************************************/
    /**
       Interrupt Signal on PWD_DD pin in 
       TIMER_MODE and SELF_POLLING_MODE
    */        
    async event void InterruptPort10.fired() {
        call InterruptPort10.clear();
        signal HPLTDA5250Config.PWD_DDInterrupt();
    }
    event result_t SetupDelay.fired() {
        signal HPLTDA5250Config.ready();
        return SUCCESS;
    }   
    event result_t ReceiverDelay.fired() { 
        if(call RSSIDelay.setOneShot(RSSI_STABLE_TIME-RECEIVER_SETUP_TIME) == FAIL)
            post RSSIStableDelayTask();   
        signal HPLTDA5250Config.SetRxStateDone();
        return SUCCESS;   
    }  
    event result_t RSSIDelay.fired() { 
        signal HPLTDA5250Config.RSSIStable();
        return SUCCESS;   
    }     
    event result_t TransmitterDelay.fired() {
        signal HPLTDA5250Config.SetTxStateDone(); 
        return SUCCESS;   
    }          
    async command result_t HPLTDA5250Data.tx(uint8_t data) {
        return call USARTControl.tx(data);
    }
    async command bool HPLTDA5250Data.isTxDone() {
        return call USARTControl.isTxEmpty(); 
    }   
    async command result_t HPLTDA5250Data.enableTx() {
        call USARTControl.setClockSource(SSEL_SMCLK);
        call USARTControl.setClockRate(UBR_SMCLK_19200, UMCTL_SMCLK_19200); 
        call USARTControl.setModeUART_TX();            
        call USARTControl.enableTxIntr();
        return SUCCESS;
    }   
    async command result_t HPLTDA5250Data.disableTx() {
        call USARTControl.disableUARTTx();
        call USARTControl.disableTxIntr();
        return SUCCESS;
    }         
    async command result_t HPLTDA5250Data.enableRx() {
        call USARTControl.setClockSource(SSEL_SMCLK);
        call USARTControl.setClockRate(UBR_SMCLK_19200, UMCTL_SMCLK_19200);   
        call USARTControl.setModeUART_RX();      
        call USARTControl.enableRxIntr();   
        return SUCCESS;
    }
    async command result_t HPLTDA5250Data.disableRx() {
        volatile uint8_t buf = 0;
        call USARTControl.disableRxIntr();
        call USARTControl.disableUARTRx();
        buf = call USARTControl.rx();
        return SUCCESS;
    }      

    async command result_t HPLTDA5250Config.enableSPI() {
        call USARTControl.setModeUART();
        call USARTControl.setModeSPI();   
        call USARTControl.setClockSource(SSEL_SMCLK);
        call USARTControl.setClockRate(4, 0);
        return SUCCESS;
    }      

    async event result_t USARTFeedback.txDone() {
        signal HPLTDA5250Data.txReady();
        return SUCCESS;
    }
    async event result_t USARTFeedback.rxDone(uint8_t data) {
        signal HPLTDA5250Data.rxDone(data);
        return SUCCESS;
    }
    async command void HPLTDA5250Config.sourceSMCLKfromDCO() {
        atomic {
            if(!(BCSCTL1 & XT2OFF)) {
                BCSCTL1 |= XT2OFF;
                BCSCTL2 = DIVS1;
                CLR_FLAG( IE1, OFIE );
                TOSH_uwait(6);
            }
        }
    }
    async command void HPLTDA5250Config.sourceSMCLKfromRadio() {
        atomic {
            if(BCSCTL1 & XT2OFF) {
                BCSCTL1 &= ~XT2OFF;
                BCSCTL2 = SELS;
                CLR_FLAG( IE1, OFIE );
                TOSH_uwait(6);
            }
        }
    }

/****************************************************************
                           Tasks Implemented 
*****************************************************************/
    task void ReceiverSetupDelayTask() {
        if(call ReceiverDelay.setOneShot(RECEIVER_SETUP_TIME) == FAIL)
            post ReceiverSetupDelayTask();   
    }
    task void RSSIStableDelayTask() {
        if(call RSSIDelay.setOneShot(RSSI_STABLE_TIME-RECEIVER_SETUP_TIME) == FAIL)
            post RSSIStableDelayTask();   
    }   
    task void TransmitterSetupDelayTask() {
        if(call TransmitterDelay.setOneShot(TRANSMITTER_SETUP_TIME) == FAIL)
            post TransmitterSetupDelayTask();   
    }
    task void SystemSetupDelayTask() {
        if(call SetupDelay.setOneShot(SYSTEM_SETUP_TIME) == FAIL)
            post SystemSetupDelayTask();   
    }  
    task void SleepSetupDelayTask() {
        signal HPLTDA5250Config.SetSleepStateDone();
    }     
   
/****************************************************************
                    Internal Functions Implemented
*****************************************************************/
   
/* Reading and writing to the radio over the USART */
    void transmitByte(uint8_t data){
        call USARTControl.tx(data);
        while (call USARTControl.isTxIntrPending() == FAIL);
    }

    void writeByte(uint8_t address, uint8_t data) {
        TOSH_CLR_TDA_ENTDA_PIN();
        TOSH_uwait(1);
        transmitByte(address);
        transmitByte(data);
        while (call USARTControl.isTxEmpty() == FAIL);
        TOSH_SET_TDA_ENTDA_PIN();
        TOSH_uwait(1);
    } 

    void writeWord(uint8_t address, uint16_t data){
        TOSH_CLR_TDA_ENTDA_PIN();
        TOSH_uwait(1);  
        transmitByte(address);
        transmitByte((uint8_t) (data >> 8));
        transmitByte((uint8_t) data);
        while (call USARTControl.isTxEmpty() == FAIL);
        TOSH_SET_TDA_ENTDA_PIN();
        TOSH_uwait(1);
    }

    uint8_t readByte(uint8_t address){
        writeByte(address, 0x00);
        return call USARTControl.rx();
    }
   
/****************************************************************
                    Default Events Implemented
*****************************************************************/   
   
    default event void HPLTDA5250Config.ready() {
    }

}
