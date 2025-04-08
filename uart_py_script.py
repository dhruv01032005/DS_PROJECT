import serial          # Import the pyserial module for serial communication
import struct          # Import struct for packing and unpacking binary data
import time            # Import time module
import pandas as pd    # Import pandas for reading csv file

df = pd.read_csv("intermediate_output.csv",header = None)

data = df.values

# Open serial communication on COM4
ComPort = serial.Serial('COM4')  
ComPort.baudrate = 115200  # Set baud rate to 115200
ComPort.bytesize = 8       # Set data bits to 8
ComPort.parity = 'N'       # Set parity to None
ComPort.stopbits = 1       # Set stop bits to 1

while True:  
    x = input("Do you want to quit (Y/N): ")  # Ask the user if he wants to quit

    if (x == 'Y' or x == 'y'):  # Check if user wants to quit
        break
    
    # Inputing all 1152 input values to the UART
    for k in range(data.shape[0]):
        num = data[k][0]
        ot = ComPort.write(struct.pack('h', int(num)))
        time.sleep(0.01)
    
    it = ComPort.read(2)  # Reading the predicted value from FPGA (2-bit data)

    # Convert received bytes to integer and print result
    print(f"Predicted Number = {int.from_bytes(it, byteorder='big')}")
    print("Actual Number = 7")

# Close the serial port after exiting the loop
ComPort.close()