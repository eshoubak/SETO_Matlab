# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 13:20:50 2024

@author: Amimul Ehsan
"""

from pymodbus.constants import Endian
from pymodbus.client.sync import ModbusTcpClient
from pymodbus.payload import BinaryPayloadDecoder
from pymodbus.payload import BinaryPayloadBuilder
import time
import datetime

import pandas as pd

import warnings

#import md5, sha

with warnings.catch_warnings():
    warnings.filterwarnings("ignore", category=DeprecationWarning)
    

server_ip_address = "192.168.0.224" #should be the server/PLC ip address


portFile = open("serverPorts.txt", "r")
serverPorts = portFile.read()
print("Server PORTS: ",serverPorts)
portFile.close()

serverPorts = serverPorts.replace("[","")
serverPorts = serverPorts.replace("]","")

serverPortsList = list(serverPorts.split(", ")) 



i=1
while i>0:
    
    df_up = pd.read_csv('result_up_save.csv') # up csv
    df_dn = pd.read_csv('result_dn_save.csv') # dn csv 
    
    startRound = time.perf_counter()
    print("********* Sending DER sepoints, round# ", i, "*********")
    portCount=1
    while portCount <= len(serverPortsList):
    #while portCount <= 1000:
        server_port =  serverPortsList[portCount-1]
        #print("server port: ", server_port)
        
        # Data to write 
        # from up CSV
        derID_up = df_up.iloc[portCount-1]["Bus Number"]
        derType_up = df_up.iloc[portCount-1]["Type"]
        
        Q1_kvar_up = df_up.iloc[portCount-1]["Q1_kvar"]
        Q2_kvar_up = df_up.iloc[portCount-1]["Q2_kvar"]
        Q3_kvar_up = df_up.iloc[portCount-1]["Q3_kvar"]
        
        Q1_dis_kvar_up = df_up.iloc[portCount-1]["Q1_dis_kw"]
        Q2_dis_kvar_up = df_up.iloc[portCount-1]["Q2_dis_kw"]
        Q3_dis_kvar_up = df_up.iloc[portCount-1]["Q3_dis_kw"]
        
        P1_soc_pred_kwh_up = df_up.iloc[portCount-1]["P1_soc_pred_kwh"]
        P2_soc_pred_kwh_up = df_up.iloc[portCount-1]["P2_soc_pred_kwh"]
        P3_soc_pred_kwh_up = df_up.iloc[portCount-1]["P3_soc_pred_kwh"]
        
        P1_soc_act_kwh_up = df_up.iloc[portCount-1]["P1_soc_act_kwh"]
        P2_soc_act_kwh_up = df_up.iloc[portCount-1]["P2_soc_act_kwh"]
        P3_soc_act_kwh_up = df_up.iloc[portCount-1]["P3_soc_act_kwh"]
        
        
        
        # from dn CSV        
        P1_kw_dn = df_dn.iloc[portCount-1]["P1_kw"]
        P2_kw_dn = df_dn.iloc[portCount-1]["P2_kw"]
        P3_kw_dn = df_dn.iloc[portCount-1]["P3_kw"]
        
        P1_dis_kw_dn = df_dn.iloc[portCount-1]["P1_dis_kw"]
        P2_dis_kw_dn = df_dn.iloc[portCount-1]["P2_dis_kw"]
        P3_dis_kw_dn = df_dn.iloc[portCount-1]["P3_dis_kw"]
        
        P1_soc_kwh_dn = df_dn.iloc[portCount-1]["P1_soc_kwh"]
        P2_soc_kwh_dn = df_dn.iloc[portCount-1]["P2_soc_kwh"]
        P3_soc_kwh_dn = df_dn.iloc[portCount-1]["P3_soc_kwh"]
        
        
        
        
        errorCount = 0
        while i>0:
            try:
                # client connect to server
                client = ModbusTcpClient(host=server_ip_address, port=server_port)
                print("-------------------------------------------------------")
                print("[+]Info : Connection successful with ", server_port, ": " + str(client.connect()))
                
                # send up CSV data 
                # Write der ID
                client.write_register(40001, derID_up, unit=1)
                print(f"Successfully sent BUS NUMBER [= {derID_up}]")
                
                # Write der type
                client.write_register(40002, derType_up, unit=1)
                print(f"Successfully sent DER TYPE [= {derType_up}]")
                
                #send q1_kvar 
                value_to_write = Q1_kvar_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40009, payload, unit=1, skip_encode=True)
                print(f"Successfully sent Q1 [= {value_to_write}(kvar)]")
                #send q2_kvar
                value_to_write = Q2_kvar_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40011, payload, unit=1, skip_encode=True)
                print(f"Successfully sent Q2 [= {value_to_write}(kvar)]")
                #send q3_kvar 
                value_to_write = Q3_kvar_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40013, payload, unit=1, skip_encode=True)
                print(f"Successfully sent Q3 [= {value_to_write}(kvar)]")
                
                #send q1_dis_kvar
                value_to_write = Q1_dis_kvar_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40021, payload, unit=1, skip_encode=True)
                print(f"Successfully sent Q1_dis [= {value_to_write}(kvar)]")
                #send q2_dis_kvar
                value_to_write = Q2_dis_kvar_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40023, payload, unit=1, skip_encode=True)
                print(f"Successfully sent Q2_dis [= {value_to_write}(kvar)]")
                #send q3_dis_kvar
                value_to_write = Q3_dis_kvar_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40025, payload, unit=1, skip_encode=True)
                print(f"Successfully sent Q3_dis [= {value_to_write}(kvar)]")
                
                #send p1_soc_pred_kwh
                value_to_write = P1_soc_pred_kwh_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40027, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P1 SOC_PRED [= {value_to_write}(kwh)]")
                #send p2_soc_pred_kwh
                value_to_write = P2_soc_pred_kwh_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40029, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P2 SOC_PRED [= {value_to_write}(kwh)]")
                #send p3_soc_pred_kwh
                value_to_write = P3_soc_pred_kwh_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40031, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P3 SOC_PRED [= {value_to_write}(kwh)]")
                
                #send p1_soc_act_kwh
                value_to_write = P1_soc_act_kwh_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40033, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P1 SOC_ACT [= {value_to_write}(kwh)]")
                #send p2_soc_act_kwh
                value_to_write = P2_soc_act_kwh_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40035, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P2 SOC_ACT [= {value_to_write}(kwh)]")
                #send p3_soc_act_kwh
                value_to_write = P3_soc_act_kwh_up #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40037, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P3 SOC_ACT [= {value_to_write}(kwh)]")
                
                
        
                

                
                # send from DN CSV
                #send p1_kw 
                value_to_write = P1_kw_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40003, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P1 [= {value_to_write}(kw)]")
                #send p2_kw 
                value_to_write = P2_kw_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40005, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P2 [= {value_to_write}(kw)]")
                #send p3_kw 
                value_to_write = P3_kw_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40007, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P3 [= {value_to_write}(kw)]")
                
                
                
                #send p1_dis_kw 
                value_to_write = P1_dis_kw_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40015, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P1_dis [= {value_to_write}(kw)]")
                #send p2_dis_kw 
                value_to_write = P2_dis_kw_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40017, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P2_dis [= {value_to_write}(kw)]")
                #send p3_dis_kw 
                value_to_write = P3_dis_kw_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40019, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P3_dis [= {value_to_write}(kw)]")
                
                
                
                
                
                #send p1_soc_kwh
                value_to_write = P1_soc_kwh_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40039, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P1 SOC [= {value_to_write}(kwh)]")
                #send p2_soc_kwh
                value_to_write = P2_soc_kwh_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40041, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P2 SOC [= {value_to_write}(kwh)]")
                #send p3_soc_kwh
                value_to_write = P3_soc_kwh_dn #float value
                builder = BinaryPayloadBuilder(byteorder=Endian.Big, wordorder=Endian.Little)
                builder.add_32bit_float(value_to_write)
                payload = builder.build()
                client.write_registers(40043, payload, unit=1, skip_encode=True)
                print(f"Successfully sent P3 SOC [= {value_to_write}(kwh)]")
                
                
                
                
                
                break
            
            except:
                errorCount = errorCount + 1
                print(f"ERROR in writing data to PORT: {server_port}. Error count# {errorCount}. Trying again... ")
               
                if errorCount >= 5:
                    print(f"PORT: {server_port} write operation FAILED in try# {errorCount}!!! Skipping over to next server... ")
                    break
        
        # #update sendStatus
        # df_up.sendStatus[portCount] = 1  # Write the value 1 to column sendStatus, row i (zero-indexed)
        # df_up.sendTimeStamp[portCount] = datetime.datetime.now()            
        # df_up.to_csv("result_up_save.csv", index=False)  # Save the file
        
        # df_dn.sendStatus[portCount] = 1  # Write the value 1 to column sendStatus, row i (zero-indexed)
        # df_dn.sendTimeStamp[portCount] = datetime.datetime.now()            
        # df_dn.to_csv("result_dn_save.csv", index=False)  # Save the file
        
        #end counting time
        finishRound = time.perf_counter()
        timeElapsedRound = round(finishRound-startRound, 2)
        #display time elapsed
        print("-------------------------------------------------------")
        print(f"Time elapsed for Round #{i} is {timeElapsedRound} second(s)")
        print("-------------------------------------------------------")
        
        print("Set point send complete!")
        
        
        portCount=portCount+1
             
    
    i=i+1
    time.sleep(10)
    
 

    
    