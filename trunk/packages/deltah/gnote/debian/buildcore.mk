# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2002,2003 Colin Walters <walters@debian.org>
# Description: Defines the rule framework
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_rules_buildcore
_cdbs_rules_buildcore = 1

include $(_cdbs_rules_path)/buildvars.mk$(_cdbs_makefile_suffix)

# Can we change this to cdbs_curpkg = $(notdir $@) ?
cdbs_curpkg = $(filter-out %/,$(subst /,/ ,$@))

testdir: debian/control
	test -x debian/rules

testroot:
ifdef _cdbs_rules_debhelper
	dh_testroot
else
	test "`id -u`" = 0
endif

$(patsubst %,makebuilddir/%,$(DEB_ALL_PACKAGES)) :: makebuilddir/% : 
	$(if $(DEB_BUILDDIR_$(cdbs_curpkg)),mkdir -p "$(DEB_BUILDDIR_$(cdbs_curpkg))")

makebuilddir:: $(patsubst %,makebuilddir/%,$(DEB_ALL_PACKAGES))
	mkdir -p "$(DEB_BUILDDIR)"

cdbs_streq = $(if $(filter-out xx,x$(subst $1,,$2)$(subst $2,,$1)x),,yes)

cleanbuilddir:: $(patsubst %,cleanbuilddir/%,$(DEB_ALL_PACKAGES))
	-$(if $(call cdbs_streq,$(DEB_BUILDDIR),$(DEB_SRCDIR)),,rmdir $(DEB_BUILDDIR))

$(patsubst %,cleanbuilddir/%,$(DEB_ALL_PACKAGES)) :: cleanbuilddir/% : 
	-$(if $(DEB_BUILDDIR_$(cdbs_curpkg)),$(if $(call cdbs_streq,$(DEB_BUILDDIR_$(cdbs_curpkg)),$(DEB_SRCDIR)),,rmdir "$(DEB_BUILDDIR_$(cdbs_curpkg))"))


# This variable is used by tarball.mk, but we want it here in order to check
# tarball contents before unpacking.  tarball.mk imports this file anyway.
DEB_TARBALL ?= $(wildcard *.tar *.tgz *.tar.gz *.tar.bz *.tar.bz2 *.zip)

ifneq (, $(findstring .bz2, $(DEB_TARBALL)))
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), bzip2
endif
ifneq (, $(findstring .zip, $(DEB_TARBALL)))
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), unzip
endif

# make is dumb
close_parenthesis = )

ifneq (, $(DEB_TARBALL))
$(warning parsing $(DEB_TARBALL) ...)
config_all_tar		:= $(shell \
for i in $(DEB_TARBALL) ; do \
	if ! test -e $$i.cdbs-config_list ; then \
		echo Parsing $$i... >&2 ; \
		case $$i in \
			*.tar$(close_parenthesis) tar -tf $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.tgz|*.tar.gz$(close_parenthesis) tar -tzf $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.tar.bz|*.tar.bz2$(close_parenthesis) tar -tjf $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*.zip$(close_parenthesis) unzip -l $$i | grep "/config\.[^/]*$$" > $$i.cdbs-config_list ;; \
			*$(close_parenthesis) echo Warning: tarball $$i with unknown format >&2 ;; \
		esac ; \
	fi ; \
	cat $$i.cdbs-config_list ; \
done)
endif

# Avoid recursive braindamage if we're building autotools-dev
ifeq (, $(shell grep -x 'Package: autotools-dev' debian/control))
config_guess		:= $(shell find $(DEB_SRCDIR) -type f -name config.guess)
config_sub		:= $(shell find $(DEB_SRCDIR) -type f -name config.sub)
ifneq (, $(config_all_tar))
config_guess_tar	:= $(filter %/config.guess, $(config_all_tar))
config_sub_tar		:= $(filter %/config.sub, $(config_all_tar))
endif
endif
# Ditto for gnulib
ifeq (, $(shell grep -x 'Package: gnulib' debian/control))
config_rpath		:= $(shell find $(DEB_SRCDIR) -type f -name config.rpath)
ifneq (, $(config_all_tar))
config_rpath_tar	:= $(filter %/config.rpath, $(config_all_tar))
endif
endif

ifneq (, $(config_guess)$(config_sub)$(config_guess_tar)$(config_sub_tar))
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), autotools-dev
endif
ifneq (, $(config_rpath)$(config_rpath_tar))
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), gnulib (>= 0.0.20041014-2)
endif

# This target is called before almost anything else happens.  It's a good place
# to do stuff like unpack extra source tarballs, apply patches, and stuff.  In
# the future it will be a good place to generate debian/control, but right
# now we don't support that very well.
pre-build:: testdir makebuilddir
	$(foreach x,$(_cdbs_deprecated_vars),$(if $(shell test "$($x)" != "$(_cdbs_deprecated_$(x)_default)" && echo W),$(warning WARNING:  $x is a deprecated variable)))

# This target is called after patches are applied.  Used by the patch system.
post-patches:: pre-build apply-patches update-config
update-config::
ifneq (, $(config_guess))
	if test -e /usr/share/misc/config.guess ; then \
		for i in $(config_guess) ; do \
			if ! test -e $$i.cdbs-orig ; then \
				mv $$i $$i.cdbs-orig ; \
				cp --remove-destination /usr/share/misc/config.guess $$i ; \
			fi ; \
		done ; \
	fi
endif
ifneq (, $(config_sub))
	if test -e /usr/share/misc/config.sub ; then \
		for i in $(config_sub) ; do \
			if ! test -e $$i.cdbs-orig ; then \
				mv $$i $$i.cdbs-orig ; \
				cp --remove-destination /usr/share/misc/config.sub $$i ; \
			fi ; \
		done ; \
	fi
endif
ifneq (, $(config_rpath))
	if test -e /usr/share/gnulib/config/config.rpath ; then \
		for i in $(config_rpath) ; do \
			if ! test -e $$i.cdbs-orig ; then \
				mv $$i $$i.cdbs-orig ; \
				cp --remove-destination /usr/share/gnulib/config/config.rpath $$i ; \
			fi ; \
		done ; \
	fi
endif

# This target should be used to configure the package before building.  Typically
# this involves running things like ./configure.
common-configure-arch:: post-patches
common-configure-indep:: post-patches
$(patsubst %,configure/%,$(DEB_ARCH_PACKAGES)) :: configure/% : common-configure-arch
$(patsubst %,configure/%,$(DEB_INDEP_PACKAGES)) :: configure/% : common-configure-indep

# This is a required Debian target; however, its specific semantics is
# in dispute.  We are of the opinion that 'build' should invoke
# build-arch and build-indep.  Policy tends to support us here.
# However, dpkg-buildpackage is currently invokes debian/rules build
# even when doing an architecture-specific (binary-arch) build.  This
# essentially means Build-Depends-Indep is worthless.  For more
# information, see Policy §5.2, Policy §7.6, and Debian Bug #178809.
# For now, you may override the dependencies by setting the variable
# DEB_BUILD_DEPENDENCIES, below.  This is not recommended.
DEB_BUILD_DEPENDENCIES = build-arch build-indep
build: $(DEB_BUILD_DEPENDENCIES)

# This target should take care of actually compiling the package from source.
# Most often this involves invoking "make".
common-build-arch:: testdir $(patsubst %,configure/%,$(DEB_ARCH_PACKAGES))
common-build-indep:: testdir $(patsubst %,configure/%,$(DEB_INDEP_PACKAGES))
$(patsubst %,build/%,$(DEB_ARCH_PACKAGES)) :: build/% : common-build-arch configure/%
$(patsubst %,build/%,$(DEB_INDEP_PACKAGES)) :: build/% : common-build-indep configure/%

# This rule is for stuff to run after the build process.  Note that this
# may run under fakeroot or sudo, so it's inappropriate for things that
# should be run under the build target.
common-post-build-arch:: common-build-arch $(patsubst %,build/%,$(DEB_ARCH_PACKAGES)) 
common-post-build-indep:: common-build-indep $(patsubst %,build/%,$(DEB_INDEP_PACKAGES)) 

# Required Debian targets.
build-arch: $(patsubst %,build/%,$(DEB_ARCH_PACKAGES))
build-indep: $(patsubst %,build/%,$(DEB_INDEP_PACKAGES))

# This rule is used to prepare the source package before a diff is generated.
# Typically you will invoke upstream's "make clean" rule here, although you
# can also hook in other stuff here.  Many of the included rules and classes
# add stuff to this rule.
clean:: testdir testroot cleanbuilddir reverse-config
reverse-config::
ifneq (::, $(config_guess):$(config_sub):$(config_rpath))
	for i in $(config_guess) $(config_sub) $(config_rpath) ; do \
		if test -e $$i.cdbs-orig ; then \
			mv $$i.cdbs-orig $$i ; \
		fi ; \
	done
endif

ifneq (, $(DEB_AUTO_UPDATE_DEBIAN_CONTROL))
control_cpu		:= $(shell grep "^Cpu:" debian/control.in | sed -e "s/^.*: //g" -e "s/ /,/g")
ifeq (, $(control_cpu))
ifneq (, $(shell egrep "\[(system|cpu): .*\]" debian/control.in))
$(error inconsistency in control.in: [(system|cpu): ] tags were used but Cpu:|System: was not)
endif
else
# Prevent recursive braindamage when building type-handling with cdbs.
ifeq (, $(shell grep -x 'Package: type-handling' debian/control))
CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), type-handling (>= 0.2.5)
endif
control_system		:= $(shell grep "^System:" debian/control.in | sed -e "s/^.*: //g" -e "s/ /,/g")
control_arch		:= $(shell type-handling $(control_cpu) $(control_system))
endif
endif
debian/control::
ifneq ($(DEB_AUTO_UPDATE_DEBIAN_CONTROL),)
	sed \
		-e "s/@cdbs@/$(CDBS_BUILD_DEPENDS)/g" \
		-e "s/^Build-Depends\(\|-Indep\): ,/Build-Depends\1:/g" \
		\
		-e "s/^Cpu: .*/Architecture: $(control_arch)/g" \
		-e "/^System: /d" \
		\
		-e "s/\[cpu: \([^]]*\)\]/\[\`type-handling \\\\\`echo \1 | tr ' ' ','\\\\\` any\`\]/g" \
		-e "s/\[system: \([^]]*\)\]/\[\`type-handling any \\\\\`echo \1 | tr ' ' ','\\\\\`\`\]/g" \
		\
		-e "s/\"/\\\\\"/g" \
		-e "s/^/echo \"/g" \
		-e "s/\\$$/\\\\$$/g" \
		-e "s/$$/\"/g" \
	< debian/control.in | $(SHELL) > debian/control
	-dpkg-checkbuilddeps -B
endif

# This rule is called before the common-install target.  It's currently only
# used by debhelper.mk, to run dh_clean -k.
common-install-prehook-arch::
common-install-prehook-indep::

# This target should do all the work of installing the package into the
# staging directory (debian/packagename or debian/tmp).
common-install-arch:: testdir common-install-prehook-arch common-post-build-arch
common-install-indep:: testdir common-install-prehook-indep common-post-build-indep

# Required Debian targets.
install-arch: $(patsubst %,install/%,$(DEB_ARCH_PACKAGES))
install-indep: $(patsubst %,install/%,$(DEB_INDEP_PACKAGES))

# These rules should do any installation work specific to a particular package.
$(patsubst %,install/%,$(DEB_ARCH_PACKAGES)) :: install/% : testdir testroot common-install-arch build/%
$(patsubst %,install/%,$(DEB_INDEP_PACKAGES)) :: install/% : testdir testroot common-install-indep build/%

# This rule is called after all packages are installed.
common-binary-arch:: testdir testroot $(patsubst %,install/%,$(DEB_ARCH_PACKAGES))
common-binary-indep:: testdir testroot $(patsubst %,install/%,$(DEB_INDEP_PACKAGES))

# Required Debian targets
binary-indep: $(patsubst %,binary/%,$(DEB_INDEP_PACKAGES))
binary-arch: $(patsubst %,binary/%,$(DEB_ARCH_PACKAGES))

# These rules should do all the work of actually creating a .deb from the staging
# directory.
$(patsubst %,binary/%,$(DEB_ARCH_PACKAGES)) :: binary/% : testdir testroot common-binary-arch install/% 
$(patsubst %,binary/%,$(DEB_INDEP_PACKAGES)) :: binary/% : testdir testroot common-binary-indep install/% 

# Required Debian target
binary: binary-indep binary-arch

##
# Deprecated targets.  You should use the -arch and -indep targets instead.
##
common-configure:: common-configure-arch common-configure-indep 
common-build:: common-build-arch common-build-indep
common-post-build:: common-post-build-arch common-post-build-indep
common-install-prehook:: common-install-prehook-arch common-install-prehook-indep
common-install:: common-install-arch common-install-indep
common-binary:: common-binary-arch common-binary-indep

.PHONY: pre-build apply-patches post-patches common-configure-arch common-configure-indep $(patsubst %,configure/%,$(DEB_ALL_PACKAGES)) build common-build-arch common-build-indep $(patsubst %,build/%,$(DEB_ALL_PACKAGES)) build-arch build-indep clean common-install-arch common-install-indep install-arch install-indep $(patsubst %,install/%,$(DEB_ALL_PACKAGES)) common-binary-arch common-binary-indep $(patsubst %,binary/%,$(DEB_ALL_PACKAGES)) binary-indep binary-arch binary $(DEB_PHONY_RULES)

# Parallel execution of the cdbs makefile fragments will fail, but
# this way you can call dpkg-buildpackage with MAKEFLAGS=-j in the
# environment and the package's own makefiles can use parallel make.
.NOTPARALLEL:

endif
