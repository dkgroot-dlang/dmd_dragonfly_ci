BASEDIR=$(shell pwd)
NCPU:=4
OS:=dragonflybsd
MODEL:=64
MAKE:=gmake
#MAKE:=make
GITUSER:=dkgroot
QUIET:=
BOOTSTRAP_DMD:=$(BASEDIR)/bootstrap/install/dragonflybsd/bin64/dmd
BUILD:=debug
MAKEFILE:=dmd.mk
#MAKEFILE:=scripts/dmd.mk

bootstrap_dir: 
	mkdir bootstrap
	touch $@

bootstrap_dmd_git: bootstrap_dir
	cd bootstrap; git clone -b dragonflybsd_v2.067.1 https://github.com/${GITUSER}/dmd.git
	touch $@

bootstrap_dmd: bootstrap_dmd_git bootstrap_druntime_git
	cd bootstrap/dmd; $(MAKE) -f posix.mak DEBUG=1 BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" HOST_CSS=g++ -j$(NCPU)
	cd bootstrap/dmd; $(MAKE) -f posix.mak DEBUG=1 BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" HOST_CSS=g++ install
	touch $@

bootstrap_druntime_git: bootstrap_dir
	cd bootstrap; git clone -b dmd-cxx https://github.com/${GITUSER}/druntime.git
	touch $@

bootstrap_druntime: bootstrap_dmd bootstrap_druntime_git
	cd bootstrap/druntime; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)"
	cd bootstrap/druntime; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" install
	touch $@

bootstrap_phobos_git: bootstrap_dir
	cd bootstrap; git clone -b dmd-cxx https://github.com/${GITUSER}/phobos.git
	touch $@

bootstrap_phobos: bootstrap_dmd bootstrap_druntime bootstrap_phobos_git
	cd bootstrap/phobos; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)"
	cd bootstrap/phobos; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" install
	touch $@

bootstrap_dmd.tar.bz2: bootstrap_dmd bootstrap_druntime bootstrap_phobos
	tar cfj bootstrap_dmd.tar.bz2 bootstrap/install
	cd bootstrap; rm -rf dmd druntime phobos

bootstrap_restore: bootstrap_dmd.tar.bz2
	tar xfj bootstrap_dmd.tar.bz2
	touch $@

bootstrap: bootstrap_dmd.tar.bz2
	$(MAKE) -f $(MAKEFILE) bootstrap_restore;

master_dir:
	mkdir master
	touch $@

master_dmd_git: master_dir
	cd master; git clone -b dragonflybsd-master https://github.com/dkgroot/dmd.git
	touch $@

master_dmd: master_dmd_git master_druntime_git master_phobos_git
	cd master/dmd; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) -j$(NCPU)
	cd master/dmd; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) install
	touch $@

master_dmd_test: master_dmd
	cd master/dmd; $(MAKE) -f posix.mak BUILD=release MODEL=$(MODEL) QUIET="$(QUIET)" HOST_CSS=g++ HOST_DMD=$(BOOTSTRAP_DMD) test

master_druntime_git: master_dir
	cd master; 							\
	git clone https://github.com/${GITUSER}/druntime.git;		\
	cd druntime;							\
	git checkout -b unittest;					\
	git pull origin dragonflybsd-master dragonfly-core.sys.posix dragonfly-core.sys.dragonflybsd --commit -q --squash;
	touch $@

master_druntime: master_dmd master_druntime_git
	cd master/druntime; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)"
	cd master/druntime; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" install
	touch $@

master_druntime_test: master_druntime
	cd master/druntime; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" unittest

master_phobos_git: master_dir
	cd master; git clone -b dragonflybsd-master https://github.com/${GITUSER}/phobos.git
	touch $@

master_phobos: master_druntime master_phobos_git
	cd master/phobos; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)"
	cd master/phobos; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" install
	touch $@

master_phobos_test: master_phobos
	cd master/phobos; $(MAKE) -f posix.mak BUILD=$(BUILD) MODEL=$(MODEL) QUIET="$(QUIET)" unittest

master_dmd.tar.bz2: build_master
	tar cfj master_dmd.tar.bz2 master/install

master_restore: master_dmd.tar.bz2
	tar xfj master_dmd.tar.bz2
	touch $@

build_master: master_dmd master_druntime master_phobos
	touch $@

run_master_test: build_master master_druntime_test master_phobos_test 
	#master_dmd_test

master: build_master run_master_test master_dmd.tar.bz2
