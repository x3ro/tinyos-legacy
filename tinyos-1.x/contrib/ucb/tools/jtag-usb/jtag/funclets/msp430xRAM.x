/* Hacked version of the linker script of a F1121.

The .text section is moved to the RAM. The segment size is set
to 2kB, so that this file can be used to link programs for all
MSP430 derrivates. However this has the disadvantage that no
error message is shown when more that the available RAM is used
on a smaller device.

chris <cliechti@gmx.net>
*/
OUTPUT_FORMAT("elf32-msp430","elf32-msp430","elf32-msp430")
OUTPUT_ARCH(msp:110)
MEMORY
{
  text   (rwx)  : ORIGIN = 0x0200,      LENGTH = 2K
  data   (rwx)  : ORIGIN = 0x0200,      LENGTH = 256
  bootloader(rx): ORIGIN = 0x0c00,      LENGTH = 1K
}
SECTIONS
{
  /* Read-only sections, merged into text segment: */
  .hash          : { *(.hash)             }
  .dynsym        : { *(.dynsym)           }
  .dynstr        : { *(.dynstr)           }
  .gnu.version   : { *(.gnu.version)      }
  .gnu.version_d   : { *(.gnu.version_d)  }
  .gnu.version_r   : { *(.gnu.version_r)  }
  .rel.init      : { *(.rel.init) }
  .rela.init     : { *(.rela.init)        }
  .rel.text      :
    {
      *(.rel.text)
      *(.rel.text.*)
      *(.rel.gnu.linkonce.t*)
    }
  .rela.text     :
    {
      *(.rela.text)
      *(.rela.text.*)
      *(.rela.gnu.linkonce.t*)
    }
  .rel.fini      : { *(.rel.fini) }
  .rela.fini     : { *(.rela.fini)        }
  .rel.rodata    :
    {
      *(.rel.rodata)
      *(.rel.rodata.*)
      *(.rel.gnu.linkonce.r*)
    }
  .rela.rodata   :
    {
      *(.rela.rodata)
      *(.rela.rodata.*)
      *(.rela.gnu.linkonce.r*)
    }
  .rel.data      :
    {
      *(.rel.data)
      *(.rel.data.*)
      *(.rel.gnu.linkonce.d*)
    }
  .rela.data     :
    {
      *(.rela.data)
      *(.rela.data.*)
      *(.rela.gnu.linkonce.d*)
    }
  .rel.ctors     : { *(.rel.ctors)        }
  .rela.ctors    : { *(.rela.ctors)       }
  .rel.dtors     : { *(.rel.dtors)        }
  .rela.dtors    : { *(.rela.dtors)       }
  .rel.got       : { *(.rel.got)          }
  .rela.got      : { *(.rela.got)         }
  .rel.bss       : { *(.rel.bss)          }
  .rela.bss      : { *(.rela.bss)         }
  .rel.plt       : { *(.rel.plt)          }
  .rela.plt      : { *(.rela.plt)         }
  /* Internal text space */
  .text :
  {
    *(.init)
    . = ALIGN(2);
    *(.text)
    . = ALIGN(2);
    *(.text.*)
    . = ALIGN(2);
    *(.fini)
     _etext = . ; 
  }  > text
  .data   : AT (ADDR (.text) + SIZEOF (.text))
  {  
     PROVIDE (__data_start = .) ; 
    . = ALIGN(2);
    *(.data)
    . = ALIGN(2);
    *(.gnu.linkonce.d*)
    . = ALIGN(2);
     _edata = . ; 
  }  > data
  /* bootloader */
  .bootloader   :
  {
     PROVIDE (__boot_start = .) ; 
    *(.bootloader)
    . = ALIGN(2);
    *(.bootloader.*)
  }  > bootloader
  /* Information memory */
  .infomem   :
  {
    *(.infomem)
    . = ALIGN(2);
    *(.infomem.*)
  }  > infomem
  .bss  SIZEOF(.data) + ADDR(.data) :
  {
     PROVIDE (__bss_start = .) ; 
    *(.bss)
    *(COMMON)
     PROVIDE (__bss_end = .) ; 
     _end = . ;  
  }  > data
  .vectors  :
/*	AT (ADDR (.text) + SIZEOF (.text) + SIZEOF (.data)) */
  {
     PROVIDE (__vectors_start = .) ; 
    *(.vectors*)
     _vectors_end = . ; 
  }  > vectors
  /* Stabs debugging sections.  */
  .stab 0 : { *(.stab) } 
  .stabstr 0 : { *(.stabstr) }
  .stab.excl 0 : { *(.stab.excl) }
  .stab.exclstr 0 : { *(.stab.exclstr) }
  .stab.index 0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment 0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info) *(.gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  PROVIDE (__stack = 0x300) ;
}
