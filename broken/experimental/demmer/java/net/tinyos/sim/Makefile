SUBDIRS = event plugins packet lossy script
ROOT = ../../..

PLUGINS_SRC = $(wildcard plugins/*.java)
PLUGINS = $(PLUGINS_SRC:.java=.class)
INITIAL_TARGETS = msgs #../sf/old/nido/NidoSerialDataSource.class 
OTHER_CLEAN = msgs-clean plugins-list-clean jarclean

# Uncomment this line to make jarfile mandatory
# FINAL_TARGETS = jarfile
FINAL_TARGETS = plugins/plugins.list

include $(ROOT)/Makefile.include

../sf/old/nido/NidoSerialDataSource.class: ../sf/old/nido/NidoSerialDataSource.java
	(cd ../sf/nido; $(MAKE))

msgs:
	(cd msg; $(MAKE))
msgs-clean:
	(cd msg; $(MAKE) clean)

# Create a list of default plugins
plugins/plugins.list: $(PLUGINS)
	echo $(PLUGINS) > plugins/plugins.list

plugins-list-clean:
	rm -f plugins/plugins.list

# This is ugly. The only way to embed a jar file inside another is to
# unpack it and repack them together into a single flat file.
jarfile: plugins/plugins.list
	@echo "Creating tinyviz.jar..."
	(cd $(ROOT); jar cmf net/tinyos/sim/tinyviz.manifest net/tinyos/sim/tinyviz-tmp.jar net/tinyos/sim/*.class net/tinyos/sim/ui net/tinyos/sim/plugins/*.class net/tinyos/sim/plugins/plugins.list net/tinyos/sim/event/*.class net/tinyos/sim/packet/*.class net/tinyos/sim/msg/*.class net/tinyos/sf/*.class net/tinyos/util/*.class net/tinyos/packet/*.class net/tinyos/message/*.class) 
	rm -rf jarbuild-tmp
	mkdir jarbuild-tmp
	(cd jarbuild-tmp; jar xf ../tinyviz-tmp.jar; jar xf ../$(ROOT)/jars/oalnf.jar; rm -rf META-INF; jar cmf ../tinyviz.manifest ../tinyviz.jar .)
	rm -rf tinyviz-tmp.jar jarbuild-tmp

jarclean:
	rm -f tinyviz.jar
