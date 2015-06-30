#!/bin/bash

# Script to make another set of bt stack files from an already edited set.

sed 's/module HCIPacket0M/module HCIPacket1M/' < HCIPacket0M.nc |\
sed 's/UDR0/UDR1/' | sed 's/UCSR0B/UCSR1B/' | \
sed 's/TOSH_SET_UART_RXD0_PIN/TOSH_SET_UART_RXD1_PIN/' | \
sed 's/sbi (PORTF, 0);//' | \
sed 's/UBRR0L/UBRR1L/' | sed 's/UBRR0H/UBRR1H/' | \
sed 's/SIG_UART0_RECV/SIG_UART1_RECV/' | \
sed 's/UCSR0A/UCSR1A/' | sed 's/SIG_UART0_TRANS/SIG_UART1_TRANS/' | \
sed 's/SIG_UART0_DATA/SIG_UART1_DATA/' > HCIPacket1M.nc

sed 's/module HCICore0M/module HCICore1M/' < HCICore0M.nc > HCICore1M.nc

sed 's/module HPLBTUART0M/module HPLBTUART1M/' < HPLBTUART0M.nc | \
sed 's/UDR0/UDR1/' | sed 's/UCSR0B/UCSR1B/' | \
sed 's/TOSH_SET_UART_RXD0_PIN/TOSH_SET_UART_RXD1_PIN/' | \
sed 's/sbi (PORTF, 0);//' | \
sed 's/UBRR0L/UBRR1L/' | sed 's/UBRR0H/UBRR1H/' | \
sed 's/SIG_UART0_RECV/SIG_UART1_RECV/' | \
sed 's/UCSR0A/UCSR1A/' | sed 's/SIG_UART0_TRANS/SIG_UART1_TRANS/' | \
sed 's/SIG_UART0_DATA/SIG_UART1_DATA/' > HPLBTUART1M.nc

echo "You still have to edit HCIPacket1M.nc add the IntOutput interface and remove some init of the bt ports"