import QtQuick
import Quickshell.Services.UPower

Rectangle {
    id: battRoot

    readonly property double percentage: UPower.displayDevice.percentage
    readonly property bool isLaptopBattery: UPower.displayDevice.isLaptopBattery
    readonly property bool isCharging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)

    signal clicked()
    signal hovered(bool isHovered)
    property bool transparentBg: false

    function getBatteryIcon(percentage, isCharging) {
        var pct = Math.round(percentage * 100);
        if (isCharging) {
            if (pct >= 95)
                return "battery_android_bolt";
            else if (pct >= 90)
                return "battery_android_bolt";
            else if (pct >= 80)
                return "battery_android_bolt";
            else if (pct >= 60)
                return "battery_android_bolt";
            else if (pct >= 50)
                return "battery_android_bolt";
            else if (pct >= 30)
                return "battery_android_bolt";
            else
                return "battery_android_bolt";
        } else {
            if (pct >= 95)
                return "battery_android_full";
            else if (pct >= 85)
                return "battery_android_6";
            else if (pct >= 70)
                return "battery_android_5";
            else if (pct >= 55)
                return "battery_android_4";
            else if (pct >= 40)
                return "battery_android_3";
            else if (pct >= 25)
                return "battery_android_2";
            else if (pct >= 15)
                return "battery_android_1";
            else
                return "battery_android_0";
        }
    }

    implicitWidth: contentRow.implicitWidth + 18
    implicitHeight: 30
    radius: 0
    color: {
        if (battRoot.transparentBg || !battRoot.isLaptopBattery)
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
                    return "battery_android_question";

                var pct = Math.round(battRoot.percentage * 100);
                var isAC = !UPower.onBattery;
                if (isAC && pct >= 80)
                    return "power";
                else
                    return battRoot.getBatteryIcon(battRoot.percentage, battRoot.isCharging);
            }
            color: {
                if (battRoot.transparentBg) {
                    var pct = Math.round(battRoot.percentage * 100);
                    if (pct <= 25) return Style.red;
                    if (pct <= 50) return Style.peach;
                    if (battRoot.isCharging) return Style.green;
                    return Style.text;
                }
                return !battRoot.isLaptopBattery ? Style.text : Style.crust;
            }
            font.family: "Material Symbols Rounded"
            font.pixelSize: Style.fontSize
            font.weight: Font.Bold
        }

        Text {
            id: labelText

            visible: battRoot.isLaptopBattery
            text: Math.round(battRoot.percentage * 100) + "%"
            color: {
                if (battRoot.transparentBg) {
                    var pct = Math.round(battRoot.percentage * 100);
                    if (pct <= 25) return Style.red;
                    if (pct <= 50) return Style.peach;
                    if (battRoot.isCharging) return Style.green;
                    return Style.text;
                }
                return Style.crust;
            }
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
