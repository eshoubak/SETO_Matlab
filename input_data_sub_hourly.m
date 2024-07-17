%% ======================================== input from field device
% denote the system status
% used to trigger the early stop of lower level and switch objective function of upper level
from_field.x_s = x_s;


%%  ========================================== agent data
% the definition of each column can also be found in the spreadsheet "inputs_outputs"
% or distributed_agent_data.m file
% ================== PCC
agent_data(n_es+1:n_es+n_pcc,4:6) = agent_data(n_es+1:n_es+n_pcc,2:4)*from_field.x_s(1); % max power 

% ================== Load
agent_data(agent_index_load,4:6) = reshape(LOAD.p_dn((t-1)*n_t_dn + k,index_load_curtail,:),[],n_phase); % max power
agent_data(agent_index_load,7:9) = reshape(LOAD.p_dn((t-1)*n_t_dn + k,index_load_curtail,:),[],n_phase)*from_field.x_s(1); % min power


%% ============================= time-dependent load, PV, and net-load data
% 1     2   3   4   5
% node	nmg	p_a	p_b	p_c
load_data(:,3:5) = reshape(LOAD.p_dn((t-1)*n_t_dn + k,index_load_noncurtail,:),[],n_phase);

% 1     2   3
% node	nmg	p
pv_data(:,3) = PV.p_max_dn((t-1)*n_t_dn + k,:,:);

net_load = zeros(n_nmg,n_phase);
for nmg_index = 1:n_nmg
    index_load = load_data(:,2)==nmg_index;
    index_pv = pv_data(:,2)==nmg_index;
    
    net_load(nmg_index,:) = sum(load_data(index_load,3:5),1) - sum(pv_data(index_pv,3),1)/3;
    index = agent_data(:,20) == nmg_index;
    agent_data(index,22:24) = repmat(net_load(nmg_index,:),sum(index),1); % net load
end

stop = 1;
