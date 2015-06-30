/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Mark Yarvis
 *
 */

#include "hexutil.h"

#include <string.h>
#include <stdio.h>

#include "clientsocket.h"
#include "exception.h"



extern bool isQuiet;

bool HexUtil::recieveMsg(ClientSocket* cSocket, unsigned char* buffer){
	int pos = 0;


	do {
		cSocket->recieve(&buffer[pos],1);
		if (pos >= BUFFER_SIZE)
			throw new Exception(cSocket,"Application sending too much data: Disconnecting");

	} while (buffer[pos++] != '\n');


	if (!hexAsciiToBin(buffer, pos)){
		printf("Error: Could not convert ascii-hex text to binary from Application\n");
		return false ;
	}

	return true;
}

void HexUtil::printHexString(char* from, const unsigned char* buffer, int length){
	if (isQuiet) return;

	char tmp[4];
	printf(from);
	printf("\n");
	for (int i = 0; i < length; i++)
		printf("%s",byteToHexString(buffer[i],tmp));
	printf("\n\n");
	fflush(stdout);
}

unsigned char* HexUtil::binToHexAscii(const unsigned char* buffer, int& length){
	char tmp[4];
	for (int i = 0; i < length; i++){
		strncpy((char *)&output[i*3],byteToHexString(buffer[i],tmp),3);
	}
	length *= 3;
	output[length-1] = '\n';
	return output;

}


bool HexUtil::hexAsciiToBin(unsigned char* buffer, int& length) {
	char out[BUFFER_SIZE];
	int out_i=0;
	int i=0;

	while (true) {
		while ((i < length) && isWhitespace(buffer[i])) { // skip whitespace
		i++;
		}

		if (i >= length) {
		return false;     // string can't end here
		}

		if (!isHexDigit(buffer[i])) {  // check first hex digit
		return false;
		}

		out[out_i++] = buffer[i++]; // copy byte

		if (i >= length) {
		return false;     // string can't end here
		}

		if (!isHexDigit(buffer[i])) { // check second hex digit
		return false;
		}

		out[out_i++] = buffer[i++]; // copy byte

		while ((i < length) && isWhitespace(buffer[i])) { // skip whitespace
		i++;
		}

		if (i >= length) {
		return false;     // string can't end here
		}

		if (buffer[i] == '\n') {  // this is end of message
			out[out_i++] = '\n';  // add a newline to the end

			// update the length and copy the string back
			length = out_i;
			bcopy(out, buffer, length);

			break;   // success!
		}

		out[out_i++] = ' ';
	}


	int j = 0;
	unsigned char* temp = buffer;

	do {
		buffer[j++] = (hexToDecimal(*(temp++))<<4) | hexToDecimal(*(temp++));
	} while (*(temp++) != '\n');

	length = j;
	return true;
}


int HexUtil::hexToDecimal(char c) {
	if ((c>='0') && (c<='9')) {
		return c - '0';
	} else if ((c>='a') && (c<='f')) {
		return c - 'a' + 10;
	} else if ((c>='A') && (c<='F')) {
		return c - 'A' + 10;
	} else {
		fprintf(stderr, "ERROR: Bad character in hex value: %c\n", c);
		return 0;
	}
}



char* HexUtil::byteToHexString(char b, char *s) {
	s[0] = intToHexChar((b>>4)&0xf);
	s[1] = intToHexChar(b&0xf);
	s[2] = ' ';
	s[3] = '\0';
	return s;
}

char HexUtil::intToHexChar(int n) {
	if (n < 10) {
		return n + '0';
	} else {
		return n - 10 + 'A';
	}
}


bool HexUtil::isHexDigit(char c) {
	return (((c>='0') && (c<='9')) ||
		((c>='a') && (c<='f')) ||
		((c>='A') && (c<='F')));
}


bool HexUtil::isWhitespace(char c) {
	return ((c == ' ') || (c == '\t') || (c == '\r'));
}
