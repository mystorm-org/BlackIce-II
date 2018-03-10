
# UART Loopback

This example receives data from USB2 at 115200 baud, decodes it, and loops it to USB2.

The design has the following:
* Pin P1 (= RTS on the CH340G) is connected to the global reset. As a result, the while design is kept in reset as long
  as the PC serial port is not active enable. To active the serial port, do ```sudo make run``` and the design will come to
  life!
* a simple UART RX block and a UART TX block that are directly connected to eachother.
* LED1 (red) toggles at ~1.5s frequency and LED2 is on when the UART TX block is transmitting.
* LED2 (orange) is connected to UART\_TX. When the FPGA transmits something, the LED will flicker.
* LED3 (green) is connected to button B1. When you press B1, it will light up.
* UART\_CTS is also connected to B1. In theory, when pressed, this should instruct the USB2 port to stop
  sending data to the board. However, that doesn't seem to work... Feel free to submit solutions here on github!

To test, do ```sudo make run``` in one terminal window. Then do ```echo "Hello World!" > /dev/ttyUSB0``` in another
terminal window. You should see "Hello World!" appear in the first terminal window.

