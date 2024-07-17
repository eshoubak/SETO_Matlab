%% ======================================== input from system
% ================ constant value
from_sys.n_phase = n_phase; % total number of phases
from_sys.n_agent = n_agent; % total number of agents

from_sys.error_estimation = 1e-8; % can be changed based on the requirements
from_sys.error_constraint = 1e-8; % can be changed based on the requirements
%from_sys.error_consensus = 1e-12; % can be changed based on the requirements
from_sys.error_consensus = 1e-6; % can be changed based on the requirements

from_sys.n_alpha = 170; %100, 150
from_sys.n_iter = 20000;

from_sys.delt_t_dn = delt_t_dn;


%% ======================================== input from upper level
% ================ updated hourly
% the following code is used to denote how all microgrids are networked
connect = [];
connect(:,1) = BRA.nfrom;
connect(:,2) = BRA.nto;
%x_br_up=zeros(24, 2670);
line_status = round(value(x_br_up(1,:)));
connect(line_status==0,:) = [];
G = graph(connect(:,1),connect(:,2));
nmg_bins = conncomp(G)';
n_nmg = length(unique(nmg_bins)); % number of networed microgrids

% from_upper.nmg_bins = nmg_bins;
from_upper.n_nmg = n_nmg;
from_upper.W = zeros(n_agent,n_agent);

% Generate the updated communication network considering all NMGs
for nmg_index = 1:n_nmg
    nmg_node = nmg_bins==nmg_index;
    nmg_agent_index = find(nmg_node(agent_data(:,1))==true);
    
    nmg_agent_outside = 1:n_agent;
    nmg_agent_outside(nmg_agent_index) = [];
    
    A_nmg = A_original;
    A_nmg(nmg_agent_outside,:) = 0;
    A_nmg(:,nmg_agent_outside) = 0;
    
    D_nmg = diag(sum(A_nmg,2));
    L_nmg = D_nmg - A_nmg;
    
    % new W for current nmg
    % note that alpha is calculated based on the original W
    W_nmg = eye(size(A_nmg,1)) - 1 * alpha * L_nmg;
    W_nmg(W_nmg==1) = 0; % The value of agents outside of current nmg
    from_upper.W(nmg_agent_index,:) = W_nmg(nmg_agent_index,:); % update W related to current nmg   
end

% ============ For RTDS
from_upper.x_br_up = round(value(x_br_up(1,:))); % line/switch connection status

from_upper.q_es_up = value(q_es_dis_up(1,:,:) - q_es_ch_up(1,:,:)); % reactive power of energy storage. Zero now
from_upper.q_dg_up = value(q_dg_up(1,:,:) ); % reactive power of DG
from_upper.q_load_up = value(q_load_up(1,:,:) ); % reactive power of Load
from_upper.q_pv_up = value(q_pv_up(1,:) ); % reactive power of PV

from_upper.p_ref_es = value(p_es_dis_up(1,:,:) - p_es_ch_up(1,:,:));  % setpoint for energy storage
from_upper.p_ref_dg = value(p_dg_up(1,:,:)); % setpoint for DG (PCC and local DG)
from_upper.p_ref_load = value(p_load_up(1,index_load_curtail,:)); % setpoint for loads

% from_upper.SOC_NEW_DN = reshape(SOC_NEW_UP,[],n_phase); % SOC
% ============ For lower-level
% note that p_ref integrates p_ref_es, p_ref_dg, and p_ref_load
from_upper.p_ref = zeros(n_agent,n_phase);
from_upper.p_ref(agent_index_es,:) = reshape(value(p_es_dis_up(1,:,:) - p_es_ch_up(1,:,:)),[],n_phase);
from_upper.p_ref(agent_index_dg,:) = reshape(value(p_dg_up(1,:,:)),[],n_phase);
from_upper.p_ref(agent_index_load,:) = reshape(value(p_load_up(1,index_load_curtail,:)),[],n_phase);

%% ======================================== input from field device
from_field.SOC_NEW_DN = reshape(SOC_NEW_UP,[],n_phase);


%%  ========================================== agent data
% ================== ESS
agent_data(agent_index_es,10:12) = from_upper.p_ref(agent_index_es,:); % p_ref_a,b,c
agent_data(agent_index_es,20) = nmg_bins(agent_data(agent_index_es,1)); % nmg

% ================== DG
agent_data(agent_index_dg,10:12) = from_upper.p_ref(agent_index_dg,:); % p_ref_a,b,c
agent_data(agent_index_dg,20) = nmg_bins(agent_data(agent_index_dg,1)); % nmg

% ================== Load
agent_data(agent_index_load,10:12) = from_upper.p_ref(agent_index_load,:); % p_ref_a,b,c
agent_data(agent_index_load,20) = nmg_bins(agent_data(agent_index_load,1)); % nmg

for i = 1:n_agent
    nmg_index = agent_data(i,20);
    n_agent_nmg = length(find(agent_data(:,20)==nmg_index));
    agent_data(i,21) = n_agent_nmg; % the number of agents in each nmg. Note that this is different from n_agent
    
    % parameter "tao" for distributed algorithm
    % larger value causes divergence
    % smaller value redcues convergence speed
    agent_data(:,25) = min( 1.0 / n_agent_nmg, 0.3 ); % tao, 5.0 to 1.0
end


%% ============================= time-dependent load and PV data
load_data(:,1) = LOAD.node(index_load_noncurtail);
load_data(:,2) = nmg_bins(load_data(:,1)); % the nmg index where load j belongs

pv_data(:,1) = PV.node;
pv_data(:,2) = nmg_bins(pv_data(:,1)); % the nmg index where pv j belongs

stop = 1;