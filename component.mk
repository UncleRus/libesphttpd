#
# Component Makefile (for esp-idf)
#
# This Makefile should, at the very least, just include $(SDK_PATH)/make/component.mk. By default, 
# this will take the sources in this directory, compile them and link them into 
# lib(subdirectory_name).a in the build directory. This behaviour is entirely configurable,
# please read the SDK documents if you need to do this.
#

COMPONENT_SRCDIRS := core espfs util
COMPONENT_ADD_INCLUDEDIRS := core espfs util include
COMPONENT_ADD_LDFLAGS := -lwebpages-espfs -llibesphttpd

COMPONENT_EXTRA_CLEAN := mkespfsimage/*

HTMLDIR := $(subst ",,$(CONFIG_ESPHTTPD_HTMLDIR))

CFLAGS += -DFREERTOS

liblibesphttpd.a: libwebpages-espfs.a

webpages.espfs: $(PROJECT_PATH)/$(HTMLDIR) mkespfsimage/mkespfsimage
	$(summary) Making espfs image
ifeq ("$(CONFIG_ESPHTTPD_USEYUICOMPRESSOR)","yes")
	$(summary) Compression assets with yui-compressor. This may take a while...
	rm -rf html_compressed;
	cp -r ($(PROJECT_PATH)/$(HTMLDIR) html_compressed;
	for file in `find html_compressed -type f -name "*.js"`; do $(YUI-COMPRESSOR) --type js $$file -o $$file; done
	for file in `find html_compressed -type f -name "*.css"`; do $(YUI-COMPRESSOR) --type css $$file -o $$file; done
	awk "BEGIN {printf \"YUI compression ratio was: %.2f%%\\n\", (`du -b -s html_compressed/ | sed 's/\([0-9]*\).*/\1/'`/`du -b -s ../html/ | sed 's/\([0-9]*\).*/\1/'`)*100}"
# mkespfsimage will compress html, css, svg and js files with gzip by default if enabled
# override with -g cmdline parameter
	cd html_compressed; find . | $(THISDIR)/espfs/mkespfsimage/mkespfsimage > $(THISDIR)/webpages.espfs; cd ..;
else
	cd  $(PROJECT_PATH)/$(HTMLDIR) &&  find . | $(COMPONENT_BUILD_DIR)/mkespfsimage/mkespfsimage > $(COMPONENT_BUILD_DIR)/webpages.espfs
endif

libwebpages-espfs.a: webpages.espfs
	$(summary) AR espfs image
	$(OBJCOPY) -I binary -O elf32-xtensa-le -B xtensa --rename-section .data=.rodata \
		webpages.espfs webpages.espfs.o.tmp
	$(CC) -nostdlib -Wl,-r webpages.espfs.o.tmp -o webpages.espfs.o -Wl,-T $(COMPONENT_PATH)/webpages.espfs.esp32.ld
	$(AR) cru $@ webpages.espfs.o

mkespfsimage/mkespfsimage: $(COMPONENT_PATH)/espfs/mkespfsimage
	$(summary) mkespfsimage tool
	mkdir -p $(COMPONENT_BUILD_DIR)/mkespfsimage
	$(MAKE) -C $(COMPONENT_BUILD_DIR)/mkespfsimage -f $(COMPONENT_PATH)/espfs/mkespfsimage/Makefile \
		USE_HEATSHRINK="$(CONFIG_ESPHTTPD_ESPFS_HEATSHRINK)" \
		GZIP_COMPRESSION="$(CONFIG_ESPHTTPD_ESPFS_GZIP_COMPRESSION)" \
		BUILD_DIR=$(COMPONENT_BUILD_DIR)/mkespfsimage CC=$(HOSTCC)

