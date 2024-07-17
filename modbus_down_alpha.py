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
    
    df_dn = pd.read_csv('result_dn_save.csv') # dn csv 
    
    startRound = time.perf_counter()
    print("********* Sending DER sepoints, round# ", i, "*********")
    portCount=1
    while portCount <= len(serverPortsList):
    #while portCount <= 1000:
        server_port =  serverPortsList[portCount-1]
        #print("server port: ", server_port)
        
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
    
 