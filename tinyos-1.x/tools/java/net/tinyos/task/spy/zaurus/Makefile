NAME=spy-tool
VERSION=1.1-1
ARCH=arm
ZAURUS=6000

all: $(NAME)-$(ZAURUS)_$(VERSION)_$(ARCH).ipk

all: $(NAME)-$(ZAURUS)_$(VERSION)_$(ARCH).ipk

$(NAME)-$(ZAURUS)_$(VERSION)_$(ARCH).ipk: data-dir
	sh ipkg-build.sh data-dir

data-dir: FORCE
	(cd ..; make)
	./build-data-dir $(ZAURUS) $(VERSION)

FORCE:

.phony: FORCE
