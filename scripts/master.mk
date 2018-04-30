# Build DMD Master
# Created by: Diederik de Groot (2018)

GIT:=/usr/local/bin/git
CURL:=/usr/local/bin/curl
GITUSER:=dlang
QUIET:=
BUILD:=debug
MODEL:=64
NCPU:=4
BUILD_BASEDIR:=$(shell pwd)
INSTALL_DIR:=/usr/local/dmd
BOOTSTRAP_DMD:=$(shell pwd)/bootstrap/install/dragonflybsd/bin64/dmd
MASTER_DMD:=$(INSTALL_DIR)/dragonflybsd/bin64/dmd

.PHONY: all

all: master_dmd.tar.bz2

clone_master:
	[ -d master ] || mkdir master
	$(GIT) -C master clone https://github.com/$(GITUSER)/dmd.git
	$(GIT) -C master clone https://github.com/$(GITUSER)/druntime.git
	#$(GIT) -C master clone -b fix_core_stdc_math https://github.com/dkgroot-dlang/druntime.git
	$(GIT) -C master clone https://github.com/$(GITUSER)/phobos.git
	#$(GIT) -C master clone -b fix_stdio_could_not_close_pipe https://github.com/dkgroot-dlang/phobos.git
	touch $@

	
build_dmd: clone_master
	$(MAKE) -C master/dmd -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU) all
	$(MAKE) -C master/dmd -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) INSTALL_DIR=$(INSTALL_DIR) install
	ln -s $(INSTALL_DIR)/dragonflybsd/bin64/dmd /usr/local/bin/dmd
	ln -s $(INSTALL_DIR)/dragonflybsd/bin64/dmd.conf /usr/local/etc/dmd.conf
	touch $@

build_druntime: clone_master
	$(MAKE) -C master/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) 
	$(MAKE) -C master/druntime -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) INSTALL_DIR=$(INSTALL_DIR) install
	touch $@

build_phobos: clone_master
	$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU)
	$(MAKE) -C master/phobos -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) INSTALL_DIR=$(INSTALL_DIR) install
	touch $@

build_phobos_release: build_phobos

build_master: build_dmd build_druntime build_phobos

test_druntime: build_druntime
	sysctl kern.coredump=0; $(MAKE) -C master/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) unittest

test_phobos: build_phobos
	$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) unittest

test_phobos_publictests: build_phobos build_dub
	$(MAKE) -C master/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) publictests

test_dmd:
	$(MAKE) -C master/dmd/src -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(MASTER_DMD) -j$(NCPU) build-examples
	$(MAKE) -C master/dmd/src -f posix.mak BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(MASTER_DMD) -j$(NCPU) unittest

run_dmd_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(MASTER_DMD) -j$(NCPU)

run_dmd_runnable_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(MASTER_DMD) -j8 start_runnable_tests

run_dmd_compilable_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(MASTER_DMD) -j$(NCPU) start_compilable_tests

run_dmd_fail_compilation_tests:
	$(MAKE) -C master/dmd/test -f Makefile BUILD=release MODEL=$(MODEL) QUIET=$(QUIET) HOST_DMD=$(MASTER_DMD) -j$(NCPU) start_fail_compilation_tests

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
	$(GIT) -C master clone https://github.com/dkgroot/tools.git
	touch $@

build_tools: clone_tools
	$(MAKE) -C master/tools -f posix.mak BUILD=debug MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU)

clone_dub:
	$(GIT) -C master clone https://github.com/$(GITUSER)/dub.git
	touch $@

build_dub: clone_dub build_dmd
	cd master/dub; DMD=$(INSTALL_DIR)/dragonflybsd/bin64/dmd ./build.sh
	ln -s /root/master/dub/bin/dub /usr/local/bin/dub
	touch $@

run_dub_test: build_dub
	cd master/dub; DUB=/usr/local/bin/dub DC=$(INSTALL_DIR)/dragonflybsd/bin64/dmd test/run-unittest.sh; exit 0
