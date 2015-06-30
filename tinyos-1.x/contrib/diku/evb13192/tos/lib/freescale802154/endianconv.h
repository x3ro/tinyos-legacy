#ifndef _ENDIANCONV_H_
#define _ENDIANCONV_H_

	static void NTOUHCPY64(uint8_t *src, uint8_t *dst)
	{
		dst[0] = src[7];
		dst[1] = src[6];
		dst[2] = src[5];
		dst[3] = src[4];
		dst[4] = src[3];
		dst[5] = src[2];
		dst[6] = src[1];
		dst[7] = src[0];
	}
	
	static void NTOUHCPY32(uint8_t *src, uint8_t *dst)
	{
		dst[0] = src[3];
		dst[1] = src[2];
		dst[2] = src[1];
		dst[3] = src[0];
	}
	
	static void NTOUHCPY16(uint8_t *src, uint8_t *dst)
	{
		dst[0] = src[1];
		dst[1] = src[0];		
	}
	
	static uint32_t NTOUH32(uint32_t n)
	{
		char* base = (char*)&n;
		return (uint32_t)base[3] << 24 |
		       (uint32_t)base[2] << 16 |
		       (uint32_t)base[1] <<  8 |
		       (uint32_t)base[0];		
	}
	
	static uint16_t NTOUH16(uint16_t n)
	{
		char* base = (char*)&n;
		return (uint16_t)base[1] << 8 |
		       (uint16_t)base[0];		
	}
#endif
