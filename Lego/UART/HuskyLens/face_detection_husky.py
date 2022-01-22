from hub import button

# imports from Anton's Mindstorms LEGO Huskylens library
# https://github.com/antonvh/LEGO-HuskyLenslib
from projects.pyhuskylens import (HuskyLens, 
ALGORITHM_FACE_RECOGNITION, 
ALGORITHM_FACE_RECOGNITION,
ALGORITHM_OBJECT_TRACKING,
ALGORITHM_OBJECT_RECOGNITION,
ALGORITHM_LINE_TRACKING,
ALGORITHM_COLOR_RECOGNITION,
ALGORITHM_TAG_RECOGNITION,
ALGORITHM_OBJECT_CLASSIFICATION,
ALGORITHM_QR_CODE_RECOGNITION,
ALGORITHM_BARCODE_RECOGNITION, 
ARROWS, # key for get() dict
BLOCKS, # key for get() dict
FRAME, # key for get() dict
clamp_int)

hl = HuskyLens('A', debug=False)

# This returns '.': OK and no payload on firmware 0.5.1 may not work on newer
print(hl.get_version())

# Show some text on screen
hl.clear_text()
hl.show_text("hello from SPIKE", position=(120,120))

print("Starting face recognition")
hl.set_alg(ALGORITHM_FACE_RECOGNITION)

while not button.right.is_pressed():
    # Get x/y loc of a face
    blocks = hl.get_blocks()
    if len(blocks) > 0:
        face_x = blocks[0].x
        face_y = blocks[0].y
        error_x = (face_x-155)
        error_y = (face_y-120)
        print('face found:', face_x,face_y)