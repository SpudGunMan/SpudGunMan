# smart-city-train.py pybricks for lego 'powered up' train systems
#-----------------------------------------------------------------------------
# Title:        Smart City Train
# Purpose:      pybricks train code.
#               includes dedicated remote for multiple trains
#               power down features when unattended
#               enhances the default remote functionality
#               optional distance sensor for automation
#
# Author:    -=SpudGunMan=- 
# Version:  Beta1
# Copyright: (C) 2022 Kelly Keeton
# sensor concept from https://pybricks.com/projects/sets/city/60198-cargo-train/speed-control/
# Usage:
#       This software may be used for any non-commercial purpose providing
#       that the original author is acknowledged.
#-----------------------------------------------------------------------------
from pybricks.hubs import CityHub
from pybricks.pupdevices import DCMotor, Remote, InfraredSensor, ColorDistanceSensor, Light
from pybricks.parameters import Port, Button, Color
from pybricks.tools import wait, StopWatch

# Remote Button Functions 0 default, 1 light control, 2 ATO Enable
#   right +/-
rp_function = 2
rm_function = 0
#   left +/-
lp_function = 0
lm_function = 0

# Some configurations might require to reverse the motor on remote
reversed_left = False
reversed_right = False

# Desired drive speed in mm per second.
ato_speed = 100

# These are the sensor reflection values in this setup.
# Adapt them to match your light conditions.
ato_light = 80
ato_dark = 39
# set debug, watch console and move train engine by hand on track
debug_ir = False

#if LED lights how bright 0-100
led_brightness = 20

# Initalize  idle shutdown timer, 4min 240000ms default
sleep_timeout = 240000
watchdog = StopWatch()
watchdog.reset()

# Initial position state. 
# mm_per_count It's two studs (16 mm) for each position increase.
on_track = True
no_remote = True
enable_ato = False
lego_remote = None
led_on = False
no_led = True
position = 0
speed = 0
rc_watchdog = 0
mm_per_count = 16

# Initialize the hub.
hub = CityHub()

# Initialize the motor
try:
    train_motor = DCMotor(Port.A)
except OSError:
    print("Critical: NO Motor PORT A")
    wait(1000)
    hub.system.shutdown()

# Initalize the optional sensor wedo2 or new Color Distance Sensor

try:
    sensor = ColorDistanceSensor(Port.B)
    no_sensor = False
    print("Detected: color sensor")
except OSError:
    no_sensor = True

if no_sensor:
    try:
        sensor = InfraredSensor(Port.B)
        no_sensor = False
        print("Detected: distance IR")
    except OSError:
        sensor = None
        reflection = 0

# Initialize the LED if equiped and set brightness
try:
    light = Light(Port.B)
    print("Detected: Lego light")
    no_led = False
except OSError:
    light = None

# Initalize the Lego Powered up Remote
def connect_remote():
    global no_remote, lego_remote, rc_watchdog
    hub.light.animate([Color.RED, Color.GREEN, Color.BLUE], interval=500)

    if rc_watchdog >= 5:
        halt_system('no remote found, check source # on missing or lost remote')
    else:
        rc_watchdog += 1
    
    try:
        # Connect to any remote. (use this for missing or lost remotes)
        # lego_remote = Remote(timeout=5000)

        # Connect to lego default name 'Handset'
        lego_remote = Remote("Handset", timeout=7000)

            # lego_remote = Remote('CargoTrain', timeout=7000)
            #   To set a remote name
            # lego_remote.name('CargoTrain')

        print("Connected device name:", lego_remote.name())
        hub.light.animate([Color.GREEN, Color.NONE], interval=1000)
        lego_remote.light.on(Color.GREEN)
        no_remote = False
        return no_remote

    except OSError:
        no_remote = True
        return no_remote

#engine power routines
def light_control():
    global led_on
    if not led_on and not no_led:
        light.on(led_brightness)
        led_on = True
    elif led_on:
        light.off()
        led_on = False
    return led_on

def fullstop():
    global speed, enable_ato
    speed = 0
    enable_ato = False
    watchdog.reset()
    train_motor.stop()

def power_increase():
    global speed
    watchdog.reset()
    if speed < 0:
        speed = speed + 10
    else:
        speed = min(max(speed + 10, 0), 100)
    return speed

def power_decrease():
    global speed
    watchdog.reset()
    if speed > 0:
        speed = speed - 10
    else:
        speed = min(max(speed - 10, -100), 0)
    return speed

def ato():
    global enable_ato
    enable_ato = True
    print ("ATO Active")
    #enhancment for detecting colors and acting on them

def ato_power():
    global ato_light, ato_dark, speed, position, on_track, debug_ir, reflection

    # Threshold values for  We add a bit of hysteresis to make
    # sure we skip extra changes on the edge of each track.
    hysteresis = (ato_light - ato_dark) / 4
    threshold_up = (ato_light + ato_dark) / 2 + hysteresis
    threshold_down = (ato_light + ato_dark) / 2 - hysteresis

    # If the reflection exceeds the threshold, increment position.
    if (reflection > threshold_up and on_track) or (reflection < threshold_down and not on_track):
        on_track = not on_track
        position += 1
        
    # Compute the target position based on the time.
    target_count = watchdog.time() / 1000 * ato_speed / mm_per_count

    # The duty cycle is the position error times a constant gain.
    speed = 2*(target_count - position)

        # ir Debug mode to set reflection settings by hand movement
    if debug_ir:
        print("reflec/upper/lower/speed:", reflection, threshold_up, threshold_down)
        print("speed/target/position:", speed, target_count, position)
    return speed

# Remote control
def get_rc():
    global speed, enable_ato, led_on
    
    if no_remote:
        fullstop()
        print('Attempting to locate remote...')
        connect_remote()
    else:
        # Check which buttons are pressed.
        pressed = lego_remote.buttons.pressed()
    
        # Check stop button.
        if Button.RIGHT in pressed:
            enable_ato = False
            fullstop()

        if Button.LEFT in pressed:
            enable_ato = False
            fullstop()

        # Shutdown
        if Button.CENTER in pressed:
            enable_ato = False
            hub.light.blink(Color.RED, [500, 500])
            halt_system("remote request")

        # Speed Up
        if Button.LEFT_PLUS in pressed:

            if lp_function == 0:
                #default behavior
                enable_ato = False
                if reversed_left:
                    speed = power_decrease()
                else:
                    speed = power_increase()

            elif lp_function == 1:
                #light function
               light_control()
                    
            elif lp_function == 2:
                #ATO
                ato()

            elif lp_function == 3:
                #track switching functions
                print("nothing to do")


        if Button.RIGHT_PLUS in pressed:

            if rp_function == 0:
                #default behavior
                enable_ato = False
                if reversed_left:
                    speed = power_decrease()
                else:
                    speed = power_increase()

            elif rp_function == 1:
                #light function
                light_control()
                    
            elif rp_function == 2:
                #ATO
                ato()

            elif rp_function == 3:
                #track switching functions
                print("nothing to do")

        # Slow Down
        if Button.LEFT_MINUS in pressed:

            if lm_function == 0:
                #default behavior
                enable_ato = False
                if reversed_left:
                    speed = power_decrease()
                else:
                    speed = power_increase()

            elif lm_function == 1:
                #light function
                light_control()
                    
            elif lm_function == 2:
                #ATO
                ato()

            elif lm_function == 3:
                #track switching functions
                print("nothing to do")

        if Button.RIGHT_MINUS in pressed:

            if rm_function == 0:
                #default behavior
                enable_ato = False
                if reversed_left:
                    speed = power_decrease()
                else:
                    speed = power_increase()

            elif rm_function == 1:
                #light function
                light_control()
                    
            elif rm_function == 2:
                #ATO
                ato()

            elif rm_function == 3:
                #track switching functions
                print("nothing to do")

        return speed

#system halt
def halt_system(msg):
    fullstop()
    if not no_led:
        light.off()
    print("Halt Requested",msg)
    wait(2000)
    hub.system.shutdown()

# Start of Program
print("SmartCity Train, All Aboard!")

# Light it up if equiped
light_control()

#main loop
while True:

    #rc button check
    get_rc()

    # IR as a tip sensor
    if not no_sensor:
        reflection = sensor.reflection()
        if reflection == 0:
            fullstop()

    # unattended poweroff
    if watchdog.time() >= sleep_timeout:
        hub.light.blink(Color.RED, [500, 500])
        halt_system("unattended")


    # Motor Movement
    if enable_ato:

        if debug_ir:
            ato_power()
        else:
            train_motor.dc(ato_power())

    else:
        train_motor.dc(speed)

    wait(100)
# eof