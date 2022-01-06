from pybricks.hubs import CityHub
from pybricks.pupdevices import Remote
from pybricks.pupdevices import DCMotor
from pybricks.parameters import Port
from pybricks.parameters import Button, Color
from pybricks.tools import wait, StopWatch

# SmartCityTrain Code -=SpudGunMan=-
ver = "1B"

# Initialize the hub.
hub = CityHub()

# Initialize the motor.
train_motor = DCMotor(Port.A)

# Initalize watchdog timer, 5min 300000ms default
sleep_timeout = 300000
watchdog = StopWatch()
watchdog.reset()

speed = 0

def fullstop():
    global speed 
    speed = 0
    watchdog.reset()
    train_motor.stop()

def speed_up():
    global speed
    watchdog.reset()
    if speed < 0:
        speed = speed + 10
    else:
        speed = min(max(speed + 10, 0), 100)
    return speed

def slow_down():
    global speed
    watchdog.reset()
    if speed > 0:
        speed = speed - 10
    else:
        speed = min(max(speed - 10, -100), 0)
    return speed

print("SmartCity Train ver:", ver)
hub.light.animate([Color.RED, Color.GREEN, Color.BLUE], interval=500)
wait(2000)

try:
    # Connect to any remote.
    # remote = Remote(timeout=5000)

    # Connect to a remote called Handset. (multiple sets rename it)
    # remote = Remote('CargoTrain', timeout=7000)
    remote = Remote('Handset', timeout=7000)

    print("Connected device:", remote.name())
    hub.light.animate([Color.GREEN, Color.NONE], interval=1000)
    remote.light.on(Color.GREEN)
    no_remote = False

    # ### to name a remote. Choose a new name.
    # my_remote.name('CargoTrain')

except OSError:
    print("Could not find the remote")
    hub.light.blink(Color.RED, [500, 500])
    no_remote = True

while True:

    if no_remote:
            wait(1000)
            print('Goodbye')
            hub.system.shutdown()
    else:
        # Check which buttons are pressed.
        pressed = remote.buttons.pressed()

        # Check stop button.
        if Button.RIGHT in pressed:
            fullstop()

        if Button.LEFT in pressed:
            fullstop()
        
        # Shutdown
        if Button.CENTER in pressed:
            print("Poweroff")
            hub.light.blink(Color.RED, [500, 500])
            wait(2000)
            hub.system.shutdown()

        # Speed Up
        if Button.LEFT_PLUS in pressed:
            speed = speed_up()

        if Button.RIGHT_PLUS in pressed:
            speed = speed_up()

        # Slow Down
        if Button.LEFT_MINUS in pressed:
            speed = slow_down()
        
        if Button.RIGHT_MINUS in pressed:
            speed = slow_down()
            
        # Motor Enable Movement with watchdog
        train_motor.dc(speed)
        wait(100)
            
        if watchdog.time() >= sleep_timeout:
            hub.light.blink(Color.RED, [500, 500])
            print("Watchdog timer shutdown")
            wait(2000)
            hub.system.shutdown()
        
        if watchdog.time() >= (sleep_timeout - 60000) :
            hub.light.blink(Color.BLUE, [500, 500])
            wait(2000)
#eof