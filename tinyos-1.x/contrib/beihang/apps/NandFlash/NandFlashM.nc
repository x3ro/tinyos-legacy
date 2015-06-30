/*
 * file:        NandFlashC.nc
 * description: implementation of NAND flash driver with echo and inferface for TL-Tree Project
				Details can be found at http://nand.bicoup.com
 * author:      Gong Zhang, Beihang Univ. Computer Science Dept. 05/2011
 */

/*
 * file:        NandFlashC.nc
 * description: implementation of NAND flash driver
 *
 * author:      Peter Desnoyers, UMass Computer Science Dept.
 * $Id: NandFlashM.nc,v 1.1 2011/08/14 16:37:54 dukenunee Exp $
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

module NandFlashM {
    provides interface StdControl;
    uses {
	interface PageNAND;
	interface Console;
    }
}

implementation {
    #define NAND_WE_PORT PORTD
	#define NAND_WE_BIT 0
	#define NAND_RE_PORT PORTD
	#define NAND_RE_BIT 1
	
    command result_t StdControl.init() {
	call Console.init();
	return SUCCESS;
    }

    command result_t StdControl.start() {
	call Console.printf0("System Init Done");
	call Console.newline();
	return SUCCESS;
    }
    
    command result_t StdControl.stop() {
        return SUCCESS;
    }
    
    result_t verifyNAND(uint8_t *buf, uint8_t val) {
	uint16_t i;
	for (i = 0; i < 512; i++)
	    if (buf[i] != val)
		return FAIL;
	return SUCCESS;
    }
    
    uint8_t unhex(char c) {
	if (c >= 'A')
	    return c - 'A' + 10;
	return c - '0';
    }

    uint32_t hex2long(char *s) {
	uint32_t val = 0;
	while ((*s >= '0' && *s <= '9' )|| (*s >= 'A' && *s <= 'F')) {
	    val = val << 4;
	    val = val + unhex(*s++);
	}
	return val;
    }
    
    /*    
     * i - read and print ID register
     * v xx - set value to hex value
     * w xxxxxx - write block <xxxxxx> with <value>
     * r xxxxxx - read block <xxxxxx> and verify =<value>
     * e xxxxxx - erase block <xxxxxx>
     * I - init
    */

    uint8_t val;
    uint8_t cmd;
    nandpage_t addr;
    uint8_t buf[528];
	uint8_t buf1[32767];//max 32k
	uint8_t buf2[4095];//4k
	
    int i, last;
    
    task void do_cmd() 
	{
		//result_t status = FAIL;
		result_t status = SUCCESS;
		register uint8_t we_1, we_0;
		
		if (cmd == 'I')
		{
			status = call PageNAND.init();		
			call Console.printf0("Command I> Init NAND");			
		}
		else if (cmd == 'i') 
		{			
			call Console.printf0("read and print ID register :");	
			status = call PageNAND.id(buf);				
			call Console.printf2(" Maker code: %x2, Device code: %x2 ", buf[0],buf[1]);	
			
		}
		else if (cmd == 'w') 
		{		
			call Console.printf0("Command w> ");			
			call Console.printf2("write block : %x4 with value : %x2\n", addr, val);		
			memset(buf, val, sizeof(buf));
			status = call PageNAND.write(addr, 0, buf, sizeof(buf));
			status = SUCCESS;
		}
		else if (cmd == 'W') 
		{
		
			call Console.printf0("Command W>");
			call Console.printf2("write incrementing values starting at %x2 to page %x4\n", val, addr);
		
			for (i = 0; i < sizeof(buf); i++) /* set incrementing values */
			buf[i] = val + i;
			status = call PageNAND.write(addr, 0, buf, sizeof(buf));
		}
		else if (cmd == 'r') 
		{		
			call Console.printf0("Command r>");
			call Console.printf1("read page %x4 :", addr);		
			status = call PageNAND.read(addr, 0, buf, sizeof(buf));
			for (i = 0; i < sizeof(buf); i++)
				call Console.printf1("%x2",buf[i]);
			
		}
		else if (cmd == 'R') 
		{
		#ifdef DEBUG_NANDB
			call Console.printf0("Command R>");
			call Console.printf1("read page %x4 , print unique bytes :", addr);
			call Console.printf1("block: %x4\n", addr);
		#endif
			memset(buf, 0, sizeof(buf));
			status = call PageNAND.read(addr, 0, buf, sizeof(buf));
			for (i = 0, last = -1; i < sizeof(buf); i++)
			if (last != buf[i]) 
			{
				last = buf[i];
			#ifdef DEBUG_NANDB
				call Console.printf2("%d: %x2\n", i, last);
			#endif
			}
		}
		else if (cmd == 'z') 
		{
		#ifdef DEBUG_NANDB
			call Console.printf0("Command z>");
			call Console.printf2("print bytes %x4 to %x4 from last page read with 'r'", addr,addr+15);			
			for (i = addr; i < addr+16; i++)
			call Console.printf1(" %x2", buf[i]);
			call Console.newline();
		#endif
			status = SUCCESS;
		}
		else if (cmd == 'e'){
		#ifdef DEBUG_NANDB
			
		#endif
			call Console.printf0("Command e>");
			call Console.printf1("erase block containing page %x4",addr);
			status = call PageNAND.erase(addr);
			
		}
		else if (cmd == '?')
		{
		#ifdef DEBUG_NAND
			call Console.printf0("Command ?>");
			call Console.printf2("addr = %x4, val = %x2\n", addr, val);
		#endif
			status = SUCCESS;
		}
		else if(cmd == 'S'){
			
		}
		if (status == SUCCESS )
			call Console.printf0("SUCCESS");
		else
			call Console.printf0("FAILED");
	#ifdef DEBUG_NAND
		
	#endif	
    }

    event result_t PageNAND.initDone(result_t r) {
	return SUCCESS;
    }
    event result_t PageNAND.eraseDone(result_t r) {
	return SUCCESS;
    }
    event result_t PageNAND.writeDone(result_t r) {
	return SUCCESS;
    }
    event result_t PageNAND.readDone(result_t r) {
	return SUCCESS;
    }
	event result_t PageNAND.falReadDone(result_t r){
	return SUCCESS;
    }

    bool unlocked = FALSE;
	
	
    event void Console.input(char *s) 
	{
		if ((cmd = s[0]) == 0)
		   return;				

		if (cmd == 'v') 
		{			
			val = hex2long(s+2);	
		#ifdef DEBUG_NAND
			call Console.printf1("val = %x2 ", val);	
			
		#endif							
		}
		if(cmd == 'a')
		{			
			addr = hex2long(s+2);	
		#ifdef DEBUG_NAND
			call Console.printf1("addr = %x4 ", addr);				
		#endif							
		}
		else {				
			post do_cmd();
		}
    }
}
