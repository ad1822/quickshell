import QtQuick
import Quickshell.Services.UPower

Rectangle {
    id: battRoot

    readonly property double percentage: UPower.displayDevice.percentage
    readonly property bool isLaptopBattery: UPower.displayDevice.isLaptopBattery
    readonly property bool isCharging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)

    signal clicked()
    signal hovered(bool isHovered)

    function getBatteryIcon(percentage, isCharging) {
        var pct = Math.round(percentage * 100);
        if (isCharging) {
            if (pct >= 95)
                return "battery_charging_full";
            else if (pct >= 90)
                return "battery_charging_90";
            else if (pct >= 80)
                return "battery_charging_80";
            else if (pct >= 60)
                return "battery_charging_60";
            else if (pct >= 50)
                return "battery_charging_50";
            else if (pct >= 30)
                return "battery_charging_30";
            else
                return "battery_charging_20";
        } else {
            if (pct >= 95)
                return "battery_full";
            else if (pct >= 85)
                return "battery_6_bar";
            else if (pct >= 70)
                return "battery_5_bar";
            else if (pct >= 55)
                return "battery_4_bar";
            else if (pct >= 40)
                return "battery_3_bar";
            else if (pct >= 25)
                return "battery_2_bar";
            else if (pct >= 15)
                return "battery_1_bar";
            else
                return "battery_0_bar";
        }
    }

    implicitWidth: contentRow.implicitWidth + 18
    implicitHeight: 30
    radius: 0
    color: {
        if (!battRoot.isLaptopBattery)
            return "transparent";

        var pct = Math.round(battRoot.percentage * 100);
        if (pct <= 25)
            return Style.red;

        if (pct <= 50)
            return Style.sapphire;

        return Style.blue;
    }

    Row {
        id: contentRow

        anchors.centerIn: parent
        spacing: 6

        Text {
            id: iconText

            text: {
                if (!battRoot.isLaptopBattery)
                    return "battery_unknown";

                var pct = Math.round(battRoot.percentage * 100);
                var isAC = !UPower.onBattery;
                if (isAC && pct >= 80)
                    return "power";
                else
                    return battRoot.getBatteryIcon(battRoot.percentage, battRoot.isCharging);
            }
            color: !battRoot.isLaptopBattery ? Style.text : Style.crust
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Font.Bold
        }

        Text {
            id: labelText

            visible: battRoot.isLaptopBattery
            text: Math.round(battRoot.percentage * 100) + "%"
            color: Style.crust
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            font.weight: Font.Bold
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: battRoot.clicked()
        onEntered: battRoot.hovered(true)
        onExited: battRoot.hovered(false)
    }

}
