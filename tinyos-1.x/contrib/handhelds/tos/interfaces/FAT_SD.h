/*
 * Copyright (c) 2008, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 ***************************************************************************
 *
 * Stephen Linder spl@alum.mit.edu
 * January 2008
 *
 * A FAT file system interface to the SD card on SHIMMER. See FAT_SD_M.nc.
 ***************************************************************************
 */
#include "dosfs.h"

#define NULL      0
#define EOF       (-1)
#define BUFSIZ    SECTOR_SIZE

struct _FILE {
	FILEINFO 	fi;
	uint32_t	startBlock;
	uint32_t  	lengthInBlocks;
	uint32_t	charactersLeft;
	uint8_t*	charPointer;
	uint8_t*	buffer;
	uint16_t	flags;

};

typedef struct _FILE FILE;

FILE *fopen(char *name, char *mode);
int _fillbuf(FILE *);
int _flushbuf(int, FILE *);

#define getc(p)   (–(p)->charactersLeft >= 0 \
                  ? (unsigned char) *(p)->charPointer++ : _fillbuf(p))
#define putc(x,p) (–(p)->charactersLeft >= 0 \
                  ? *(p)->charPointer++ = (x) : _flushbuf((x),p))
