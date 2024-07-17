import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import threading
import time
import numpy as np

#Variables
mult = 1 #in hours; Time to next dataset
wait = 15 #Multiplier for the wait time, same as in DataExtract.py, if Nodes high, increase wait time (e.g. 1 for 100 nodes; 15 for 10000 nodes)

### Rerun over watchdog observer Part 1
# Create a shared variable
rerun_flag = [False]

#Try to handle the rerun over the update of the csv files
class FileChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if os.path.basename(event.src_path) == 'result.csv':
            time.sleep(5)
            rerun_flag[0] = True
###

class Plotter:
    def __init__(self, csv_files, mult=60):
        self.csv_files = csv_files
        self.mult = mult

    def plot_data(self, column_name):
        selected_files = st.multiselect(f'Select {column_name} Nodes for visualization', self.csv_files)
        for selected_file in selected_files:
            df = pd.read_csv(selected_file)
            df = df.iloc[:, 2:8] # Only look at relevant data -> P_i; Q_i
            dfP = df.iloc[:, 0:3] # Only look at relevant data -> P_i
            dfQ = df.iloc[:, 3:6] # Only look at relevant data -> Q_i

            # Multiselect for number of timesteps to display
            #row_options = list(range(1, len(df) + 1))
            #selected_rows = st.multiselect('Select number of hours to display', row_options)

            #dfP = dfP.iloc[0:selected_rows, :]
            #dfQ = dfQ.iloc[0:selected_rows, :]

            fig_colP, fig_colQ = st.columns(2)

            # Plot P_i
            with fig_colP:
                st.write(f'P_i for {selected_file}')
                selected_columns = st.multiselect(f'Select P for {selected_file}', dfP.columns.tolist(), default=dfP.columns.tolist())
                self._plot_columns(dfP, selected_columns)

            # Plot Q_i
            with fig_colQ:
                st.write(f'Q_i for {selected_file}')
                selected_columns = st.multiselect(f'Select Q for {selected_file}', dfQ.columns.tolist(), default=dfQ.columns.tolist())
                self._plot_columns(dfQ, selected_columns)

    def _plot_columns(self, df, selected_columns):
        fig, ax = plt.subplots()
        for column in selected_columns:
            t_val = self.mult * np.arange(len(df[column]))  # construct time values for graphs
            ax.plot(t_val, df[column], label=column)
    
        #ax.set_ylim([0, 0.1])  # Modify the y-axis range
        ax.set_title('Power vs. Time')
        ax.set_xlabel('Time (m)')
        ax.set_ylabel('Power (W)')
        ax.legend()
    
        st.pyplot(fig)

#    def _plot_columns(self, df, selected_columns):
#        for column in selected_columns:
#            fig, ax = plt.subplots()
#            t_val = self.mult * np.arange(len(df[column]))  # construct time values for graphs
#            ax.plot(t_val, df[column])
#            ax.set_ylim([0, 10])  # Modify the y-axis range
#            ax.set_title(f'{column} vs. Time')
#            ax.set_xlabel('time (s)')
#            ax.set_ylabel(f'{column} (MW)')

#            st.pyplot(fig)

def cls():
    os.system('cls' if os.name=='nt' else 'clear')

cls()

st.set_page_config(
    page_title="Power Value Dashboard",
    page_icon="✅",
    layout="wide",
)

st.title("Real-Time Power Node Dashboard")

# Get list of CSV files in current directory
csv_files = [os.path.join('results', f) for f in os.listdir('results') if f.endswith('.csv')]

num_csv = len(csv_files) #subtraction for csv files in dir other than the ones for the nodes

# Create a multiselect box for selecting CSV files
#selected_files = st.multiselect('Select Nodes for visualization', csv_files)

placeholder = st.empty()

with placeholder.container():

    kpi1, kpi2, kpi3 = st.columns(3)

    kpi1.metric(
        label = "Nodes",
        value = num_csv
        #delta = num_csv - num_csv_old
        #num_csv_old = num_csv #update number of csv for delta calculation of next round
    )

    kpi2.metric(
        label = "Number of timeslots",
        #timeslots = pd.read_csv('value_0.csv')
        value = pd.read_csv('./results/3000.csv').shape[0],
        delta = (f'+1 / h')
    )

    kpi3.metric(
        label = "Time alive in sec",
        value = pd.read_csv('./results/3000.csv').shape[0] * mult #time alive in seconds
    )

    fig_col1, fig_col2 = st.columns(2)

    # Left plot
    with fig_col1:
        plotter = Plotter(csv_files)
        plotter.plot_data('First')
    
    # Right plot
    with fig_col2:
        plotter = Plotter(csv_files)
        plotter.plot_data('Second')

### Rerun over watchdog observer Part 2
# Start a watchdog observer in a separate thread
event_handler = FileChangeHandler()
observer = Observer()
observer.schedule(event_handler, path='./', recursive=False)
observer.start()
###

# Check the shared variable in a loop in the main thread
while True:
    if rerun_flag[0]:
        rerun_flag[0] = False
        st.rerun()
    time.sleep(3*wait) #wait for the next iteration (3 times the time to wait for the csv files to be written, same as in DataExtract.py)


