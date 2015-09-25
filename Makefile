.PHONY: all
all:

OBJECT_NAMES = resources.o util.o display.o byte_buffer.o load_image.o string.o input.o

CPP_FLAGS += -fsanitize=address -fno-omit-frame-pointer -fno-exceptions -fno-rtti -Ibuild/native -Isrc -g -Wall -Wextra -Werror
COMPILE_CPP = $(CROSS_PREFIX)g++ -c -std=c++14 -o $@ -MMD -MP -MF $@.d $(CPP_FLAGS) $(shell $(CROSS_PREFIX)pkg-config --cflags SDL2_ttf sdl2 libpng) $<

LINK_FLAGS += -lm -lrucksack -lasan $(TARGET_SPECIFIC_LINK_FLAGS)
LINK = $(CROSS_PREFIX)gcc -o $@ $^ $(LINK_FLAGS) $(shell $(CROSS_PREFIX)pkg-config --libs SDL2_ttf sdl2 libpng)

# ld is not allowed to omit functions and global variables defined in .o files,
# but it can omit unused content from .a static libraries.
# first make a static library with ar, then make our binary out of that.
LINK_SPARSE = rm -f $@.a; $(foreach f,$^,$(CROSS_PREFIX)ar qcs $@.a $f;) $(CROSS_PREFIX)gcc -o $@ $@.a $(LINK_FLAGS)

THE_VERSION := $(shell echo $$(echo -n $$(cat version.txt)).$$(echo -n $$(git rev-parse --short HEAD)))
# this file has the full version number in its name.
# depend on this whenever you depend on the exact full version number.
VERSION_FILE = build/the_version_is.$(THE_VERSION)
$(VERSION_FILE): version.txt | build
	touch "$@"
build/full_version.txt: $(VERSION_FILE)
	echo -n "$(THE_VERSION)" > $@
%/resources: build/full_version.txt
	rucksack bundle assets.json $(dir $@)resources --deps $@.d
	rucksack strip $(dir $@)resources
%/resources.o: %/resources
	@# the name "resources" is where these symbol names come from:
	@#   _binary_resources_start _binary_resources_end _binary_resources_size
	@# but wait, in windows, the leading underscore is not present, resulting in these names:
	@#    binary_resources_start  binary_resources_end  binary_resources_size
	cd $(dir $@) && $(CROSS_PREFIX)ld -r -b binary resources -o $(notdir $@)

.PHONY: test
test: build/native/test
	build/native/test

.PHONY: native
all: native
-include $(wildcard build/native/*.d)
OBJECTS_native = $(foreach f,$(OBJECT_NAMES),build/native/$f)
$(OBJECTS_native) build/native/main.o build/native/test.o: CROSS_PREFIX =
build/native/%.o: src/%.cpp
	$(COMPILE_CPP)

build/native/prismoid build/native/test: TARGET_SPECIFIC_LINK_FLAGS =
build/native/prismoid build/native/test: CROSS_PREFIX =
build/native/prismoid: $(OBJECTS_native) build/native/main.o
	$(LINK)
build/native/test: $(OBJECTS_native) build/native/test.o
	$(LINK_SPARSE)
native: build/native/prismoid

$(OBJECTS_native) build/native/main.o build/native/resources: | build/native
build/native:
	mkdir -p $@


# cross compiling for windows.
# See README.md for instructions.
.PHONY: windows
-include $(wildcard build/windows/*.d)
CROSS_windows = $(MXE_HOME)/usr/bin/i686-w64-mingw32.static-
OBJECTS_windows = $(foreach f,$(OBJECT_NAMES),build/windows/$f)
$(OBJECTS_windows) build/windows/main.o: CROSS_PREFIX = $(CROSS_windows)
build/windows/%.o: src/%.cpp
	$(if $(MXE_HOME),,$(error MXE_HOME is not defined))
	$(COMPILE_CPP)

build/windows/prismoid.exe: TARGET_SPECIFIC_LINK_FLAGS = -static -mconsole
build/windows/prismoid.exe: CROSS_PREFIX = $(CROSS_windows)
build/windows/prismoid.exe: $(OBJECTS_windows) build/windows/main.o
	$(LINK)
windows: build/windows/prismoid.exe

$(OBJECTS_windows) build/windows/main.o build/windows/resources: | build/windows
build/windows:
	mkdir -p $@


.PHONY: publish-windows
PUBLISH_EXE_NAME = prismoid-$(THE_VERSION).exe
FULL_PUBLISH_EXE_NAME = build/publish-windows/$(PUBLISH_EXE_NAME)
publish-windows: $(FULL_PUBLISH_EXE_NAME)

$(FULL_PUBLISH_EXE_NAME): build/windows/prismoid.exe | build/publish-windows
	cp $< $@.tmp.exe
	upx $@.tmp.exe
	mv $@.tmp.exe $@
	touch $@

build/publish-windows:
	mkdir -p $@


build:
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf build
