%%  ========================================== constant agent data
% may need to revise this value if the distributed algorithm can not converge
rho = 0.05; 

agent_bus = [ ES.node; DG.node; LOAD.node(index_load_curtail) ];
n_agent = length(agent_bus);

agent_type_es = 1;
agent_type_pcc = 2;
agent_type_local_DG = 3;
agent_type_load = 4;

agent_index_es(:,1) = 1:n_es;
agent_index_dg(:,1) = n_es+1:n_es+n_dg;
agent_index_load(:,1) = n_es+n_dg+1:n_agent;

agent_data = zeros(n_agent,25);
% 1     2	3       4       5       6       7       8       9       10
% node	AA	type	p_max_a	p_max_b	p_max_c	p_min_a	p_min_b	p_min_c	p_ref_a
% 11        12      13      14      15      16  17      18	19	20
% p_ref_b	p_ref_c	soc_max	soc_min	soc_ini	coe	coe_a	rho	mg	nmg
% 21            22          23          24          25
% n_nmg_agent	net_load_a	net_load_b	net_load_c	tao
% the definition of each column can also be found in the spreadsheet "inputs_outputs"
% ================== ESS
agent_data(agent_index_es,1) = ES.node;
agent_data(agent_index_es,2) = 1;
agent_data(agent_index_es,3) = agent_type_es;
agent_data(agent_index_es,4:6) = repmat(ES.p_max,1,3);
agent_data(agent_index_es,7:9) = -repmat(ES.p_max,1,3);
agent_data(agent_index_es,13:15) = [ES.e_max ES.e_min ES.e_ini];
agent_data(agent_index_es,16) = 1.0*1/n_es*ones(n_es,1);
agent_data(agent_index_es,17) = 1.0 .* agent_data(agent_index_es,16);
agent_data(agent_index_es,18) = rho*0.1;
agent_data(agent_index_es,19) = ES.mg;


% ================== DG
agent_data(agent_index_dg,1) = DG.node;
agent_data(agent_index_dg,2) = 1;
agent_data(agent_index_dg,3) = agent_type_local_DG;
agent_data(agent_index_dg,4:6) = repmat(DG.p_max,1,3);
agent_data(agent_index_dg,7:9) = -repmat(DG.p_max,1,3)*0;
agent_data(agent_index_dg,13:15) = 0;
agent_data(agent_index_dg,16) = 1*ones(n_dg,1);
agent_data(agent_index_dg,18) = rho*0.1;
agent_data(agent_index_dg,19) = DG.mg;

% ================== PCC
agent_data(n_es+1:n_es+n_pcc,3) = agent_type_pcc;
% agent_data(n_es+1:n_es+n_pcc,4:6) = agent_data(n_es+1:n_es+n_pcc,2:4)*x_s(1);
agent_data(n_es+1:n_es+n_pcc,16) = 0.5/n_pcc*agent_data(n_es+1:n_es+n_pcc,16);
% ================== Local DG
agent_data(n_es+n_pcc+1:n_es+n_pcc+n_local_dg,16) = 0.1/n_local_dg*agent_data(n_es+n_pcc+1:n_es+n_pcc+n_local_dg,16);

agent_data(agent_index_dg,17) = 1.0 .* agent_data(agent_index_dg,16);

% ================== Load
agent_data(agent_index_load,1) = LOAD.node(index_load_curtail);
agent_data(agent_index_load,2) = -1;
agent_data(agent_index_load,3) = agent_type_load;
% agent_data(agent_index_load,4:6) = reshape(LOAD.p_dn((t-1)*n_t_dn + k,index_load_curtail,:),[],n_phase);
% agent_data(agent_index_load,7:9) = reshape(LOAD.p_dn((t-1)*n_t_dn + k,index_load_curtail,:),[],n_phase)*x_s(1);
agent_data(agent_index_load,13:15) = 0;
agent_data(agent_index_load,16) = 1.0/n_load*ones(n_load_curtail,1);
agent_data(agent_index_load,17) = 1.0 .* agent_data(agent_index_load,16);
agent_data(agent_index_load,18) = rho;
agent_data(agent_index_load,19) = LOAD.mg(index_load_curtail);