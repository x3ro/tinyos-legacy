$Id: README.txt,v 1.2 2005/03/15 06:23:20 jwhui Exp $

STM25P Storage Stack

- Project members/groups:
  * Jonathan Hui <jwhui@cs.berkeley.edu>

- This directory contains the storage stack implementation for the
STM25P family of chips. The implementation follows proposed TinyOS
Storage Abstraction being introduced in TinyOS 2.x and detailed in
tep103.

- The new storage stack now allows the user to partition the flash
into volumes. The flash is partitioned into segments with size equal
to a multiple of STORAGE_BLOCK_SIZE. An example for formating the
flash is included in beta/STM25P/TestStorage/. If the flash is not
formatted, it will automatically be formatted to the default
configuration. Currently, the default configuration includes only
those volumes required for Deluge to function.

- Implementation Status:
  - BlockStorage: nearly complete except commit()/verify(). Well
  tested under Deluge.
  - LogStorage: code complete, limited testing.
  - ConfigStorage: not implemented
