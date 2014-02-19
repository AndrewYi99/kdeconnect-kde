/**
 * Copyright 2014 Samoilenko Yuri <kinnalru@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 1.1
import org.kde.plasma.core 0.1 as PlasmaCore
import org.kde.plasma.components 0.1 as PlasmaComponents
import org.kde.kdeconnect 1.0

QtObject {
  
    id: root
    
    property string deviceId: ""
    property variant device: DeviceDbusInterfaceFactory.create(deviceId)
    property bool available: false

    property bool charging: false
    property int charge: -1
    property string displayString: (available && charge > -1) ? ((charging) ? (i18n("Charging, %1").arg(charge)) : (i18n("Discharging, %1").arg(charge))) : i18n("No info")
    property variant battery: null

    property variant nested1: DBusAsyncResponse {
        id: startupCheck1
        autoDelete: false
        onSuccess: root.charging = result
    }
    
    property variant nested2: DBusAsyncResponse {
        id: startupCheck2
        autoDelete: false
        onSuccess: root.charge = result
    }
    
    /* Note: magically called by qml */
    onAvailableChanged: {
        if (available) {
            battery = DeviceBatteryDbusInterfaceFactory.create(deviceId)
            
            battery.stateChanged.connect(function(charging) {root.charging = charging})
            battery.chargeChanged.connect(function(charge) {root.charge = charge})
            
            startupCheck1.setPendingCall(battery.isCharging())
            startupCheck2.setPendingCall(battery.charge())
        }
        else {
            battery = null
        }
    }
    
    function pluginsChanged() {
        var result = DBusResponseWaiter.waitForReply(device.hasPlugin("kdeconnect_battery"))
      
        if (result && result != "error") {
            available = true
        }
        else {
            available = false
        }      
    }
    
    Component.onCompleted: {
        device.pluginsChanged.connect(pluginsChanged)
        device.pluginsChanged()
    }
}