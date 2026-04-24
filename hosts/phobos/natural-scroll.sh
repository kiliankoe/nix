#!/bin/sh
# Enable natural scrolling on all QEMU pointer devices via KWin DBus
for dev in $(qdbus org.kde.KWin /org/kde/KWin/InputDevice org.kde.KWin.InputDeviceManager.ListPointers); do
  qdbus org.kde.KWin "/org/kde/KWin/InputDevice/$dev" org.freedesktop.DBus.Properties.Set \
    org.kde.KWin.InputDevice naturalScroll true 2>/dev/null
done
