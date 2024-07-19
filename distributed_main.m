clc;clear;
yalmip('clear')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo
%Initialize SQL database
[conn,sqltableup,sqltabledn,sqltableall] = initSQLDatabase();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo


%% ============================== case setting  
% system information
file_sys = fullfile('0_data','T6662_UNCC_Three_Phase_Revised.mat');
file_dg = fullfile('0_data','T6662_Three_Phase_Reduced.xlsx');

file_csv = fullfile('0_data','T6662_Three_Phase_Reduced_CSV.xlsx');
file_csv1 = readmatrix(file_csv);
file_csv_dn2 = fullfile('0_data','T6662_lower_2.xlsx');
file_csv12 = readmatrix(file_csv_dn2);

file_csv_up = fullfile('0_data','T6662_Three_Phase_Reduced_upper_CSV.xlsx');
file_csv2 = readmatrix(file_csv_up);
file_csv_up2 = fullfile('0_data','T6662_upper_2.xlsx');
file_csv22 = readmatrix(file_csv_up2);

file_load = fullfile('0_data','load_pv.xlsx');
file_result = '[1]_result';
if exist(file_result,'dir') == 0
    mkdir(file_result)
end

% file_path = 'E:\OneDrive - Southern Methodist University\[A1]_Project\3_SETO_Control\[A3]_code_large_system\hotspring\0_data';
% file_sys = fullfile(file_path,'hotspring_UNCC_Revised_5mg_v2.mat');
% file_dg = fullfile(file_path,'hotspring_v2_5mg_v2.xlsx');
% file_load = fullfile(file_path,'load_pv.xlsx');

file_path = ['/home/desgl-server2/Downloads/Anpingcode/T6662_Three_Phase_reduced_function_parallel/0_data'];     
file_sys = fullfile(file_path,'T6662_UNCC_Three_Phase_Revised.mat');
file_dg = fullfile(file_path,'T6662_Three_Phase_Reduced.xlsx');
file_load = fullfile(file_path,'load_pv.xlsx');
file_result = '[1]_result';
if exist(file_result,'dir') == 0
    mkdir(file_result)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo
%Set up Connection to Modbus Server (Is this the right place to do this? Can the #DERs change again after this point?)
portNumbers = initModbusConnection(size(file_csv1 ,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo

s_base = 1000; %kW
n_phase = 3; % number of pheases

F_MAX = 5; % MW line capacity

Delt_V = 2 * 0.05;
V_MIN = 1.00 - Delt_V; % lower bound of voltage magnitude
V_MAX = 1.00 + Delt_V; % upper bound of voltage magnitude

interval_up = 60; % minutes
interval_dn = 15; % minutes  
delt_t_up = interval_up/60;
delt_t_dn = interval_dn/60;

n_t_up = 24; % number of time slot
n_t_dn = 4; % number of tracking step

M = 1e4; % Big Value. Used for the upper-level modeling
truncate = 6; % round to N digits to the right of the decimal point.Used for the upper-level results

run distributed_read

% for lower-level control
run distributed_agent_data % constant agent data
run distributed_communication_network % build the original communication network

% store the tracking evolution; can be removed
result_track.p_local = cell(n_t_up*n_t_dn,1);
result_track.NET_LOAD = cell(n_t_up*n_t_dn,1);
result_track.P_REF= cell(n_t_up*n_t_dn,1);
result_track.n_nmg= cell(n_t_up*n_t_dn,1);
result_track.iter = zeros(n_t_up*n_t_dn,1);
result_track.solution = cell(n_t_up*n_t_dn,1);

result_track.lmd = cell(n_t_up*n_t_dn,1);
result_track.y = cell(n_t_up*n_t_dn,1);
result_track.lmd_diff = cell(n_t_up*n_t_dn,1);
result_track.y_diff = cell(n_t_up*n_t_dn,1);

%% ============================== modeling
run distributed_upper_model

% ==================== simulation begin
system_status = {'Emergency','Normal'};
network_status = {'Isolated','Networked'};

%hybrid = 0;
hybrid = 1;
x_s = 0 * ones(n_pcc,1); % 0: emergency;  1: normalcy
networked = 1; % 0: isolated;  1: networked

fprintf('-----------====== Simulation Start ======----------------------\n');
count = 1;
t_start = tic;
for t = 1:24
    % ==================== pre-defined opeartion scenario for test
    if hybrid == 1
        if (t >= 8) && (t<= 16)
            x_s = 0*ones(n_pcc,1);
        else
            x_s = 1*ones(n_pcc,1);
        end
    end
    
    % ==================== upper level
    if t == 1
        % if field devices are added, the right-hand side value should be
        % read from field devices
        SOC_NEW_UP(1,:,:) = repmat(ES.e_ini,1,3);
    else
        % if field devices are added, the right-hand side value should be
        % read from field devices
        % as we currently do not include the real-time operation between two
        % consective tracking control, these values come from the
        % previous tracking step.
        SOC_NEW_UP(1,:,:) = round( to_field.soc_dn,truncate );
        P_ES_CH_NEW_UP(1,:,:) = round( to_field.p_es_ch_dn,truncate );
        P_ES_DIS_NEW_UP(1,:,:) = round( to_field.p_es_dis_dn,truncate );
        P_DG_NEW_UP(1,:,:) = round( to_field.p_dg_dn(index_dg_local,:),truncate );
    end
    
    run distributed_upper_scenario
    tic
    run distributed_upper_update
    result_up.time(t,1) = toc;

    if sol_up.problem == 0
        solve_status = 'Optimal';
    else
        solve_status = 'Infeasible'; % if true, check the results of the upper-level
        % fprintf('trying CPLEX...\n')
        % options_up_cplex = sdpsettings('verbose',0, 'solver','cplex');
        % options_up_cplex.cplex.mip.tolerances.mipgap = 0.5/100;
        % sol_up = optimize(cons_up, obj_up, options_up_cplex);
        % if sol_up.problem == 0
        %     solve_status = 'Optimal';
        % else
        %     fprintf('CPLEX fails as well!\n')
        % end
    end
    fprintf('Time step: %2d || Status: %s || Connection: %s || Loss: %.4f (MWh) || Shedding: %.4f (MWh) || Solution: %s\n',t,...
        system_status{x_s(1)+1},network_status{networked+1},value(obj_normal)*x_s(1), value(sum(p_load_up(:)))-sum(sum(LOAD.p_up(period_up,:))), solve_status );
    
    % ==================== lower level
    run input_data
    count_inside = 0;
    
    
    
    
    
    
    filename_prefix = 'result_dn_save'; % used for saving CSV file
    dn_save = cell(n_t_dn,1);
    for k = 1:n_t_dn
        % ==================== used for debug
        result_track.period_dn = (t-1)*n_t_dn + k;
        result_track.count = count;
        
        run input_data_sub_hourly
        tic
        % save result_now from_upper from_field from_sys agent_data load_data pv_data result_track net_load
        % run distributed_lower
        [ to_field, result_track ] = distributed_lower_function(from_upper, from_field, from_sys, agent_data, load_data, pv_data, result_track);
        
        result_dn.time(count,1) = toc;
        fprintf('\t Tracking step: %2d || Tracking error: %.6f || NMGs: %2d || Iters: %5d \n',k, abs(to_field.obj_dn), from_upper.n_nmg, max( result_track.iter(count,:) ) );
        % if field devices are added, the right-hand side value should be
        % read from field devices
        % as we currently do not include the real-time operation between two
        % consective tracking control, this value comes from the
        % previous tracking step.
        from_field.SOC_NEW_DN = to_field.soc_dn; 
        
        % save lower level result
        result_dn.iteration(count,1) = max( result_track.iter(count,:) );
        result_dn.obj(count,:) = to_field.obj_dn;
        result_dn.p_dg(count,:,:)  = to_field.p_dg_dn;

        result_dn.soc(count,:,:)  = to_field.soc_dn;
        result_dn.p_es_ch(count,:,:)  = to_field.p_es_ch_dn;
        result_dn.p_es_dis(count,:,:)  = to_field.p_es_dis_dn;
        
        result_dn.p_pv(count,:)  = to_field.p_pv_dn;

        result_dn.p_load(count,:,:)  = to_field.p_load_dn;
        result_dn.ls(count,:,:)  = round(result_dn.p_load(count,:,:)  - LOAD.p_dn(count,:,:),4);

        %% % output as CSV file
        % data_table = table(result_dn.p_dg(count,:,:), result_dn.soc(count,:,:), result_dn.p_es_ch(count,:,:), result_dn.p_es_dis(count,:,:), result_dn.p_pv(count,:), result_dn.p_load(count,:,:),...
        %     'VariableNames', {'p_dg', 'soc','p_es_ch', 'p_es_dis','p_pv', 'p_load'});
        % filename = [filename_prefix, '.csv'];
        % writetable(data_table, filename, 'WriteMode', 'overwrite');

        % collect data for DG and load
        data_table_la = table(result_dn.p_dg(count,:,:), result_dn.p_load(count,index_load_curtail,:));
        data_table_la = table2array(data_table_la);
        data_table_la = reshape(data_table_la, 972, 3);
        new_table_la = array2table(data_table_la, 'VariableNames', {'P1_kw','P2_kw','P3_kw'});
        empty_table = array2table(zeros(972, 6), 'VariableNames', {'P1_dis_kw','P2_dis_kw','P3_dis_kw','P1_soc_kwh','P2_soc_kwh','P3_soc_kwh'});
        new_table_la = [new_table_la, empty_table];

        % collect data for ESS
        data_table_lb = table(result_dn.p_es_ch(count,:,:), result_dn.p_es_dis(count,:,:), result_dn.soc(count,:,:));
        data_table_lb = table2array(data_table_lb);
        new_table_lb = reshape(data_table_lb, 13, 9);
        new_table_lb = array2table(new_table_lb, 'VariableNames', {'P1_kw','P2_kw','P3_kw', 'P1_dis_kw','P2_dis_kw','P3_dis_kw','P1_soc_kwh','P2_soc_kwh','P3_soc_kwh'});

        final_table_l=[new_table_la; new_table_lb];
        new_table = addvars(final_table_l, file_csv1(:, 1), file_csv1(:, 2), 'NewVariableNames', {'Bus Number', 'Type'},'Before', 1);

        new_table_dn = addvars(new_table, file_csv12(:, 1), file_csv12(:, 2), file_csv12(:, 3), 'NewVariableNames', {'sendStatus', 'writeTimeStampMatlab', 'sendTimeStamp'}, 'After', size(new_table, 2));
        new_table_dn.writeTimeStampMatlab = string(new_table_dn.writeTimeStampMatlab);
        current_time1 = datestr(datetime('now','TimeZone','local','InputFormat','yyyy-mm-dd HH:MM:SS'));
        current_time_dn = string(current_time1);
        for j=1:985
        new_table_dn{j, 13} = current_time_dn;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo
        %Add time steps and tracking steps for visualization
        timesteparray = t * ones(height(new_table_dn),1);
        new_table_dn = addvars(new_table_dn, timesteparray, 'NewVariableNames',{'TimeStep'});
        trackingsteparray = k * ones(height(new_table_dn),1);
        new_table_dn = addvars(new_table_dn, trackingsteparray, 'NewVariableNames',{'TrackingStep'});
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo

        %Write data to CSV file | Comment out for now because we are now using matlab to send data over modbus
        %writetable(new_table_dn, 'result_dn_save.csv', 'WriteMode', 'overwrite');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo
        %Write data to modbus
        %portNumbers = initModbusConnection(size(new_table_dn ,1));
        %writeDownDataToModbusServer(new_table_dn, portNumbers);
        %Write data to sql database
        dn_save{k} = new_table_dn;
        sqlwritetable = new_table_dn;
        sqlwritetable = renamevars(sqlwritetable, ["Bus Number"],["BusNumber"]);
        sqlwrite(conn, sqltabledn, sqlwritetable);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo
     %%
    
        count_inside = count_inside + 1;
        count = count + 1;
    end

    % save upper level result
filename_prefix_upper = 'result_up_save'; % used for saving CSV file
    if t == 1
        step_save_up = 1:count_inside;
    else
        step_save_up = length(result_up.sol)+1:length(result_up.sol)+count_inside;
    end

    result_up.sol(step_save_up,:) = sol_up.problem;
    result_up.obj(step_save_up,:) = value(obj_up);

    result_up.p_dg(step_save_up,:,:) = repmat(value(p_dg_up(1,:,:)),count_inside,1);
    result_up.q_dg(step_save_up,:,:) = repmat(value(q_dg_up(1,:,:)),count_inside,1);

    result_up.x_ch(step_save_up,:) = repmat(value(x_ch_up(1,:)),count_inside,1);
    result_up.x_dis(step_save_up,:) = repmat(value(x_dis_up(1,:)),count_inside,1);
    result_up.soc_pred(step_save_up,:,:) = repmat(value(soc_up(1,:,:)),count_inside,1);
    result_up.soc_actual(step_save_up,:,:) = repmat(reshape(from_field.SOC_NEW_DN,1,[],3),count_inside,1);
    
    result_up.p_es_ch(step_save_up,:,:) = repmat(value(p_es_ch_up(1,:,:)),count_inside,1);
    result_up.q_es_ch(step_save_up,:,:) = repmat(value(q_es_ch_up(1,:,:)),count_inside,1);
    result_up.p_es_dis(step_save_up,:,:) = repmat(value(p_es_dis_up(1,:,:)),count_inside,1);
    result_up.q_es_dis(step_save_up,:,:) = repmat(value(q_es_dis_up(1,:,:)),count_inside,1);

    result_up.x_br(step_save_up,:) = repmat(value(x_br_up(1,:)),count_inside,1);
    result_up.p_f(step_save_up,:,:) = repmat(value(p_f_up(1,:,:)),count_inside,1);
    result_up.q_f(step_save_up,:,:) = repmat(value(q_f_up(1,:,:)),count_inside,1);

    result_up.vm(step_save_up,:,:) = sqrt( repmat( value(vm_up(1,:,:)),count_inside,1 ) );

    result_up.p_pv(step_save_up,:) = repmat(value(p_pv_up(1,:)),count_inside,1);
    result_up.q_pv(step_save_up,:) = repmat(value(q_pv_up(1,:)),count_inside,1);

    result_up.p_load(step_save_up,:,:) = repmat(value(p_load_up(1,:,:)),count_inside,1);
    result_up.q_load(step_save_up,:,:) = repmat(value(q_load_up(1,:,:)),count_inside,1);
    
    index_critical = find(LOAD.priority==5 | LOAD.priority==4);
    result_up.ls(step_save_up,:,:) = round(result_up.p_load(step_save_up,:,:) - repmat(LOAD.p_up(t,:,:),count_inside,1),6);
    result_up.ls_critical = result_up.ls(:,index_critical,:);
    critical_alive = sum(result_up.ls_critical,3);
    fprintf('\t Critical alive hours: %d \n ', floor(sum(sum(critical_alive,2)>=0)/count_inside) );

     %% % output as CSV file
    % data_table2 = table(result_up.p_dg(step_save_up,:,:), result_up.q_dg(step_save_up,:,:), result_up.x_ch(step_save_up,:,:), result_up.x_dis(step_save_up,:,:), result_up.soc_pred(step_save_up,:,:), result_up.soc_actual(step_save_up,:,:),...
    %         result_up.p_es_ch(step_save_up,:,:), result_up.q_es_ch(step_save_up,:,:), result_up.p_es_dis(step_save_up,:,:), result_up.q_es_dis(step_save_up,:,:), result_up.p_pv(step_save_up,:), result_up.q_pv(step_save_up,:),...
    %         result_up.p_load(step_save_up,:,:), result_up.q_load(step_save_up,:,:),...
    %         'VariableNames', {'p_dg','q_dg', 'x_ch','x_dis', 'soc_pres', 'soc_actual','p_es_ch','q_es_ch', 'p_es_dis','q_es_dis','p_pv','q_pv', 'p_load', 'q_load'});
    % filename = [filename_prefix_upper, '.csv'];
    % writetable(data_table2, filename, 'WriteMode', 'overwrite');

        % collect data for DG and load
        % data_table_ua = table(result_up.p_dg(step_save_up,:,:), result_up.q_dg(step_save_up,:,:), result_up.p_load(step_save_up,index_load_curtail,:), result_up.q_load(step_save_up,index_load_curtail,:));
        data_table_ua1 = table(result_up.p_dg(step_save_up,:,:));
        data_table_ua1 = table2array(data_table_ua1);
        data_table_ua1 = reshape(data_table_ua1, [], 3);
        new_table_ua1 = array2table(data_table_ua1, 'VariableNames', {'P1_kw','P2_kw','P3_kw'});
        data_table_ua2 = table(result_up.q_dg(step_save_up,:,:));
        data_table_ua2 = table2array(data_table_ua2);
        data_table_ua2 = reshape(data_table_ua2, [], 3);
        new_table_ua2 = array2table(data_table_ua2, 'VariableNames', {'Q1_kvar','Q2_kvar','Q3_kvar'});
        C1 = [new_table_ua1, new_table_ua2];

        data_table_ua3 = table(result_up.p_load(step_save_up,index_load_curtail,:));
        data_table_ua3 = table2array(data_table_ua3);
        data_table_ua3 = reshape(data_table_ua3, [], 3);
        new_table_ua3 = array2table(data_table_ua3, 'VariableNames', {'P1_kw','P2_kw','P3_kw'});
        data_table_ua4 = table(result_up.q_load(step_save_up,index_load_curtail,:));
        data_table_ua4 = table2array(data_table_ua4);
        data_table_ua4 = reshape(data_table_ua4, [], 3);
        new_table_ua4 = array2table(data_table_ua4, 'VariableNames', {'Q1_kvar','Q2_kvar','Q3_kvar'});
        C2 = [new_table_ua3, new_table_ua4];

        C_dl = [C1; C2];
        empty_table_C_dl = array2table(zeros(3888, 12), 'VariableNames', {'P1_dis_kw','P2_dis_kw','P3_dis_kw','Q1_dis_kw','Q2_dis_kw','Q3_dis_kw','P1_soc_pred_kwh','P2_soc_pred_kwh','P3_soc_pred_kwh','P1_soc_act_kwh','P2_soc_act_kwh','P3_soc_act_kwh'});
        new_table_C_dl = [C_dl, empty_table_C_dl]; % 972*18
        
        % % collect data for ESS
        % data_table_ub1 = table(result_up.p_es_ch(step_save_up,:,:), result_up.q_es_ch(step_save_up,:,:), result_up.p_es_dis(step_save_up,:,:), result_up.q_es_dis(step_save_up,:,:),result_up.soc_pred(step_save_up,:,:), result_up.soc_actual(step_save_up,:,:));
        data_table_ub1 = table(result_up.p_es_ch(step_save_up,:,:));
        data_table_ub1 = table2array(data_table_ub1);
        data_table_ub1 = reshape(data_table_ub1, [], 3);
        new_table_ub1 = array2table(data_table_ub1, 'VariableNames', {'P1_kw','P2_kw','P3_kw'});

        data_table_ub2 = table(result_up.q_es_ch(step_save_up,:,:));
        data_table_ub2 = table2array(data_table_ub2);
        data_table_ub2 = reshape(data_table_ub2, [], 3);
        new_table_ub2 = array2table(data_table_ub2, 'VariableNames', {'Q1_kvar','Q2_kvar','Q3_kvar'});

        data_table_ub3 = table(result_up.p_es_dis(step_save_up,:,:));
        data_table_ub3 = table2array(data_table_ub3);
        data_table_ub3 = reshape(data_table_ub3, [], 3);
        new_table_ub3 = array2table(data_table_ub3, 'VariableNames', {'P1_dis_kw','P2_dis_kw','P3_dis_kw'});

        data_table_ub4 = table(result_up.q_es_dis(step_save_up,:,:));
        data_table_ub4 = table2array(data_table_ub4);
        data_table_ub4 = reshape(data_table_ub4, [], 3);
        new_table_ub4 = array2table(data_table_ub4, 'VariableNames', {'Q1_dis_kw','Q2_dis_kw','Q3_dis_kw'});

        data_table_ub5 = table(result_up.soc_pred(step_save_up,:,:));
        data_table_ub5 = table2array(data_table_ub5);
        data_table_ub5 = reshape(data_table_ub5, [], 3);
        new_table_ub5 = array2table(data_table_ub5, 'VariableNames', {'P1_soc_pred_kwh','P2_soc_pred_kwh','P3_soc_pred_kwh'});

        data_table_ub6 = table(result_up.soc_actual(step_save_up,:,:));
        data_table_ub6 = table2array(data_table_ub6);
        data_table_ub6 = reshape(data_table_ub6, [], 3);
        new_table_ub6 = array2table(data_table_ub6, 'VariableNames', {'P1_soc_act_kwh','P2_soc_act_kwh','P3_soc_act_kwh'});

        C_es = [new_table_ub1, new_table_ub2, new_table_ub3, new_table_ub4, new_table_ub5, new_table_ub6];

        final_table_up=[new_table_C_dl; C_es];
        new_table_up = addvars(final_table_up, file_csv2(:, 1), file_csv2(:, 2), 'NewVariableNames', {'Bus Number', 'Type'},'Before', 1);

        new_table_up_2 = addvars(new_table_up, file_csv22(:, 1), file_csv22(:, 2), file_csv22(:, 3), 'NewVariableNames', {'sendStatus', 'writeTimeStampMatlab', 'sendTimeStamp'}, 'After', size(new_table_up, 2));
        new_table_up_2.writeTimeStampMatlab = string(new_table_up_2.writeTimeStampMatlab);
        current_time_up = datestr(datetime('now','TimeZone','local','InputFormat','yyyy-mm-dd HH:MM:SS'));
        current_time_up = string(current_time_up);
        for j=1:3940
           new_table_up_2{j, 22} = current_time_up;
        end
        indices = 1:4:3937; 

        groupData = new_table_up_2(indices, :);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo
        %Add time steps for visualization
        timesteparray = t * ones(height(groupData),1);
        groupData = addvars(groupData, timesteparray, 'NewVariableNames',{'TimeStep'});
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo

        %Write data to CSV file | Comment out for now because we are now using matlab to send data over modbus
        %writetable(new_table_up_2, 'result_up_save.csv', 'WriteMode', 'overwrite');
        %writetable(groupData, 'result_up_save.csv', 'WriteMode', 'overwrite');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo
        %Write data to modbus
        %portNumbers = initModbusConnection(size(groupData ,1));
        %writeUpDataToModbusServer(groupData, portNumbers);
        %Write data to SQL database
        sqlwritetable = groupData;
        sqlwritetable = renamevars(sqlwritetable, ["Bus Number"],["BusNumber"]);
        sqlwrite(conn, sqltableup, sqlwritetable);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Begin Bodo

        for i = 1:length(dn_save)
            modbusWriteTable = table();
            modbusWriteTable.BusNumber = sqlwritetable.BusNumber;
            modbusWriteTable.Type = sqlwritetable.Type;
            modbusWriteTable.TimeStep = dn_save{i}.TimeStep;
            modbusWriteTable.TrackingStep = dn_save{i}.TrackingStep;
            modbusWriteTable.P1_kw = dn_save{i}.P1_kw;
            modbusWriteTable.P2_kw = dn_save{i}.P2_kw;
            modbusWriteTable.P3_kw = dn_save{i}.P3_kw;
            modbusWriteTable.P1_dis_kw = dn_save{i}.P1_dis_kw;
            modbusWriteTable.P2_dis_kw = dn_save{i}.P2_dis_kw;
            modbusWriteTable.P3_dis_kw = dn_save{i}.P3_dis_kw;
            modbusWriteTable.P1_soc_kwh = dn_save{i}.P1_soc_kwh;
            modbusWriteTable.P2_soc_kwh = dn_save{i}.P2_soc_kwh;
            modbusWriteTable.P3_soc_kwh = dn_save{i}.P3_soc_kwh;
            modbusWriteTable.Q1_kvar = sqlwritetable.Q1_kvar;
            modbusWriteTable.Q2_kvar = sqlwritetable.Q2_kvar;
            modbusWriteTable.Q3_kvar = sqlwritetable.Q3_kvar;
            modbusWriteTable.Q1_dis_kw = sqlwritetable.Q1_dis_kw;
            modbusWriteTable.Q2_dis_kw = sqlwritetable.Q2_dis_kw;
            modbusWriteTable.Q3_dis_kw = sqlwritetable.Q3_dis_kw;
            modbusWriteTable.P1_soc_pred_kwh = sqlwritetable.P1_soc_pred_kwh;
            modbusWriteTable.P2_soc_pred_kwh = sqlwritetable.P2_soc_pred_kwh;
            modbusWriteTable.P3_soc_pred_kwh = sqlwritetable.P3_soc_pred_kwh;
            modbusWriteTable.P1_soc_act_kwh = sqlwritetable.P1_soc_act_kwh;
            modbusWriteTable.P2_soc_act_kwh = sqlwritetable.P2_soc_act_kwh;
            modbusWriteTable.P3_soc_act_kwh = sqlwritetable.P3_soc_act_kwh;

            %Write data to sql database
            sqlwrite(conn, sqltableall, modbusWriteTable);
            
            %Write data to modbus
            %portNumbers = initModbusConnection(size(modbusWriteTable ,1));
            writeDataToModbusServer(modbusWriteTable, portNumbers);

            disp(['Data from Time Step ', num2str(t), ' Tracking Step ', num2str(i), ' successfully written to SQL database and Modbus server']);
            pause(100);

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End Bodo

     %%  
end
fprintf('\t Runtime: %ss\n', num2str(toc(t_start)));

% output as CSV file
% data_table2 = table();
% data_table2.p_dg = [result_up.p_dg];data_table2.q_dg = [result_up.q_dg];
% data_table2.x_ch = [result_up.x_ch];data_table2.x_dis = [result_up.x_dis];
% data_table2.soc_pred = [result_up.soc_pred];data_table2.soc_actual = [result_up.soc_actual];
% data_table2.p_es_ch = [result_up.p_es_ch];data_table2.q_es_ch = [result_up.q_es_ch];
% data_table2.p_es_dis = [result_up.p_es_dis];data_table2.q_es_dis = [result_up.q_es_dis];
% data_table2.p_pv = [result_up.p_pv];data_table2.q_pv = [result_up.q_pv];
% data_table2.p_load = [result_up.p_load];data_table2.q_load = [result_up.q_load];
% storename2 = 'result_up.csv';
% writetable(data_table2, storename2);

% ================ save results
% =========== can be removed
yalmip('clear')
result_name = ['result_all_dis_',num2str(x_s(1)),'_',num2str(networked)];
path_save = fullfile(pwd, file_result, result_name);
save(path_save)
if isfile([path_save,'.txt']) == 0
    fopen([path_save,'.txt'],'w');
    fclose('all');
end
stop = 1;