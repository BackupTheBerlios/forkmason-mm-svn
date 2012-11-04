from distutils.core import setup
from DistUtilsExtra.command import *
import glob

setup(
    name = 'gnewsense-theme',
    version = '0.01',
    data_files=[('share/themes/gNewSense-Murrine/gtk-2.0',
                 glob.glob('gNewSense-Murrine/gtk-2.0/*')),
                ('share/themes/gNewSense', 
                 ['cursor.theme',]),
                ('share/pixmaps/',
                 glob.glob('gnewsense-screensaver.svg')),
               ],
    cmdclass = { "build" : build_extra.build_extra,
                 "build_i18n" :  build_i18n.build_i18n }
)

