from distutils.core import setup
from DistUtilsExtra.command import *
import glob
import os
import re

# look/set what version we have
changelog = "debian/changelog"
if os.path.exists(changelog):
    head=open(changelog).readline()
    match = re.compile(".*\((.*)\).*").match(head)
    if match:
        version = match.group(1)

setup(
    name = 'gnewsense-gdm-themes',
    version = version,
    data_files=[('share/gdm/themes/deltah', 
                 glob.glob('deltah/*.png')+glob.glob('deltah/*.svg')+\
		 glob.glob('deltah/*.xml')),
               ],
    cmdclass = { "build" : build_extra.build_extra,
                 "build_i18n" :  build_i18n.build_i18n }
)

