#!/bin/bash

level0=42 # 25% 
level1=50 # 50%
level2=60 # 75%
level3=70 # 100%

CHIP="pwmchip8"
THERMAL_ZONE=0
INTERVAL=30
actual=0

usage() {
    echo "Usage: $0 [-c <pwmchipX>] [-z <int>] [-i <int>]" 1>&2;
    exit 1;
}

while getopts ":c:z:i:" opt; do
    case "${opt}" in
        c)
            CHIP=${OPTARG}
            ;;
        z)
            THERMAL_ZONE=${OPTARG}
            ;;
        i)
            INTERVAL=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

set_level(){
    if [ "$actual" -ne $1 ]; then
	echo "Changing fan speed from $actual to $1"
        echo $1 > /sys/class/pwm/${CHIP}/pwm0/duty_cycle
        actual=$1
    fi
}

monitor_temp() {
    while true; do
        temp_raw=$(cat /sys/class/thermal/thermal_zone${THERMAL_ZONE}/temp)
        temp=$((temp_raw / 1000))
        echo "Current temperature: $temp °C"
        if [ "$temp" -ge "$level3" ]; then
            set_level 40000
        elif [ "$temp" -ge "$level2" ]; then
            set_level 30000
        elif [ "$temp" -ge "$level1" ]; then
            set_level 20000
        elif [ "$temp" -ge "$level0" ]; then
            set_level 10000
        else
            set_level 0
        fi
        sleep $INTERVAL
    done
}


start(){
    echo "Starting fan manager..."

    # check if pwm0 exists and create it if not
    if [ ! -d /sys/class/pwm/${CHIP}/pwm0 ]; then
        echo "pwm0 not found, trying to enable it..."
        echo 0 > /sys/class/pwm/${CHIP}/export
        sleep 0.2
    fi
    if [ ! -d /sys/class/pwm/${CHIP}/pwm0 ]; then
        echo "Failed to create pwm0 for ${CHIP}"
        exit 1
    fi
    if [ ! -f /sys/class/thermal/thermal_zone${THERMAL_ZONE}/temp ]; then
        echo "Thermal zone ${THERMAL_ZONE} not found"
        exit 2
    fi
    # set pwm0 period
    echo 40000 > /sys/class/pwm/${CHIP}/pwm0/period
    sleep 0.2
    # set pwm0 duty cycle to obtain 25% speed
    actual=1
    set_level 0
    # set pwm0 polarity
    echo normal >  /sys/class/pwm/${CHIP}/pwm0/polarity
    sleep 0.2
    # enable pwm0
    echo 1 > /sys/class/pwm/${CHIP}/pwm0/enable

    # start monitoring temperature
    monitor_temp
}

start
