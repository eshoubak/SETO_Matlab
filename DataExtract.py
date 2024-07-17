import pandas as pd
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time
import os
import numpy as np

#Variables
wait = 1 #Multiplier for the wait time, if Nodes high, increase wait time (e.g. 1 for 100 nodes; 10 for 10000 nodes)

class FileChangeHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_modified = {}

    def on_modified(self, event):
        filename = os.path.basename(event.src_path)
        if filename == 'result_up_save.csv':
            now = time.time()
            if filename in self.last_modified and now - self.last_modified[filename] < 3 * wait:
                # Ignore event if file was modified less than 1 second ago
                return
            self.last_modified[filename] = now

            time.sleep(1*wait)  # wait for all write operations to complete
            count = time.time()
            df = pd.read_csv('result_up_save.csv')
            derArray = df.to_numpy()#.to_string()
            for i in range(len(derArray[:,0])):
                if not os.path.isfile(f'./results/{derArray[i,0]}.csv'):
                    df.iloc[i].to_frame().T.to_csv(f'./results/{derArray[i,0]}.csv', mode='a', index=False, header=True)
                else:
                    df.iloc[i].to_frame().T.to_csv(f'./results/{derArray[i,0]}.csv', mode='a', index=False, header=False)
            print(f'CSV files created at {count} in {time.time() - count} seconds')
"""
class FileChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        #time.sleep(5)
        if os.path.basename(event.src_path) == 'power_values.csv':
            time.sleep(10)  # wait for all write operations to complete
            df = pd.read_csv('power_values.csv')
            for i in range(len(df)):
                #row_df = df.iloc[i].to_frame().T #macht doch eigentlich nix weil die danach sowieso nochmal die row auslesen...?
                #custom_headers = [f'Q_{i}', f'P_{i}'] #name the headers according to the data you insert

                #header_df = pd.DataFrame(data=row_df.values, columns=custom_headers)


                if not os.path.isfile(f'value_{i}.csv'):
                    #Add custom header to csv files
                    #header_df.to_csv(f'value_{i}.csv', mode='w', index=False, header = True)
                    df.iloc[i].to_frame().T.to_csv(f'value_{i}.csv', mode='a', index=False, header=True)
                else:
                    df.iloc[i].to_frame().T.to_csv(f'value_{i}.csv', mode='a', index=False, header=False)
"""      
event_handler = FileChangeHandler()
observer = Observer()
observer.schedule(event_handler, path='./', recursive=False)
observer.start()

try:
    while True:
        time.sleep(1*wait)
except KeyboardInterrupt:
    observer.stop()

observer.join()