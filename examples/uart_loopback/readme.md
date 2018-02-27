
# UART Loopback

This example receives data from USB2 at 115200 baud, decodes it, and loops it to USB2.

The design contains a simple UART RX block and a UART TX block that are directly connected to eachother.

In addition, LED1 toggles at ~1.5s frequency and LED2 is on when the UART TX block is transmitting.

To test, do ```sudo make run``` in one terminal window. Then do ```echo "Hello World!" > /dev/ttyUSB0``` in another
terminal window. You should see "Hello World!" appear in the first terminal window.

