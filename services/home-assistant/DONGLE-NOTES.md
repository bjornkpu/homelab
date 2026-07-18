# USB dongle notes

Hardware plugged into the TrueNAS server for Home Assistant.

## Sonoff Zigbee 3.0 USB Dongle Plus V2 (Zigbee coordinator)

| Field | Value |
|---|---|
| Product | Sonoff Zigbee 3.0 USB Dongle Plus V2 (Itead) |
| USB ID | `10c4:ea60` (Silicon Labs CP210x UART Bridge) |
| Host driver | `cp210x` (present on TrueNAS kernel `6.12.15-production+truenas`, auto-binds) |
| Serial number | `2c20bc0193f3ef119f48c21b6d9880ab` |
| Kernel node | `/dev/ttyUSB0` (can shift on reboot/replug — do NOT use in config) |

**Stable path to use in ZHA / Zigbee2MQTT (never changes):**

```
/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_2c20bc0193f3ef119f48c21b6d9880ab-if00-port0
```

Verified: the dongle enumerates and `cp210x` binds cleanly on the NAS, so Zigbee can run on the container HA directly. Device still needs to be mapped into the `home-assistant` Docker Custom App (add to compose `devices:`), then enable ZHA or run Zigbee2MQTT pointed at the by-id path.

Zigbee devices to pair: Aqara T1 x2, Aqara Climate Sensor W100 (in Zigbee mode).

## Not usable: CSR Bluetooth dongle

`0a12:0001` CSR8510 A10 (Cambridge Silicon Radio), `bcdDevice=88.91` — counterfeit CSR clone.
The TrueNAS kernel has **no `btusb` module** (not on disk), so no Bluetooth adapter comes up on
the host. Cannot be used by the container HA. For Bluetooth (e.g. SwitchBot Meter Pro, BLE-only),
use an ESP32 Bluetooth proxy over the network instead.
