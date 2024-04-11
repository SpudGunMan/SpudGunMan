#!/bin/bash
# rigcontrol script K7MHI
SERVICE="rigctld"
HAMLIB="rigctld -m 3085 -r /dev/ttyACM0 -s 19200"

if pgrep -x "flrig" > /dev/null
then
    echo "flrig is running, override"
    HAMLIB="rigctld -m 4"
fi


if pgrep -x "$SERVICE" >/dev/null
then
    echo "$SERVICE is running"
    exit 0
else
    echo "$SERVICE booting up, ctl-c to terminate program"
    cat <<'EOF'
    
     .              +   .                .   . .     .  .
                   .                    .       .     *
  .       *                        . . . .  .   .  + .
            "You Are Here"            .   .  +  . . .
.                 |             .  .   .    .    . .
                  |           .     .     . +.    +  .
                 \|/            .       .   . .
        . .       V          .    * . . .  .  +   .
           +      .           .   .      +
                            .       . +  .+. .
  .                      .     . + .  . .     .      .
           .      .    .     . .   . . .        ! /
      *             .    . .  +    .  .       - O -
          .     .    .  +   . .  *  .       . / |
               . + .  .  .  .. +  .
.      .  .  .  *   .  *  . +..  .            *
 .      .   . .   .   .   . .  +   .    .            +
EOF
    $HAMLIB
    echo "73.."
    exit 0 
fi

exit 0


