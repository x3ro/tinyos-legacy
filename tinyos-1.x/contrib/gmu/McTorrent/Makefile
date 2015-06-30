PLATFORM?=mica2

all:
	cd tools; make clean; make PLATFORM=$(PLATFORM)
	cd tos/lib/McTorrent/TOSBoot; make $(PLATFORM)
	cd apps/Erase; make $(PLATFORM)
	cd apps/TestMcTorrent/Basic; make $(PLATFORM)
	cd apps/TestMcTorrent/McBlink; make $(PLATFORM)

clean:
	cd tools; make clean
	cd tos/lib/McTorrent/TOSBoot; make clean
	cd apps/Erase; make clean
	cd apps/TestMcTorrent/Basic; make clean
	cd apps/TestMcTorrent/McBlink; make clean

