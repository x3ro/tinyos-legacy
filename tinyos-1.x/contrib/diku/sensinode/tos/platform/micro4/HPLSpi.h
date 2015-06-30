
#ifndef _H_HPLSpi_h
#define _H_HPLSpi_h

#define configCPU_CLOCK_HZ	( ( unsigned long ) 8000000 )

#ifndef configSMCLK_HZ
#define SPI_115K  (configCPU_CLOCK_HZ / 115200)
#define SPI_1M  (configCPU_CLOCK_HZ / 1000000)
#define SPI_4M  (configCPU_CLOCK_HZ / 4000000)
#else
#define SPI_115K  (configSMCLK_HZ / 115200)
#define SPI_1M  (configSMCLK_HZ / 1000000)
#define SPI_4M  (configSMCLK_HZ / 4000000)
#endif

	typedef enum
	{
		BUS_SPI_DEFAULT = 0x00,
		BUS_STE = 0x01,
		BUS_PHASE_INVERT = 0x02,
		BUS_CLOCK_INVERT = 0x04,
		BUS_MULTIMASTER = 0x08,
		BUS_CLOCK_115kHZ = 0x20,
		BUS_CLOCK_1MHZ = 0x40,
		BUS_CLOCK_4MHZ = 0x60,
		BUS_SPI_SLAVE = 0x80
	}bus_spi_flags;



#endif//_H_HPLSpi_h
