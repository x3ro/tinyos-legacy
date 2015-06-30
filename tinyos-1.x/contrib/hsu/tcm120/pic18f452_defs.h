// $Id: pic18f452_defs.h,v 1.1 2005/04/13 16:38:06 hjkoerber Exp $

/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * 
 * $Date: 2005/04/13 16:38:06 $
 * $Revision: 1.1 $
 *
 */

#ifndef _H_pic18f452_defs_h
#define _H_pic18f452_defs_h

// All of the following declarations will be erased/replaced by the perl script.
// The necessary original declarations are included in the original microchip 
// pic18f452.h which is filled into app_pic.c by the perl script  

int asm_nop;
int asm_sleep;
int asm_TX_SendMessage;
int asm_ISR_RxRadio;
int asm_rxBufptr;
int asm_TBLWT;
int asm_clrwdt;

/* Register - dummy declarations */
int PORTA_register;
int PORTB_register;
int PORTC_register;
int PORTD_register;
int PORTE_register;

int TRISA_register;
int TRISB_register;
int TRISC_register;
int TRISD_register;
int TRISE_register;

int LATA_register;
int LATB_register;
int LATC_register;
int LATD_register;
int LATE_register;

int INTCON_register;
int INTCON2_register;
int INTCON3_register;

int PIR1_register;
int PIR2_register;

int PIE1_register;
int PIE2_register;

int IPR_register;
int RCON_register;

int T0CON_register;
int T1CON_register;
int T2CON_register;
int TMR0L_register;
int TMR0H_register;
int TMR2_register;
int PR2_register;
int TMR1L_register;
int TMR1H_register;


int ADCON0_register;
int ADCON1_register;
int ADRESH_register;
int ADRESL_register;

int TXSTA_register;
int RCSTA_register;
int SPBRG_register;
int TXREG_register;
int RCREG_register;

int EECON1_register;
int EECON2_register;
int FSR0_register; 
int TBLPTR_register; 
int TABLAT_register;


/* INTCON - dummy declarations */
int INTCONbits_GIE; 
int INTCONbits_PEIE;
int INTCONbits_TMR0IE; 
int INTCONbits_INT0IE;
int INTCONbits_RBIE;
int INTCONbits_TMR0IF;
int INTCONbits_INT0IF;
int INTCONbits_RBIF;

/* PIR1 - dummy declarations */
int PIR1bits_PSPIF;
int PIR1bits_ADIF;
int PIR1bits_RCIF;
int PIR1bits_TXIF;
int PIR1bits_SSPIF;
int PIR1bits_CCP1IF;
int PIR1bits_TMR2IF;
int PIR1bits_TMR1IF;

/* PIE1 - dummy declarations */
int PIE1bits_PSPIE;
int PIE1bits_ADIE;
int PIE1bits_RCIE;
int PIE1bits_TXIE;
int PIE1bits_SSPIE;
int PIE1bits_CCP1IE;
int PIE1bits_TMR2IE;
int PIE1bits_TMR1IE;


/* PORTA - dummy declarations */
int PORTAbits_RA0;
int PORTAbits_RA1;
int PORTAbits_RA2;
int PORTAbits_RA3;
int PORTAbits_RA4;
int PORTAbits_RA5;
int PORTAbits_RA6;
int PORTAbits_RA7;
int PORTAbits_RA8;

/* TRISA - dummy declarations */
int TRISAbits_TRISA0;
int TRISAbits_TRISA1;
int TRISAbits_TRISA2;
int TRISAbits_TRISA3;
int TRISAbits_TRISA4;
int TRISAbits_TRISA5;
int TRISAbits_TRISA6;
int TRISAbits_TRISA7;


/* PORTB - dummy declarations */
int PORTBbits_RB0;
int PORTBbits_RB1;
int PORTBbits_RB2;
int PORTBbits_RB3;
int PORTBbits_RB4;
int PORTBbits_RB5;
int PORTBbits_RB6;
int PORTBbits_RB7;
int PORTBbits_RB8;

/* TRISB - dummy declarations */
int TRISBbits_TRISB0;
int TRISBbits_TRISB1;
int TRISBbits_TRISB2;
int TRISBbits_TRISB3;
int TRISBbits_TRISB4;
int TRISBbits_TRISB5;
int TRISBbits_TRISB6;
int TRISBbits_TRISB7;


/* PORTC - dummy declarations */
int PORTCbits_RC0;
int PORTCbits_RC1;
int PORTCbits_RC2;
int PORTCbits_RC3;
int PORTCbits_RC4;
int PORTCbits_RC5;
int PORTCbits_RC6;
int PORTCbits_RC7;
int PORTCbits_RC8;

/* TRISC - dummy declarations */
int TRISCbits_TRISC0;
int TRISCbits_TRISC1;
int TRISCbits_TRISC2;
int TRISCbits_TRISC3;
int TRISCbits_TRISC4;
int TRISCbits_TRISC5;
int TRISCbits_TRISC6;
int TRISCbits_TRISC7;

/* PORTD - dummy declarations */
int PORTDbits_RD0;
int PORTDbits_RD1;
int PORTDbits_RD2;
int PORTDbits_RD3;
int PORTDbits_RD4;
int PORTDbits_RD5;
int PORTDbits_RD6;
int PORTDbits_RD7;
int PORTDbits_RD8;

/* TRISD - dummy declarations */
int TRISDbits_TRISD0;
int TRISDbits_TRISD1;
int TRISDbits_TRISD2;
int TRISDbits_TRISD3;
int TRISDbits_TRISD4;
int TRISDbits_TRISD5;
int TRISDbits_TRISD6;
int TRISDbits_TRISD7;

/* PORTE - dummy declarations */
int PORTEbits_RE0;
int PORTEbits_RE1;
int PORTEbits_RE2;
int PORTEbits_RE3;
int PORTEbits_RE4;
int PORTEbits_RE5;
int PORTEbits_RE6;
int PORTEbits_RE7;
int PORTEbits_RE8;

/* TRISE - dummy declarations */
int TRISEbits_TRISE0;
int TRISEbits_TRISE1;
int TRISEbits_TRISE2;
int TRISEbits_TRISE3;
int TRISEbits_TRISE4;
int TRISEbits_TRISE5;
int TRISEbits_TRISE6;
int TRISEbits_TRISE7;

/* T0CON - dummy declarations */
int T0CONbits_TMR0ON;
int T0CONbits_T08BIT;
int T0CONbits_T0CS;
int T0CONbits_T0SE;
int T0CONbits_PSA;
int T0CONbits_T0PS2;
int T0CONbits_T0PS1;
int T0CONbits_T0PS0;

/* T1CON - dummy declarations */
int T1CONbits_TMR1ON;
int T1CONbits_TMR1CS;
int T1CONbits_T1SYNC;
int T1CONbits_T1OSCEN;
int T1CONbits_T1CKPS0;
int T1CONbits_T1CKPS1;
int T1CONbits_RD16;

/* T2CON - dummy declarations */
int T2CONbits_TMR2ON;

/* T3CON - dummy declarations */
int T3CONbits_TMR3ON;
int T3CONbits_TMR3CS;
int T3CONbits_T3SYNC;
int T3CONbits_T3CKPS0;
int T3CONbits_T3CKPS1;
int T3CONbits_T3CCP1;
int T3CONbits_T3CCP2;
int T3CONbits_RD6;

/* ADCON0 - dummy declarations */
int ADCON0bits_ADON;
int ADCON0bits_GO;
int ADCON0bits_CHSO;
int ADCON0bits_CHS1;
int ADCON0bits_CHS2;
int ADCON0bits_ADCS0;
int ADCON0bits_ADCS1;

/* ADCON1 - dummy declarations */
int ADCON1bits_PCFG0;
int ADCON1bits_PCFG1;
int ADCON1bits_PCFG2;
int ADCON1bits_PCFG3;
int ADCON1bits_ADCS2;
int ADCON1bits_ADFM;

/* TXSTA - dummy declarations */
int TXSTAbits_CSRC;
int TXSTAbits_TX9;
int TXSTAbits_TXEN;
int TXSTAbits_SYNC;
int TXSTAbits_BRGH;
int TXSTAbits_TRMT;
int TXSTAbits_TX9D;

/* RCSTA - dummy declarations */
int RCSTAbits_SPEN;
int RCSTAbits_RX9;
int RCSTAbits_SREN;
int RCSTAbits_CREN;
int RCSTAbits_ADDEN;
int RCSTAbits_FERR;
int RCSTAbits_OERR;
int RCSTAbits_RX9D;



/* EECON1 - dummy declarations */
int EECON1bits_RD;
int EECON1bits_WR;
int EECON1bits_WREN;
int EECON1bits_WRERR;
int EECON1bits_FREE;
int EECON1bits_CFGS;
int EECON1bits_EEPGD;

/* STATUS - dummy declarations */
int STATUSbits_C;
int STATUSbits_DC;
int STATUSbits_Z;
int STATUSbits_OV;
int STATUSbits_N;

/* WDTCON - dummy declarations */
int WDTCONbits_SWDTEN;

#endif //_H_pic18f452_defs_h
