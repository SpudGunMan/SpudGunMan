
import ubinascii, os, machine,uhashlib, time
from ubinascii import hexlify

mpy_files_encoded={}

def calc_hash(b):
    return hexlify(uhashlib.sha256(b).digest()).decode()

error=False
exception=''
install_path='/projects/legolibs/'

try:
    #directory to write on hub by default user content is in projects
    os.mkdir(install_path)
except Exception as e:
    error=True
    exception += (' directory create ,')
    print(e)

for file, code, hash_gen in mpy_files_encoded:
    target_loc = install_path+file

    # check for file and remove
    try: # remove any old versions of library
        os.remove(target_loc)
        print("Removing old file ", file)
    except Exception as e:
        exception += (' deleting' +file+ ',' )

    # hash_gen=code[1]
    try:
        print('writing '+file+' to Hub ' +install_path)
        with open(target_loc,'wb') as f:
            for chunk in code:
                f.write(ubinascii.a2b_base64(chunk))
        del code
    except Exception as e:
        error=True
        exception += ('writing:' +file+ ',')
        print(e)

    try:
        print('Finished writing '+file+', Checking hash.')
        result=open(target_loc,'rb').read()
        time.sleep(1)
        hash_check=calc_hash(result)

        if hash_check != hash_gen:
            error=True
            exception += ('hash check:' +file+ 'hash:' +hash_check+ ',')
        else:
            print('Good Hash: ',file, hash_gen)

    except Exception as e:
        error=True
        exception += ('hash check:' +file+ 'hash:' +hash_check+ ',')
        print(e)


if not error:
    print('Library written succesfully. UNPLUG USB now!')
    time.sleep(0.5)
    print("Resetting....")
    machine.reset()
else:
    print('Errors with library(s):', exception)