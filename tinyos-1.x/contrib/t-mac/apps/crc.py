#!/usr/bin/python

import re,sys
from os import system

data = re.compile("_PKT_DATA (\d+)")
end = re.compile("_RADIO_STATE 2")
items = [[]]
for x in sys.stdin.readlines():
	r = data.search(x)
	if r!=None:
		items[-1].append(int(r.group(1)))
	else:
		r = end.search(x)
		if r!=None:
			items.append([])

def bin(inp,minbits=8):
	out = ""
	while inp>0:
		out = str(inp % 2) + out
		inp = int(inp/2)
	if len(out)<minbits:
		out = ((minbits-len(out))*"0")+out
	return out

while True:
	try:
		items.remove([])
	except:
		break
print items

f = open("/tmp/junk.c",'w')
print >>f,"#include <stdint.h>"
print >>f,"#define PACKETS %d"%len(items)
print >>f,"""
struct block {
	uint8_t data;
	char *binary;
};
struct packet {
	uint8_t length;
	struct block data[256];
};"""
print >>f,"struct packet items[] = {"
for n in range(len(items)):
	p = items[n]
	if len(p)==0:
		continue
	print >>f,"\t%d,{"%len(p),
	for x in range(len(p)):
		print >>f,"{%d,\"%s\"}"%(p[x],bin(p[x])),
		if x!=len(p)-1:
			print >>f,",",
	print >>f,"}",
	if n!=len(items)-1:
		print >>f,","
	else:
		print >>f,""
print >>f,"};"

print >>f,"""
uint16_t update_crc(uint8_t data, uint16_t crc)
{
    crc  = (uint8_t)(crc >> 8) | (crc << 8);
    crc ^= data;
    crc ^= (uint8_t)(crc & 0xff) >> 4;
    crc ^= (crc << 8) << 4;
    crc ^= ((crc & 0xff) << 4) << 1;
	return crc;
}

/*int16_t update_crc(char data, int16_t crc)
{
	char i;
	int16_t tmp;
	tmp = (int16_t) (data);
	crc = crc ^ (tmp << 8);
	for (i = 0; i < 8; i++)
	{
		if (crc & 0x8000)
			crc = crc << 1 ^ 0x1021;	// << is done before ^
		else
			crc = crc << 1;
	}
	return crc;
}*/



int main()
{
	int16_t i,k,crc;
	uint8_t test[2];
	for (i=0;i<PACKETS;i++)
	{
		struct packet *p = &(items[i]);
		crc = 0; 
		printf("New packet: length=%d\\n",p->length);
		for (k=0;k<p->length;k++)
		{
			crc = update_crc(p->data[k].data,crc);
			memcpy(&test,&crc,2);
			printf("Data = %02d(%s), CRC = %02d,%02d\\n",p->data[k].data,p->data[k].binary,test[0],test[1]);
		}
		printf("\\n");
	}
	return 0;
}"""
f.close()

system("gcc /tmp/junk.c -o /tmp/junk")
system("/tmp/junk")

