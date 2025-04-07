import serial           # Import the pyserial module for serial communication
import struct          # Import struct for packing and unpacking binary data
import time            # Import time module (not used in this script)

# Open serial communication on COM10
ComPort = serial.Serial('COM4')  
ComPort.baudrate = 115200  # Set baud rate to 115200
ComPort.bytesize = 8       # Set data bits to 8
ComPort.parity = 'N'       # Set parity to None
ComPort.stopbits = 1       # Set stop bits to 1

# Display instructions to the user
print("Enter 2 sixteen-bit numbers.\nThe sum will be printed")
print("Press 'q' to exit the infinite loop at any time")

while True:  
    x = input("Enter number 1: ")  # Take first input from user

    if x == 'q':  # Check if user wants to exit
        break  

    ot = ComPort.write(struct.pack('h', int(x)))  # Send first number to FPGA
    time.sleep(0.1)
    
    y = input("Enter number 2: ")  # Take second input from user
    ot = ComPort.write(struct.pack('h', int(y)))  # Send second number to FPGA
    time.sleep(0.1)
    
    it = ComPort.read(2)  # Read the 2-byte sum from FPGA

    # Convert received bytes to integer and print result
    print(f"{x} + {y} = {int.from_bytes(it, byteorder='big')}")

# Close the serial port after exiting the loop
ComPort.close()