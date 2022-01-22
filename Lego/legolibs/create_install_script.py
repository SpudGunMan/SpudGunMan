#!python3

# Run this on a Mac or Linux machine to create/update 'install_legolibs.py'
# Copy the contents of install_legolibs.py into an empty SPIKE/51515 project
# on the offical lego app And run to install. The transfer and program run 
# will take extra time. 
# 
# To restore to OEM, allow LEGO app to update your hub, library's will be removed.
#
# 
# installer idea from antonsmindstorms.com
#
# The following librarys will be checked and used if they are
# git cloned into the same folder as this project.
# by default if they exist they will be loaded
# to add your own just create a new item ih the compile_list
#
# https://github.com/antonvh/mpy-robot-tools 
# https://github.com/antonvh/UartRemote
# https://github.com/antonvh/LEGO-HuskyLenslib/blob/master/Library/pyhuskylens.py
#
# Open the console/Debug and watch for notice to unplug USB BEFORE you upload/run

import binascii, mpy_cross, time
import hashlib
import os
from functools import partial

ANTONVH_MPY_TOOLS_DIR = '../mpy-robot-tools/mpy_robot_tools/'
ANTONVH_LIB_UART = '../LMS-uart-esp/Libraries/UartRemote/MicroPython/uartremote.py'
ANTONVH_LIB_HUSKY = '../LEGO-HuskyLenslib/Library/pyhuskylens.py'
COMPILED_MPY_DIR = 'build/'
INSTALLER = 'install_legolibs.py'
BASE_SCRIPT = 'base_script.py'
BAD_NAMES = ['__pycache__.py','REDME.md']
COMPILE_LIST = [ANTONVH_MPY_TOOLS_DIR, ANTONVH_LIB_UART, ANTONVH_LIB_HUSKY]
 
mpy_installer_files_encoded = []
exception = ''
is_dir = False
error=False
working_list=[]

def mpy_tools_compile(py_file_in, build_dir):
    global mpy_installer_files_encoded
    #in_dir = os.path.dirname(py_file_in)
    in_file = os.path.basename(py_file_in)

    if in_file in BAD_NAMES:
        #skip file
        return None

    out_file = in_file.split(".")[0]+".mpy"
    out_file_loc = build_dir+out_file
    mpy_cross.run('-march=armv6', py_file_in,'-o', out_file_loc)
    time.sleep(0.5)
    with open(out_file_loc,'rb') as mpy_file:
        file_hash = hashlib.sha256(mpy_file.read()).hexdigest()
    chunks = []
    with open(out_file_loc,'rb') as mpy_file:
        for chunk in iter(partial(mpy_file.read, 2**10), b''):
            chunks += [binascii.b2a_base64(chunk).decode('utf-8')]

    print(out_file,": ",len(chunks)," chunks of ",2**10)

    # string for final installer
    mpy_installer_files_encoded += [(
        out_file,
        tuple(chunks), 
        file_hash
    )]

    return mpy_installer_files_encoded

# main


for library in COMPILE_LIST:
    #clean up the list with good stuff only
    try:
        lib_filename = os.path.basename(library)
    except:
        exception += (' library not found :',library)
        COMPILE_LIST = COMPILE_LIST.remove(library)

if not COMPILE_LIST:
    error=True
    exception += 'nothing to build go download some things from github!'

isExistBuild = os.path.exists('build/')
if not isExistBuild:
  # Create a new directory because it does not exist 
  os.makedirs('build/')

for library in COMPILE_LIST:

        isDirectory = os.path.isdir(library)
    
        if isDirectory:
            lib_dir = os.path.dirname(library) + '/'
            #compile script a directory of .py files, the BADWORDS is used in this
            print('diretory scan for', library, lib_dir)
            try:
                files = [f for f in os.listdir(lib_dir)]
                for f in files:
                    mpy_tools_compile(lib_dir+f, COMPILED_MPY_DIR)
            except Exception as e:
                error=True
                exception += (' error ' + library + ',' )
                print(e)
            

        if not isDirectory:# compile a file
            try:
                if os.path.exists(library):
                    lib_filename = os.path.basename(library)
                    lib_dir = os.path.dirname(library) + '/'
                    print('found ',library)
                    mpy_tools_compile(lib_dir+lib_filename, COMPILED_MPY_DIR)
            except Exception as e:
                error=True
                exception += (' error ' + library + ',' )
                print(e)


if not error:
    print('Library compiled succesfully')
else:
    print('Error:', exception)

# open base installer
spike_code=open(BASE_SCRIPT,'r').read()

# inject the encoded files as base64 for install in lego app
with open(INSTALLER,'w') as f:
    f.write(spike_code.format(repr(tuple(mpy_installer_files_encoded))))
