%%% Author: Bodo Baumann
%%% github: github.com/sarkspasst
%%% Organization: UNC Charlotte EPIC
%%% Date: 06/10/2024

%%% !!!TAKE CARE OF THE REGISTER NUMBERING IN THE CODE!!!
%%% !!!MATLAB STARTS COUNTING FROM 1, THEREFORE THE REGISTER NUMBERING IN THE CODE IS OFF BY 1!!!
%%% !!!MAKE SURE TO ADJUST THE REGISTER NUMBERING IN THE CODE BETWEEN PYTHON AND MATLAB!!!



function writeDataToModbusServer(DataArray, portNumbers)
    % Server IP and port
    server_ip_address = '192.168.0.224';

    % Server ports
    serverPortsList = portNumbers;
    %disp(['Successfully loaded server ports: ']);  %, num2str(serverPortsList)]);

    % Load data from CSV
    modbusData = DataArray;
    %disp('Successfully loaded data from input')

    success = false;

    while ~success
        try
            % Loop over server ports
            for i = 1:length(serverPortsList)
                %disp('Successfully started loop over server ports')
                server_port = serverPortsList(i);
                
                % Create Modbus object
                modbusObj = modbus('tcpip', server_ip_address, server_port);
                modbusObj.WordOrder = 'little-endian';
                %disp('Successfully created Modbus object')
                
                % Get data from table
                derID= modbusData{i, 'BusNumber'};
                derType = modbusData{i, 'Type'};
                Q1_kvar = modbusData{i, 'Q1_kvar'};
                Q2_kvar = modbusData{i, 'Q2_kvar'};
                Q3_kvar = modbusData{i, 'Q3_kvar'};
                Q1_dis_kvar = modbusData{i, 'Q1_dis_kw'};
                Q2_dis_kvar = modbusData{i, 'Q2_dis_kw'};
                Q3_dis_kvar = modbusData{i, 'Q3_dis_kw'};
                P1_soc_pred_kwh = modbusData{i, 'P1_soc_pred_kwh'};
                P2_soc_pred_kwh = modbusData{i, 'P2_soc_pred_kwh'};
                P3_soc_pred_kwh = modbusData{i, 'P3_soc_pred_kwh'};
                P1_soc_act_kwh = modbusData{i, 'P1_soc_act_kwh'};
                P2_soc_act_kwh = modbusData{i, 'P2_soc_act_kwh'};
                P3_soc_act_kwh = modbusData{i, 'P3_soc_act_kwh'};
                P1_kw = modbusData{i, 'P1_kw'};
                P2_kw = modbusData{i, 'P2_kw'};
                P3_kw = modbusData{i, 'P3_kw'};
                P1_dis_kw = modbusData{i, 'P1_dis_kw'};
                P2_dis_kw = modbusData{i, 'P2_dis_kw'};
                P3_dis_kw = modbusData{i, 'P3_dis_kw'};
                P1_soc_kwh = modbusData{i, 'P1_soc_kwh'};
                P2_soc_kwh = modbusData{i, 'P2_soc_kwh'};
                P3_soc_kwh = modbusData{i, 'P3_soc_kwh'};
                timeStep = modbusData{i, 'TimeStep'};
                trackingStep = modbusData{i, 'TrackingStep'};
                %disp('Successfully fetched data from table')

                % Write data to Modbus server
                write(modbusObj, 'holdingregs', 40002, derID); %Register number 40001 in Modbus
                %disp(['Successfully sent BUS NUMBER [= ', num2str(derID), ']'])
                write(modbusObj, 'holdingregs', 40003, derType); %Register number 40002
                %disp(['Successfully sent DER TYPE [= ', num2str(derType), ']'])
                write(modbusObj, 'holdingregs', 40004, P1_kw, 'single'); %Register number 40003
                %disp(['Successfully sent P1 [= ', num2str(P1_kw), '(kw)]'])
                write(modbusObj, 'holdingregs', 40006, P2_kw, 'single'); %Register number 40005
                %disp(['Successfully sent P2 [= ', num2str(P2_kw), '(kw)]'])
                write(modbusObj, 'holdingregs', 40008, P3_kw, 'single'); %Register number 40007
                %disp(['Successfully sent P3 [= ', num2str(P3_kw), '(kw)]'])
                write(modbusObj, 'holdingregs', 40010, Q1_kvar, 'single'); %Register number 40009
                %disp(['Successfully sent Q1 [= ', num2str(Q1_kvar), '(kvar)]'])
                write(modbusObj, 'holdingregs', 40012, Q2_kvar, 'single'); %Register number 40011
                %disp(['Successfully sent Q2 [= ', num2str(Q2_kvar), '(kvar)]'])
                write(modbusObj, 'holdingregs', 40014, Q3_kvar, 'single'); %Register number 40013
                %disp(['Successfully sent Q3 [= ', num2str(Q3_kvar), '(kvar)]'])
                write(modbusObj, 'holdingregs', 40016, P1_dis_kw, 'single'); %Register number 40015
                %disp(['Successfully sent P1_DIS [= ', num2str(P1_dis_kw), '(kw)]'])
                write(modbusObj, 'holdingregs', 40018, P2_dis_kw, 'single'); %Register number 40017
                %disp(['Successfully sent P2_DIS [= ', num2str(P2_dis_kw), '(kw)]'])
                write(modbusObj, 'holdingregs', 40020, P3_dis_kw, 'single'); %Register number 40019
                %disp(['Successfully sent P3_DIS [= ', num2str(P3_dis_kw), '(kw)]'])
                write(modbusObj, 'holdingregs', 40022, Q1_dis_kvar, 'single'); %Register number 40021
                %disp(['Successfully sent Q1_DIS [= ', num2str(Q1_dis_kvar), '(kvar)]'])
                write(modbusObj, 'holdingregs', 40024, Q2_dis_kvar, 'single'); %Register number 40023
                %disp(['Successfully sent Q2_DIS [= ', num2str(Q2_dis_kvar), '(kvar)]'])
                write(modbusObj, 'holdingregs', 40026, Q3_dis_kvar, 'single'); %Register number 40025
                %disp(['Successfully sent Q3_DIS [= ', num2str(Q3_dis_kvar), '(kvar)]'])
                write(modbusObj, 'holdingregs', 40028, P1_soc_pred_kwh, 'single'); %Register number 40027
                %disp(['Successfully sent P1_SOC_PRED [= ', num2str(P1_soc_pred_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40030, P2_soc_pred_kwh, 'single'); %Register number 40029
                %disp(['Successfully sent P2_SOC_PRED [= ', num2str(P2_soc_pred_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40032, P3_soc_pred_kwh, 'single'); %Register number 40031
                %disp(['Successfully sent P3_SOC_PRED [= ', num2str(P3_soc_pred_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40034, P1_soc_act_kwh, 'single'); %Register number 40033
                %disp(['Successfully sent P1_SOC_ACT [= ', num2str(P1_soc_act_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40036, P2_soc_act_kwh, 'single'); %Register number 40035
                %disp(['Successfully sent P2_SOC_ACT [= ', num2str(P2_soc_act_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40038, P3_soc_act_kwh, 'single'); %Register number 40037
                %disp(['Successfully sent P3_SOC_ACT [= ', num2str(P3_soc_act_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40040, P1_soc_kwh, 'single'); %Register number 40039
                %disp(['Successfully sent P1_SOC [= ', num2str(P1_soc_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40042, P2_soc_kwh, 'single'); %Register number 40041
                %disp(['Successfully sent P2_SOC [= ', num2str(P2_soc_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40044, P3_soc_kwh, 'single'); %Register number 40043
                %disp(['Successfully sent P3_SOC [= ', num2str(P3_soc_kwh), '(kwh)]'])
                write(modbusObj, 'holdingregs', 40046, timeStep, 'int16'); %Register number 40045
                %disp(['Successfully sent time step [= ', num2str(timeStep), ']'])
                write(modbusObj, 'holdingregs', 40047, trackingStep, 'int16'); %Register number 40046
                %disp(['Successfully sent tracking step [= ', num2str(trackingStep), ']'])
                disp(['Successfully sent all data to Modbus server ', num2str(server_ip_address), ' on port ', num2str(server_port)])
                
                % Close Modbus connection
                %fclose(modbusObj);
            end

            %disp('Successfully sent all data to Modbus server');

            success = true;

        catch
            disp('Failed to open Modbus connection. Retrying...');
            pause(1);
        end
    end