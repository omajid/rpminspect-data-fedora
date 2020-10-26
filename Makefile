MESON_BUILD_DIR = build
topdir := $(shell realpath $(dir $(lastword $(MAKEFILE_LIST))))

# Project information (may be an easier way to get this from meson)
PROJECT_NAME = $(shell grep ^project $(topdir)/meson.build | cut -d "'" -f 2)
PROJECT_VERSION = $(shell grep version $(topdir)/meson.build | grep -E ',$$' | cut -d "'" -f 2)

all: setup
	ninja -C $(MESON_BUILD_DIR) -v

setup:
	meson setup $(MESON_BUILD_DIR)

check: setup
	meson test -C $(MESON_BUILD_DIR) -v

srpm:
	$(topdir)/utils/srpm.sh

new-release:
	$(topdir)/utils/release.sh -A

release:
	$(topdir)/utils/release.sh -t -p

koji:
	@if [ ! -f $(RELEASED_TARBALL) ]; then \
		echo "*** Missing $(RELEASED_TARBALL), be sure to have run 'make release'" >&2 ; \
		exit 1 ; \
	fi
	@if [ ! -f $(RELEASED_TARBALL_ASC) ]; then \
		echo "*** Missing $(RELEASED_TARBALL_ASC), be sure to have run 'make release'" >&2 ; \
		exit 1 ; \
	fi
	$(topdir)/utils/submit-koji-builds.sh $(RELEASED_TARBALL) $(RELEASED_TARBALL_ASC) $$(basename $(topdir))

clean:
	-rm -rf $(MESON_BUILD_DIR)

help:
	@echo "rpminspect-data-fedora helper Makefile"
	@echo "The source tree uses meson(1) for building and testing, but this Makefile"
	@echo "is intended as a simple helper for the common steps."
	@echo
	@echo "    all          Default target, setup tree to build and build"
	@echo "    setup        Run 'meson setup $(MESON_BUILD_DIR)'"
	@echo "    check        Run 'meson test -C $(MESON_BUILD_DIR) -v'"
	@echo "    srpm         Generate an SRPM package of the latest release"
	@echo "    release      Tag and push current tree as a release"
	@echo "    new-release  Bump version, tag, and push current tree as a release"
	@echo "    koji         Run 'make srpm' then 'utils/submit-koji-builds.sh'"
	@echo "    clean        Run 'rm -rf $(MESON_BUILD_DIR)'"
	@echo
	@echo "To build:"
	@echo "    make"
	@echo
	@echo "To run the test suite:"
	@echo "    make check"
	@echo
	@echo "Make a new release on Github:"
	@echo "    make release         # just tags and pushes"
	@echo "    make new-release     # bumps version number, tags, and pushes"
	@echo
	@echo "Generate SRPM of the latest release and do all Koji builds:"
	@echo "    env BRANCHES=\"master f31 f32 f33 epel7 epel8\" make koji"
	@echo "NOTE: You must set the BRANCHES environment variable for the koji target"
	@echo "otherwise it will just build for the master branch."
