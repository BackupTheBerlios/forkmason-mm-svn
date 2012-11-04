#!/bin/bash

###############################################################################
#		(C) 2009-2011 hyperclock (aka Jimmy M. Coleman)
#        website	:		www.cybernux.org
#        email		:		hyperclock(at)cybernux(dot)org
#        svn		:		http://xp-dev.com/svn/ForkForge/
#        dev		:		http://dev.cybernux.org
#
###############################################################################
###############################################################################
#    ForkMason - Scripts designed to build Cybernux Linux® based on Debian.
#
#    ForkMason is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    ForkMason is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy (see docs/gpl-3.0.txt) of the GNU General
#    Public License along with ForkMason.  If not, see
#    <http://www.gnu.org/licenses/>.
#
################################################################################
################################ INFO ##########################################
#
#       Derived from the scripts used by the gNewSense Project.
#       See the original scripts at http://gnewsense.org
#
#       Original (C) 2006 - 2009  Brian Brazil
#
#################################################################################

# Remove hard coding 'later'

# Manually uncomment this line after looking at what the script does.
exit 1

# Remove the package database(s)
rm /srv/gnewsense/db/references.db
rm /srv/gnewsense/db/packages.db

# Remove the dists files
rm -r /srv/gnewsense/dists

for component in main universe; do
        find /srv/gnewsense/pool/$component -name *.deb -exec reprepro -Vb /srv/gnewsense --component $component includedeb deltah {} \;
        find /srv/gnewsense/pool/$component -name *.udeb -exec reprepro -Vb /srv/gnewsense --component $component includeudeb deltah {} \;
        find /srv/gnewsense/pool/$component -name *.dsc -exec reprepro -Vb /srv/gnewsense --component $component includedsc deltah {} \;
done

