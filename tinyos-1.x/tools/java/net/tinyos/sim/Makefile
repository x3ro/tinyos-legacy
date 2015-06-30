SUBDIRS = event plugins packet lossy script
ROOT = ../../..

PLUGINS_SRC = $(wildcard plugins/*.java)
PLUGINS = $(PLUGINS_SRC:.java=.class)
INITIAL_TARGETS = msgs jython ../sf/old/nido/NidoSerialDataSource.class 
OTHER_CLEAN = msgs-clean plugins-list-clean jarclean

# Uncomment this line to make jarfile mandatory
FINAL_TARGETS = jarfile 

include $(ROOT)/Makefile.include

../sf/nido/NidoSerialDataSource.class: ../sf/old/nido/NidoSerialDataSource.java
	(cd ../sf/nido; $(MAKE))

msgs:
	(cd msg; $(MAKE))
msgs-clean:
	(cd msg; $(MAKE) clean)

# Make sure that jython gets built
jython: $(ROOT)/org/python/core/parser.class
$(ROOT)/org/python/core/parser.class:
	(cd $(ROOT)/org/python && $(MAKE))
	(cd $(ROOT)/org/apache && $(MAKE))

# Create a list of default plugins
plugins/plugins.list: $(PLUGINS)
	echo $(PLUGINS) > plugins/plugins.list

plugins-list-clean:
	rm -f plugins/plugins.list

# This is ugly. The only way to embed a jar file inside another is to
# unpack it and repack them together into a single flat file.
jarfile: plugins/plugins.list 
	@echo "Creating simdriver.jar..."
	(cd $(ROOT); \
		jar cmf net/tinyos/sim/simdriver.manifest \
		net/tinyos/sim/simdriver-tmp.jar \
		net/tinyos/sim/*.class                  \
		net/tinyos/sim/event/*.class            \
		net/tinyos/sim/lossy/*.class            \
		net/tinyos/sim/msg/*.class              \
		net/tinyos/sim/packet/*.class           \
		net/tinyos/sim/plugins/*.class          \
		net/tinyos/sim/script/*.class           \
                net/tinyos/sim/script/reflect/*.class   \
                net/tinyos/sim/ui                       \
                net/tinyos/sim/plugins/plugins.list     \
                net/tinyos/sf/*.class                   \
                net/tinyos/util/*.class                 \
                net/tinyos/packet/*.class               \
                net/tinyos/message/*.class              \
                net/tinyos/message/avrmote/*.class      \
                net/tinyos/message/telos/*.class        \
                net/tinyos/message/micaz/*.class        \
                org/apache/oro/text/regex/*.class       \
                org/python/compiler/*.class             \
                org/python/core/*.class                 \
                org/python/modules/*.class              \
                org/python/parser/*.class               \
                org/python/parser/ast/*.class           \
                org/python/rmi/*.class                  \
                org/python/util/*.class)                
	rm -rf jarbuild-tmp
	mkdir jarbuild-tmp
	(cd jarbuild-tmp; jar xf ../simdriver-tmp.jar; jar xf ../$(ROOT)/jars/oalnf.jar; rm -rf META-INF; jar cmf ../simdriver.manifest ../simdriver.jar .)
	rm -rf simdriver-tmp.jar jarbuild-tmp

jarclean:
	rm -f simdriver.jar
