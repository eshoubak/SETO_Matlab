# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 13:20:50 2024

@author: Amimul Ehsan
"""

from pymodbus.constants import Endian
from pymodbus.client.sync import ModbusTcpClient
from pymodbus.payload import BinaryPayloadDecoder
import time

server_ip_address = "192.168.0.224" #should be the server/PLC ip address


portFile = open("monitorPorts.txt", "r")
serverPorts = portFile.read()
print("Monitor PORTS: ",serverPorts)
portFile.close()

serverPorts = serverPorts.replace("[","")
serverPorts = serverPorts.replace("]","")

serverPortsList = list(serverPorts.split(", ")) 



#start counting time

i=1
while i>0:
    startRound = time.perf_counter()
    print("*********Checking for Field Monitor Measurements, round# ", i, "*********")
    portCount=1
    #while portCount <= 1000:
    while portCount <= len(serverPortsList):
        server_port =  serverPortsList[portCount-1]
        #print("server port: ", server_port)
        portCount = portCount+1
        errorCount = 0
        
        while i>0:
            # client connect and pull data from server
            try:
                client = ModbusTcpClient(host=server_ip_address, port=server_port)
                print("-------------------------------------------------------")
                print("[+]Info : Connection successful with ", server_port, ": " + str(client.connect()))
                
                #read monitor value float
                read_value = client.read_holding_registers(40001,2)
                real_decoder = BinaryPayloadDecoder.fromRegisters(read_value.registers, byteorder = Endian.Big, wordorder = Endian.Little)
                value = real_decoder.decode_32bit_float()
                monitorVal = "%.2f" %value
                
                if server_port == '501':
                    print(f"[PORT: {server_port}] RTDS feeder-1 net load: {monitorVal}")
                if server_port == '502':
                    print(f"[PORT: {server_port}] RTDS feeder-2 net load: {monitorVal}")
                if server_port == '503':
                    print(f"[PORT: {server_port}] OpenDSS feeder-1 net load: {monitorVal}")
                if server_port == '504':
                    print(f"[PORT: {server_port}] OpenDSS feeder-2 net load: {monitorVal}")
                    
                
                
                break 
            
            except:
                errorCount = errorCount + 1
                print(f"ERROR in reading PORT: {server_port}. Error count# {errorCount}. Trying again... ")
                
                if errorCount >= 5:
                    print(f"PORT: {server_port} read operation FAILED in try# {errorCount}!!! Skipping over to next port... ")
                    break 
            
        #end counting time
        finishRound = time.perf_counter()
        timeElapsedRound = round(finishRound-startRound, 2)
        #display time elapsed
        print("-------------------------------------------------------")
        print(f"Time elapsed for Round #{i} is {timeElapsedRound} second(s)")
        print("-------------------------------------------------------")
        
   
    i=i+1
    time.sleep(5)
    
 

    
    