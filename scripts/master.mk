# Build DMD Master
# Created by: Diederik de Groot (2018)

GIT:=/usr/local/bin/git
CURL:=/usr/local/bin/curl
GITUSER:=dkgroot
QUIET:=
BUILD:=debug
MODEL:=64
NCPU:=4
BUILD_BASEIDR:=$(shell pwd)
BOOTSTRAP_DMD:=$(shell pwd)/bootstrap/install/dragonflybsd/bin64/dmd
INSTALL_DIR:=$(shell pwd)/master/install

.PHONY: all

all: master_dmd.tar.bz2

clone_master:
	[ -d master ] || mkdir master
	$(GIT) -C master clone -b dragonflybsd-master https://github.com/${GITUSER}/dmd.git
	$(GIT) -C master clone https://github.com/${GITUSER}/druntime.git
	cd master/druntime; $(GIT) checkout -b unittest;
	cd master/druntime; $(GIT) pull origin dragonflybsd-master dragonfly-core.sys.posix dragonfly-core.sys.dragonflybsd --commit -q --squash;
	$(GIT) -C master clone https://github.com/dlang/phobos.git
	touch $@
	
build_dmd: clone_master
	$(MAKE) -C master/dmd -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) all
	$(MAKE) -C master/dmd -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) INSTALL_DIR=$(INSTALL_DIR) install
	touch $@

build_release: clone_master
	$(MAKE) -C master/dmd -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) all
	touch $@

build_druntime: clone_master
	$(MAKE) -C master/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) 
	$(MAKE) -C master/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) INSTALL_DIR=$(INSTALL_DIR) install
	touch $@

build_phobos: clone_master
	$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU)
	$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) INSTALL_DIR=$(INSTALL_DIR) install
	touch $@

build_master: build_dmd build_druntime build_phobos build_release

test_druntime: build_druntime
	sysctl kern.coredump=0; $(MAKE) -C master/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) unittest

test_phobos: build_phobos
	#$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) unittest
	$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) unittest

test_dmd: build_release
	$(MAKE) -C master/dmd/src -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) build-examples
	$(MAKE) -C master/dmd/src -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) unittest

run_dmd_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU)

run_dmd_runnable_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) start_runnable_tests

run_dmd_compilable_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) start_compilable_tests

run_dmd_fail_compilation_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) start_fail_compilation_tests

test_master: test_druntime test_phobos test_dmd run_dmd_tests

master_dmd.tar.bz2: build_master
	tar cfj master_dmd.tar.bz2 master/install
	cd master; rm -rf dmd druntime phobos

master_restore: master_dmd.tar.bz2
	tar xfj master_dmd.tar.bz2
	touch $@

master: master_dmd.tar.bz2
	[ -d master/install ] || $(MAKE) -f $(MAKEFILE) master_restore;

clone_tools:
	$(GIT) -C master clone https://github.com/${GITUSER}/tools.git
	touch $@

patch_tools: clone_tools
	$(CURL) -s https://raw.githubusercontent.com/dkgroot/dragonflybsd_dmd_port/master/patches/tools.patch -o tools.patch
	$(GIT) -C master/tools apply --reject /root/tools.patch
	touch $@

build_tools: patch_tools build_release
	$(MAKE) -C master/tools -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET)

clone_dub:
	$(GIT) -C master clone https://github.com/${GITUSER}/dub.git
	touch $@

patch_dub: clone_dub
	$(CURL) -s https://raw.githubusercontent.com/dkgroot/dragonflybsd_dmd_port/master/patches/dub.patch -o dub.patch
	$(GIT) -C master/dub apply --reject /root/dub.patch
	touch $@

build_dub: patch_dub
	cd master/dub; DMD=$(BUILD_BASEDIR)/root/master/install/dragonflybsd/bin64/dmd ./build.sh
	touch $@

run_dub_test: build_dub
	cd master/dub; DUB=$(BUILD_BASEDIR)/master/dub/bin/dub DC=$(BUILD_BASEDIR)/master/install/dragonflybsd/bin64/dmd test/run-unittest.sh
