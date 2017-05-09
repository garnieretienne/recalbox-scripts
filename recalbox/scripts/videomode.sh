#!/bin/bash

HDMI_GLOBAL_VIDEO_MODE="CEA 4 HDMI"
HDMI_N64_VIDEO_MODE="CEA 1 HDMI"
OVERSCAN_CONFIGS_PATH="/recalbox/share/system/configs"

video_mode="unknown"

get_video_mode() {
  tvservice --status | grep HDMI > /dev/null
  if [ $? -eq 0 ]; then
    video_mode="HDMI"
  else
    video_mode="CRT"
  fi
  echo Video mode is $video_mode
}

unlock_boot_partition() {
  echo "Unlock the boot partition"
  mount -o remount, rw /boot
}

lock_boot_partition() {
  echo "Lock the boot partition"
  mount -o remount, ro /boot
}

request_restart() {
  msg=$1
  echo msg >> /tmp/restart_request
}

restart_if_requested() {
  if [ -a /tmp/restart_request ]; then
    shutdown -r now `cat /tmp/restart_request`
  fi
}

kill_emulation_station_if_started() {
  echo "Kill emulation station if started"
  killall emulationstation
}

start_emulation_station() {
  /etc/init.d/S31emulationstation start
}

disable_overscan() {
  cat /boot/config.txt | grep "disable_overscan\s*=\s*0" > /dev/null
  disable_overscan_flag=$?
  if [ $disable_overscan_flag -eq 0 ]; then
    unlock_boot_partition
    echo "Disable overscan"
    sed -i "/^disable_overscan=/s/=.*/=1/" /boot/config.txt
    request_restart "Disabling overscan request a restart"
    lock_boot_partition
  else
    echo "Overscan already disabled"
  fi
}

enable_overscan() {
  cat /boot/config.txt | grep "disable_overscan\s*=\s*0" > /dev/null
  disable_overscan_flag=$?
  if [ $disable_overscan_flag -eq 1 ]; then
    unlock_boot_partition
    echo "Enable overscan"
    sed -i "/^disable_overscan=/s/=.*/=0/" /boot/config.txt
    request_restart "Enabling overscan request a restart"
    lock_boot_partition
  else
    echo "Overscan already enabled"
  fi
}

configure_overscan_values() {
  overscan_top=$1
  overscan_bottom=$2
  overscan_left=$3
  overscan_right=$4

  unlock_boot_partition

  cat /boot/config.txt | grep "overscan_top\s*=\s*$overscan_top" > /dev/null
  if [ $? -eq 1 ]; then
    sed -i "/^overscan_top=/s/=.*/=${overscan_top}/" /boot/config.txt
    request_restart "Overscan top value updated"
  fi

  cat /boot/config.txt | \
      grep "overscan_bottom\s*=\s*$overscan_bottom" > /dev/null
  if [ $? -eq 1 ]; then
    sed -i "/^overscan_bottom=/s/=.*/=${overscan_bottom}/" /boot/config.txt
    request_restart "Overscan bottom value updated"
  fi

  cat /boot/config.txt | grep "overscan_left\s*=\s*$overscan_left" > /dev/null
  if [ $? -eq 1 ]; then
    sed -i "/^overscan_left=/s/=.*/=${overscan_left}/" /boot/config.txt
    request_restart "Overscan left value updated"
  fi

  cat /boot/config.txt | grep "overscan_right\s*=\s*$overscan_right" > /dev/null
  if [ $? -eq 1 ]; then
    sed -i "/^overscan_right=/s/=.*/=${overscan_right}/" /boot/config.txt
    request_restart "Overscan right value updated"
  fi

  lock_boot_partition
}

configure_overscan() {
  config_file=""

  case $video_mode in
    "HDMI")
      config_file="${OVERSCAN_CONFIGS_PATH}/overscan-HDMI.cfg"
      tvservice --dumpedid /tmp/edid.dat &> /dev/null
      md5=`md5sum /tmp/edid.dat | cut -d " " -f 1`
      e_config_file="${OVERSCAN_CONFIGS_PATH}/overscan-${md5}.cfg"
      if [ -f $e_config_file ]; then
        config_file=$e_config_file
      fi
    ;;
    "CRT")
      config_file="${OVERSCAN_CONFIGS_PATH}/overscan-CRT.cfg"
    ;;
  esac

  if [ -f $config_file ]; then
    echo "Configuring overscan (${config_file}: `cat ${config_file}`)"
    configure_overscan_values `cat ${config_file}`
    enable_overscan
  else
    disable_overscan
  fi
}

set_recalbox_video_mode_to_hdmi() {
  echo "Set recalbox video mode to HDMI (${HDMI_GLOBAL_VIDEO_MODE})"
  sed -i "/^global.videomode=/s/=.*/=${HDMI_GLOBAL_VIDEO_MODE}/" \
      /recalbox/share/system/recalbox.conf
  sed -i "/^n64.videomode=/s/=.*/=${HDMI_N64_VIDEO_MODE}/" \
      /recalbox/share/system/recalbox.conf
}

set_recalbox_video_mode_to_crt() {
  echo "Set recalbox video mode to CRT"
  sed -i "/^global.videomode=/s/=.*/=default/" \
      /recalbox/share/system/recalbox.conf
  sed -i "/^n64.videomode=/s/=.*/=default/" \
      /recalbox/share/system/recalbox.conf
}

disable_game_smoothing() {
  echo "Disable game smoothing"
  sed -i "/^global.smooth=/s/=.*/=0/" /recalbox/share/system/recalbox.conf
}

enable_game_smoothing() {
  echo "Enable game smoothing"
  sed -i "/^global.smooth=/s/=.*/=1/" /recalbox/share/system/recalbox.conf
}

disable_retro_shader() {
  echo "Disable retro shaders"
  sed -i "/^global.shaderset=/s/=.*/=none/" /recalbox/share/system/recalbox.conf
}

enable_retro_shader() {
  echo "Enable retro shaders"
  sed -i "/^global.shaderset=/s/=.*/=retro/" \
      /recalbox/share/system/recalbox.conf
}

get_video_mode
case $video_mode in
  "HDMI")
    configure_overscan
    set_recalbox_video_mode_to_hdmi
    enable_game_smoothing
    enable_retro_shader
  ;;
  "CRT")
    configure_overscan
    set_recalbox_video_mode_to_crt
    disable_game_smoothing
    disable_retro_shader
  ;;
esac
restart_if_requested
