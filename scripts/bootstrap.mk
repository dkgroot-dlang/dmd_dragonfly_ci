# Build DMD Bootrap
# Created by: Diederik de Groot (2018)

GIT:=git
GITUSER:=dkgroot
QUIET:=
BUILD:=debug
MODEL:=64
NCPU:=4
INSTALL_DIR:=$(shell pwd)/bootstrap/install

.PHONY: all

all: bootstrap_dmd.tar.bz2

clone_bootstrap:
	[ -d bootstrap ] || mkdir bootstrap
	$(GIT) -C bootstrap clone -b dragonflybsd_v2.067.1 https://github.com/${GITUSER}/dmd.git
	$(GIT) -C bootstrap clone -b dmd-cxx https://github.com/${GITUSER}/druntime.git
	$(GIT) -C bootstrap clone -b dmd-cxx https://github.com/${GITUSER}/phobos.git
	touch $@
	
build_dmd: clone_bootstrap
	$(MAKE) -C bootstrap/dmd -f posix.mak ENABLE_WARNINGS=1 DEBUG=1 BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ -j$(NCPU) all
	$(MAKE) -C bootstrap/dmd -f posix.mak DEBUG=1 BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) HOST_CSS=g++ -j$(NCPU) INSTALL_DIR=$(INSTALL_DIR) install

build_druntime: clone_bootstrap
	$(MAKE) -C bootstrap/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU) 
	$(MAKE) -C bootstrap/druntime -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) INSTALL_DIR=$(INSTALL_DIR) install

build_phobos: clone_bootstrap
	$(MAKE) -C bootstrap/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) -j$(NCPU)
	$(MAKE) -C bootstrap/phobos -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET=$(QUIET) INSTALL_DIR=$(INSTALL_DIR) install

build_bootstrap: build_dmd build_druntime build_phobos

bootstrap_dmd.tar.bz2: build_bootstrap
	tar cfj bootstrap_dmd.tar.bz2 bootstrap/install
	cd bootstrap; rm -rf dmd druntime phobos

bootstrap_restore: bootstrap_dmd.tar.bz2
	tar xfj bootstrap_dmd.tar.bz2
	touch $@

bootstrap: bootstrap_dmd.tar.bz2
	[ -d bootstrap/install ] || $(MAKE) -f $(MAKEFILE) bootstrap_restore;

	