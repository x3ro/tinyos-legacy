#!/usr/bin/perl

# $Id: convert_tcm.pl,v 1.1 2005/04/13 16:38:06 hjkoerber Exp $

#
# Copyright (c) Helmut-Schmidt-University, Hamburg
#		 Dpt.of Electrical Measurement Engineering  
#		 All rights reserved
#
# Redistribution and use in source and binary forms, with or without 
#  modification, are permitted provided that the following conditions 
# are met:
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright 
#   notice, this list of conditions and the following disclaimer in the 
#   documentation and/or other materials provided with the distribution.
# - Neither the name of the Helmut-Schmidt-University nor the names 
#   of its contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED  
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#/

# @author Hans-Joerg Koerber 
#         <hj.koerber@hsu-hh.de>
#	  (+49)40-6541-2638/2627
# 
# $Date: 2005/04/13 16:38:06 $
# $Revision: 1.1 $
#

#-------------------------------------------------------------------------------------------------------------#       
#
#  This script will take the C file produced by nesC and 
#  make it compatible with the Microchip C18-Compiler
#                        
#-------------------------------------------------------------------------------------------------------------#


#-------------------------------------------------------------------------------------------------------------#       
#
# Command line paramters used when invoking the script
# 
#         First parameter  = source name  (app.c)
#         Second parameter = output name (app_pic.c) 
#                        
#-------------------------------------------------------------------------------------------------------------#


$source = $ARGV[0];
$output = $ARGV[1];

if ($source eq $output) {
	die("perl: source and output cannot be the same");
}

open(SOURCE,$source) or die("perl: Could not open source-file: $source");
open(OUTPUT,">$output") or die ("perl: Could not open output-file: $output");

$line_counter =0;

while (<SOURCE>)
{
    $line_counter ++;

#-------------------------------------------------------------------------------------------------------------#       
#
# In the following the syntax which MPLAB doesn't understand is removed and replaced by
# syntax which can be compiled without any trouble:
#                        
#-------------------------------------------------------------------------------------------------------------#

			s/^\# [0-9]+/\/\//;	                 # Convert # XXX statements  to//
			s/^\#line [0-9]+/\/\//;                  # Convert #line statements to //
			s/\$/_/g;		                 # Convert $ in all nesC-typical identifiers to _ 
			s/__inline//;		                 # This keyword is C99-standard thus it has to be removed
			s/inline//;			         # Keyword has to be removed
			s/__attribute\(\(packed\)\)//;           # Since MPLAB doesn't support neither _attribute(packed) nor #pragma pack() the expression
                                                                 # _attribute(packed) has to be removed 			
                        s/ __nesc_atomic_t __nesc_atomic/auto  __nesc_atomic_t __nesc_atomic/;  #adding an auto statement because MPLAB demands it
		


#-------------------------------------------------------------------------------------------------------------#       
# 
# Since MPLAB C18 deviates from ANSI standard X3.159-1989 it doen't support long long integertypes.
# So the respective lines in usr/local/avr/include/inttypes.h must be commented out.
#                        
#-------------------------------------------------------------------------------------------------------------#

			if (/long long/)   
			{
				$_ = '//' .$_;
			}
						
                        if (/progmem/)
                        {
			        $_ = '//' .$_; 
                        } 

# The following lines are needed as long as cc1000const.h is included                        

                        if (/static const prog_uchar/)
                        {
			        $_ = '/*' .$_; 
                        }


			if (/TRUE \} \}\;/)
                        {
			    $line= $_;
			    chomp $line;
			    $_ = $line."*/\n"; 
                        }

#                  	s/^.[x]...., /\/\//;

#-------------------------------------------------------------------------------------------------------------#       
# 
# Since MPLAB doesn't support neither _attribute(packed) nor #pragma pack() the expression
# _attribute(packed) has to be removed                       
#                        
#-------------------------------------------------------------------------------------------------------------#

			if (s/__attribute\(\(packed\)\)//)
                        {
			    print OUTPUT $_;
                        }
			

#-------------------------------------------------------------------------------------------------------------#       
# 
# Since the syntax of the pic's inline assembly can't be understood by gcc this backdoor is used
#                        
#      1. declaration of a dummy variable in the header pic18f452_defs.h
#      2. using the dummies by initialising them
#      3. replacement of the dummies by the original assembly lines using this script
#                        
#-------------------------------------------------------------------------------------------------------------#
			

			s/int asm_nop\;//;  

			s/asm_nop = 1\;/_asm nop _endasm\n/;    # converts"asm_nop = 1;" to "_asm nop _endasm"

                    	s/int asm_sleep\;//;  

			s/asm_sleep = 1\;/_asm sleep _endasm\n/;  # converts"asm_sleep = 1;" to "_asm sleep _endasm"  
	
			s/int asm_TBLWT\;//; 
                        
			s/asm_TBLWT = 1\;/_asm TBLWT _endasm\n/;  # converts"asm_TBLWT = 1;" to "_asm TBLWT _endasm"

                   	s/int asm_clrwdt\;//;  

			s/asm_clrwdt = 1\;/_asm clrwdt _endasm\n/;  # converts"asm_clrwdt = 1;" to "_asm clrwdt _endasm"  
                

#-------------------------------------------------------------------------------------------------------------#       
# 
# In order to use EnOcean assembler routines the following backdoor is used
#                        
#      1. declaration of a dummy variables in the header pic18f452_defs.h
#      2. using the dummies by initialising them
#      3. replacement of the dummies by the original assembly function declaratiosn and invocations  using 
#         this script
#                              
#-------------------------------------------------------------------------------------------------------------#

                 	s/int asm_(TX_SendMessage)\;/extern void $1\(void\)\;\n/;  # converts "int asm_TX_SendMessage;" to "extern void TX_SendMessage(void);"

			s/asm_(TX_SendMessage) = 1\;/$1\(\)\;/;                    # converts "asm_TX_SendMessage = 1;" to "TX_SendMessage();"
			
			s/int asm_(ISR_RxRadio)\;/extern char $1\(void\)\;\n/;     # converts "int asm_ISR_RxRadio;" to "extern char ISR_RxRadio(void);"
    
			s/asm_(ISR_RxRadio)/$1\(\)/;                               # converts "asm_ISR_RxRadio" to "ISR_RxRadio()"

			s/int (asm_rxBufptr)\;/extern char $1\;\n/;                # converts "int asm_rxBufptr;" to "extern char asm_rxBufptr;"




#-------------------------------------------------------------------------------------------------------------#       
#
# All lines which only contain comments should not apppear
#                        
#-------------------------------------------------------------------------------------------------------------#     

                   
			if(/^\/\//) 
			{
			    $_ = ""; 
                        }

#-------------------------------------------------------------------------------------------------------------#       
#
# All static arguments are put into the next line
#                        
#-------------------------------------------------------------------------------------------------------------#

			if(/^static[ ]*\n$/) 
			{
			    $line="static ";
			    $_ = $line; 
                        }

#-------------------------------------------------------------------------------------------------------------#
#
# The placement of the interrupt service routine has to be introduced to TinyOS using this backdoor. The output 
# of the if-statement will be as demanded in MPLAP C18 User's Guide 2.9.2.2. 
#
# It will look like:
# 
#      void InterruptHandler (void);
#
#
#      #pragma code low_vector=0x18
#      void low_interrupt (void)
#      {
#        _asm GOTO timer_isr _endasm
#      }
#      #pragma code
#
#
#      #pragma interruptlow InterruptHandler save=PROD
#      void InterruptHandler (void)
#      {
#         perform interrupt instruction here
#      }
#
#-------------------------------------------------------------------------------------------------------------#     


			s/__attribute\(\(interrupt\)\)//;
			
			if(/void    InterruptHandler\(void\)[ ]*\n/)
			{
			    $_="\#pragma code InterruptVector = 0x08\nvoid InterruptVector (void)\n  \{\n    _asm GOTO InterruptHandler _endasm\n  \}\n\#pragma code\n\#pragma interruptlow InterruptHandler save=PROD\nvoid InterruptHandler (void)\n"
			}   

	
#-------------------------------------------------------------------------------------------------------------#       
#
# Adding the rom qualifier to the crc string constant defined in crc8.h and crc16.h 
#                        
#-------------------------------------------------------------------------------------------------------------#

			s /int8_t crc8/rom int8_t crc8/; 

 		        s /uint16_t crc16/rom uint16_t crc16/;

#-------------------------------------------------------------------------------------------------------------#       
#
# Since ncc doesn't not unerstand the register/pin_definitions from the microchip header p18f452.h the following 
# backdoor is used to handle the pins in nesC
#      
#      1. Defining all the pins as "int foobits_foobit" and the registers as "int foo" in a  header pic18f452.h
#                     -> e.g. "int INTCONbits_GIE" or "int PORTB"
#      2. Using the so defined pins in the nesC-files
#      3. After compiling with ncc all the foobits_foobit are replaced by foobits.foo using this script
#      4. The perl-script puts the original microchip header  p18f452.h at the first line of the 
#         converted app.c
#-------------------------------------------------------------------------------------------------------------#


			if ($line_counter==1)
			{
			    $_="\#include <p18f452.h>\n\#include <cfg.h>\n\#define _CONFIG 1\n";    # includes header-files <p18f452.h> and <cfg.h> and the config macro at the first line
		        }    

			if(/int[ ][\w]+bits_/)               # removes the declaration int foobits_foobit, e.g.int INTCONbits_GIE;
                      	{                                     
			    $_="";
		        }


                        s/([0-9A-z]+bits)_/ $1./g;            # converts foo_foobits_foobit into foobits.foobit, e.g. PIC18F452InterruptM_INTCONbits_GIE  -> INTCONbits.GIE

			if(/int[ ][\w]+_register/)           # removes the declaration int foo_register, e.g.int ADCON0_register;
                      	{                                     
			    $_="";
		        }

                        s/([0-9A-z]+)_register/ $1/g;        # converts foo_register into foo, e.g. ADCON0_register  -> ADCON0

#-------------------------------------------------------------------------------------------------------------#       
#
# All the blank lines of the original app.c must not appear in app_pic.c
#
#-------------------------------------------------------------------------------------------------------------#

			unless (/^\n/) 
                        {			       
				print OUTPUT $_;			
			}

		
	
}

close(OUTPUT);
close(SOURCE);

