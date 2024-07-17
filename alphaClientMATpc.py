# -*- coding: utf-8 -*-
"""
Created on Fri Jun 23 11:36:40 2023

@author: Amimul Ehsan
"""

import pandas as pd
import time
from pymodbus.constants import Endian
from pymodbus.client.sync import ModbusTcpClient
from pymodbus.payload import BinaryPayloadDecoder
import os.path


server_ip_address = "192.168.0.224"
server_port = 600

errorCount = 0

i = 1
while i>0:
    
    try: 
        # check if fromMatlab csv file exists
        csvSetPointFile = '/home/desgl-server2/Downloads/Anpingcode/T6662_Three_Phase_reduced_function_parallel/result_up_save.csv'
        csvSetpointFileExist = os.path.isfile(csvSetPointFile)
        
        if csvSetpointFileExist == True:
            df = pd.read_csv('/home/desgl-server2/Downloads/Anpingcode/T6662_Three_Phase_reduced_function_parallel/result_up_save.csv')

            derCount = df["Bus Number"].size
            print("*******************************************************")
            print(f"Sending # of DERs [count = {derCount}] to initialize Modbus servers")
            
            
            client = ModbusTcpClient(host=server_ip_address, port=server_port)
            print("*******************************************************")
            print("[+]Info : Connection successful with ", server_port, ": " + str(client.connect()))
            
            # Write DER count to register 40001    
            client.write_register(40001, derCount, unit=1)
            print(f"[+]Info : # of DER successfully sent to server [PORT: {server_port}]")
            
            # Read net load value (opendss + rtds) from register 40002
            read_value = client.read_holding_registers(40002,2)
            print(f"read_value: {read_value.registers}")
            real_decoder = BinaryPayloadDecoder.fromRegisters(read_value.registers, byteorder = Endian.Big, wordorder = Endian.Little)
            print(f"real_decoder: {real_decoder}")
            value = real_decoder.decode_32bit_float()
            print(f"value: {value}")
            netLoad = "%.2f" %value
            print(f"[+]Info : Netload (DSS+RTDS) receieved from simulation: {netLoad} (kw)")
            
            # Read DER port numbers from PORT 600
            portCount = 1
            registerNumber = 40004
            portNumber = []
            while portCount <= derCount:
                value = client.read_holding_registers(registerNumber, 1, unit=1) 
                port = value.registers[0]
                portNumber.append(port)
                portCount = portCount+1
                registerNumber = registerNumber+1
            
            # Write port numbers to a txt file
            usedPortTxt = f"{portNumber}"
            portFile = open("serverPorts.txt", "w")
            portFile.write(usedPortTxt)
            print(f"Used Ports: {portNumber}")
            print("-------------------------------------------------------")
            time.sleep(5)
            
        else:
            print('NO CSV file with setpoints exist. Skipping over to next loop run...')
            
            break

    except:
        errorCount = errorCount + 1
        print(f"ERROR in writing data to PORT: {server_port}. Error count# {errorCount}. Trying again... ")
        
        if errorCount >= 5:
            print(f"PORT: {server_port} write operation FAILED in try# {errorCount}!!! skipping to next loop... ")
        
        
        time.sleep(5)
            
           
            
    
    
    

    



    
