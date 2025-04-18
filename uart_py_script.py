import serial
import struct
import time
import pandas as pd

df = pd.read_csv("intermediate_output.csv", header=None)
data = df.values

ComPort = serial.Serial('COM4', baudrate=115200, timeout=2)
ComPort.bytesize = 8
ComPort.parity = 'N'
ComPort.stopbits = 1

while True:
    x = input("Do you want to quit (Y/N): ").lower()
    if (x == 'y' or x == 'Y'):
        break
    
    # Send all 1152 values as bytes
    for k in range(data.shape[0]):
        num = data[k][0]
        ot = ComPort.write(struct.pack('B', int(num)))
        time.sleep(0.01)
    
    print("Input Done")
    
    it = ComPort.read(10)
    print(f"FPGA Output: {list(it)}")

ComPort.close()
