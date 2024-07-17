fprintf('-----------====== MILP Formulating - Upper level ======----------------------\n');

%% Variables
p_dg_up = sdpvar(n_t_up, n_dg, n_phase,'full');
q_dg_up = sdpvar(n_t_up, n_dg, n_phase,'full');
p_dg_pre_up = sdpvar(1, n_local_dg, n_phase,'full');

x_ch_up = binvar(n_t_up, n_es, 'full');
x_dis_up = binvar(n_t_up, n_es, 'full');
soc_up = sdpvar(n_t_up, n_es, n_phase, 'full');
p_es_ch_up = sdpvar(n_t_up, n_es, n_phase, 'full');
q_es_ch_up = sdpvar(n_t_up, n_es, n_phase, 'full');
p_es_dis_up = sdpvar(n_t_up, n_es, n_phase, 'full');
q_es_dis_up = sdpvar(n_t_up, n_es, n_phase, 'full');
p_es_ch_pre_up = sdpvar(1, n_es, n_phase, 'full');
p_es_dis_pre_up = sdpvar(1, n_es, n_phase, 'full');

%x_br_up = binvar(n_t_up, n_bra, 'full');
x_br_up1 = binvar(n_t_up, n_bra, 'full');
x_br_up  = ones(n_t_up, n_bra)-x_br_up1;
%x_br_up = ones(n_t_up, n_bra);
p_f_up = sdpvar(n_t_up,n_bra, n_phase, 'full');
q_f_up = sdpvar(n_t_up,n_bra, n_phase, 'full');

vm_up = sdpvar(n_t_up, n_node, n_phase, 'full');

% ================= updated hourly
p_pv_up = sdpvar(n_t_up, n_pv, 'full');
q_pv_up = sdpvar(n_t_up, n_pv, 'full');
p_load_up = sdpvar(n_t_up, n_load, n_phase, 'full');
q_load_up = sdpvar(n_t_up, n_load, n_phase, 'full');
soc_pre_up = sdpvar(1, n_es, n_phase, 'full');


%%  Constraints
con_up = [];
% ================= power flow constraints
con_up = con_up + [[ (p_es_dis_up(:,:,1) - p_es_ch_up(:,:,1))*M_ES_NODE + p_pv_up/n_phase*M_PV_NODE + ...
                      p_dg_up(:,:,1)*M_DG_NODE + p_load_up(:,:,1)*M_LOAD_NODE + p_f_up(:,:,1)*M_BRA_NODE == 0 ]:'p_balance_A'];
					
con_up = con_up + [[ (p_es_dis_up(:,:,2) - p_es_ch_up(:,:,2))*M_ES_NODE + p_pv_up/n_phase*M_PV_NODE + ...
                      p_dg_up(:,:,2)*M_DG_NODE + p_load_up(:,:,2)*M_LOAD_NODE + p_f_up(:,:,2)*M_BRA_NODE == 0 ]:'p_balance_B'];
					
con_up = con_up + [[ (p_es_dis_up(:,:,3) - p_es_ch_up(:,:,3))*M_ES_NODE + p_pv_up/n_phase*M_PV_NODE + ...
                      p_dg_up(:,:,3)*M_DG_NODE + p_load_up(:,:,3)*M_LOAD_NODE + p_f_up(:,:,3)*M_BRA_NODE == 0 ]:'p_balance_C'];

con_up = con_up + [[ (q_es_dis_up(:,:,1) - q_es_ch_up(:,:,1))*M_ES_NODE + q_pv_up/n_phase*M_PV_NODE + ...
                      q_dg_up(:,:,1)*M_DG_NODE + q_load_up(:,:,1)*M_LOAD_NODE + q_f_up(:,:,1)*M_BRA_NODE == 0 ]:'q_balance_A'];
					
con_up = con_up + [[ (q_es_dis_up(:,:,2) - q_es_ch_up(:,:,2))*M_ES_NODE + q_pv_up/n_phase*M_PV_NODE + ...
                      q_dg_up(:,:,2)*M_DG_NODE + q_load_up(:,:,2)*M_LOAD_NODE + q_f_up(:,:,2)*M_BRA_NODE == 0 ]:'q_balance_B'];
					
con_up = con_up + [[ (q_es_dis_up(:,:,3) - q_es_ch_up(:,:,3))*M_ES_NODE + q_pv_up/n_phase*M_PV_NODE + ...
                      q_dg_up(:,:,3)*M_DG_NODE + q_load_up(:,:,3)*M_LOAD_NODE + q_f_up(:,:,3)*M_BRA_NODE == 0 ]:'q_balance_C'];

% satisfies_condition = zeros(n_bra, 1);

for i = 1:n_bra
    nfrom = BRA.nfrom(i); 
    nto = BRA.nto(i); 
    phase = BRA.phase(i,:);

    ZZ = diag(phase)*Z(3*nfrom-2:3*nfrom, 3*nto-2:3*nto);
    RR = real(ZZ)/5; 
    XX = imag(ZZ)/5; 

    a_ratio = [ 1; exp(1i*-120/180*pi); exp(1i*120/180*pi) ];
    Requal = real(a_ratio*a_ratio').*RR + imag(a_ratio*a_ratio').*XX;
    Xequal = real(a_ratio*a_ratio').*XX - imag(a_ratio*a_ratio').*RR;

    Vf2 = [ vm_up(:,nfrom,1)'; vm_up(:,nfrom,2)'; vm_up(:,nfrom,3)' ];
    Vt2 = [ vm_up(:,nto,1)';   vm_up(:,nto,2)';   vm_up(:,nto,3)' ];

    Pft = [ p_f_up(:,i,1)'; p_f_up(:,i,2)'; p_f_up(:,i,3)' ];
    Qft = [ q_f_up(:,i,1)'; q_f_up(:,i,2)'; q_f_up(:,i,3)' ];

    %con_up = con_up + [[ -M*(1-repmat(x_br_up(:,i)',3,1)) <= Vt2 - Vf2 + 2*(Requal*Pft + Xequal*Qft) <= M*(1-repmat(x_br_up(:,i)',3,1)) ]:'Dist'];
  con_up = con_up + [[ Vt2 - Vf2 + 2*(Requal*Pft + Xequal*Qft) <= M*(1-repmat(x_br_up(:,i)',3,1)) ]:'Dist'];
  con_up = con_up + [[ Vt2 - Vf2 + 2*(Requal*Pft + Xequal*Qft) >= -M*(repmat(x_br_up(:,i)',3,1)) ]:'Dist'];
  % 
  % matrix_result = sum(value(Vt2 - Vf2 + 2 * (Requal * Pft + Xequal * Qft)));
  % if matrix_result<0
  %  satisfies_condition(i) = i; 
  % else 
  %  satisfies_condition(i) = 0; 
  % end
end

% indices_satisfying_condition = find(satisfies_condition);
% disp('支路满足条件的索引：');
% disp(indices_satisfying_condition);

% ================= energy storage
% ======= SOC contraints
t_pre = 1:n_t_up-1;
t_now = 2:n_t_up;
effi = 0.98;
con_up = con_up + [[ soc_up(1,:,1) == soc_pre_up(1,:,1) + (effi*p_es_ch_up(1,:,1) - p_es_dis_up(1,:,1)/effi)*delt_t_up ]:'soc_1']; % t = 1
con_up = con_up + [[ soc_up(1,:,2) == soc_pre_up(1,:,2) + (effi*p_es_ch_up(1,:,2) - p_es_dis_up(1,:,2)/effi)*delt_t_up ]:'soc_1']; % t = 1 
con_up = con_up + [[ soc_up(1,:,3) == soc_pre_up(1,:,3) + (effi*p_es_ch_up(1,:,3) - p_es_dis_up(1,:,3)/effi)*delt_t_up ]:'soc_1']; % t = 1 
 
con_up = con_up + [[ soc_up(t_now,:,1) == soc_up(t_pre,:,1) + (effi*p_es_ch_up(t_now,:,1) - p_es_dis_up(t_now,:,1)/effi)*delt_t_up ]:'soc_2_T']; % t = [2,T]
con_up = con_up + [[ soc_up(t_now,:,2) == soc_up(t_pre,:,2) + (effi*p_es_ch_up(t_now,:,2) - p_es_dis_up(t_now,:,2)/effi)*delt_t_up ]:'soc_2_T']; % t = [2,T]
con_up = con_up + [[ soc_up(t_now,:,3) == soc_up(t_pre,:,3) + (effi*p_es_ch_up(t_now,:,3) - p_es_dis_up(t_now,:,3)/effi)*delt_t_up ]:'soc_2_T']; % t = [2,T]

con_up = con_up + [[ repmat(ES.e_min',n_t_up,1,3) <= soc_up <= repmat(ES.e_max',n_t_up,1,3) ]:'soc_range'];

% ======= charge/discharge 
con_up = con_up + [[ 0 <= p_es_ch_up ]:'p_es_ch_range_lb'];
con_up = con_up + [[ p_es_ch_up <= repmat(ES.p_max',n_t_up,1,3).*repmat(x_ch_up,1,1,3) ]:'p_es_ch_range_ub'];

con_up = con_up + [[ 0 <= p_es_dis_up ]:'p_es_dis_range_lb'];
con_up = con_up + [[ p_es_dis_up <= repmat(ES.p_max',n_t_up,1,3).*repmat(x_dis_up,1,1,3) ]:'p_es_dis_range_ub'];

con_up = con_up + [[ q_es_ch_up == 0, q_es_dis_up == 0]:'q_es'];

% ======= ramping
t_pre = 1:n_t_up-1;
t_now = 2:n_t_up;
% % time = 1
% con_up = con_up + [[ -ES.ramp' - (1-x_ch_up(1,:))*M <= p_es_ch_up(1,:) - p_es_ch_pre_up <= ES.ramp' + (1-x_ch_up(1,:))*M  ]:'p_es_ch_ramp_1'];
% con_up = con_up + [[ -ES.ramp' - (1-x_dis_up(1,:))*M <= p_es_dis_up(1,:) - p_es_dis_pre_up <= ES.ramp' + (1-x_dis_up(1,:))*M ]:'p_es_dis_ramp_'];
% % time = [2,T]
% con_up = con_up + [[ -repmat(ES.ramp',n_t_up-1,1) - (1-x_ch_up(t_now,:))*M <= p_es_ch_up(t_now,:) - p_es_ch_up(t_pre,:) <= repmat(ES.ramp',n_t_up-1,1) + (1-x_ch_up(t_now,:))*M ]:'p_es_ch_ramp_2_T'];
% con_up = con_up + [[ -repmat(ES.ramp',n_t_up-1,1) - (1-x_dis_up(t_now,:))*M <= p_es_dis_up(t_now,:) - p_es_dis_up(t_pre,:) <= repmat(ES.ramp',n_t_up-1,1) + (1-x_dis_up(t_now,:))*M ]:'p_es_dis_ramp_2_T'];

% as the ramping rate of ess equals its max output, we can use the following constraints
% otherwise, use the aboved,
% time = 1
con_up = con_up + [[ -repmat(ES.ramp',1,1,3) <= p_es_ch_up(1,:,:) - p_es_ch_pre_up <= repmat(ES.ramp',1,1,3) ]:'p_es_ch_ramp_1'];
con_up = con_up + [[ -repmat(ES.ramp',1,1,3) <= p_es_dis_up(1,:,:) - p_es_dis_pre_up <= repmat(ES.ramp',1,1,3) ]:'p_es_dis_ramp_'];
% time = [2,T]
con_up = con_up + [[ -repmat(ES.ramp',n_t_up-1,1,3) <= p_es_ch_up(t_now,:,:) - p_es_ch_up(t_pre,:,:) <= repmat(ES.ramp',n_t_up-1,1,3) ]:'p_es_ch_ramp_2_T'];
con_up = con_up + [[ -repmat(ES.ramp',n_t_up-1,1,3) <= p_es_dis_up(t_now,:,:) - p_es_dis_up(t_pre,:,:) <= repmat(ES.ramp',n_t_up-1,1,3) ]:'p_es_dis_ramp_2_T'];

% ================= voltage magnitude
con_up = con_up + [[ V_MIN*V_MIN <= vm_up <= V_MAX*V_MAX ]:'v_range'];

% ================= line capacity
con_up = con_up + [[ -F_MAX.*x_br_up <= p_f_up(:,:,1) <= F_MAX.*x_br_up ]:'pf_range_A'];
con_up = con_up + [[ -F_MAX.*x_br_up <= p_f_up(:,:,2) <= F_MAX.*x_br_up ]:'pf_range_B'];
con_up = con_up + [[ -F_MAX.*x_br_up <= p_f_up(:,:,3) <= F_MAX.*x_br_up ]:'pf_range_C'];

% con_up = con_up + [[ -F_MAX.*x_br_up <= sum(p_f_up,3) <=  F_MAX.*x_br_up ]:'pf_range_sum'];

con_up = con_up + [[ -F_MAX.*x_br_up <= q_f_up(:,:,1) <= F_MAX.*x_br_up ]:'qf_range_A'];
con_up = con_up + [[ -F_MAX.*x_br_up <= q_f_up(:,:,2) <= F_MAX.*x_br_up ]:'qf_range_B'];
con_up = con_up + [[ -F_MAX.*x_br_up <= q_f_up(:,:,3) <= F_MAX.*x_br_up ]:'qf_range_C'];

% con_up = con_up + [[ -F_MAX.*x_br_up <= sum(q_f_up,3) <= F_MAX.*x_br_up ]:'qf_range_sum'];

for tt = 1:n_t_up
    con_up = con_up + [[ -F_MAX*BRA.phase <= p_f_up(tt,:,:) <=  F_MAX*BRA.phase ]:'pf_phase'];
    con_up = con_up + [[ -F_MAX*BRA.phase <= q_f_up(tt,:,:) <=  F_MAX*BRA.phase ]:'qf_phase'];
end

% ================= Local DG output
n_polygon = 6;
s_polygon = repmat(DG.p_max(index_dg_local)',n_t_up,1) * sqrt( (2*pi/n_polygon) / sin(2*pi/n_polygon) );
con_up = con_up + [ -sqrt(3)*(p_dg_up(:,index_dg_local,1) + s_polygon) <= q_dg_up(:,index_dg_local,1) <= -sqrt(3)*(p_dg_up(:,index_dg_local,1) - s_polygon) ];
con_up = con_up + [ -sqrt(3)*(p_dg_up(:,index_dg_local,2) + s_polygon) <= q_dg_up(:,index_dg_local,2) <= -sqrt(3)*(p_dg_up(:,index_dg_local,2) - s_polygon) ];
con_up = con_up + [ -sqrt(3)*(p_dg_up(:,index_dg_local,3) + s_polygon) <= q_dg_up(:,index_dg_local,3) <= -sqrt(3)*(p_dg_up(:,index_dg_local,3) - s_polygon) ];

con_up = con_up + [ -sqrt(3)/2*s_polygon <= q_dg_up(:,index_dg_local,1) <= sqrt(3)/2*s_polygon ] ;
con_up = con_up + [ -sqrt(3)/2*s_polygon <= q_dg_up(:,index_dg_local,2) <= sqrt(3)/2*s_polygon ] ;
con_up = con_up + [ -sqrt(3)/2*s_polygon <= q_dg_up(:,index_dg_local,3) <= sqrt(3)/2*s_polygon ] ;

con_up = con_up + [ sqrt(3)*(p_dg_up(:,index_dg_local,1) - s_polygon) <= q_dg_up(:,index_dg_local,1) <= sqrt(3)*(p_dg_up(:,index_dg_local,1) + s_polygon) ];
con_up = con_up + [ sqrt(3)*(p_dg_up(:,index_dg_local,2) - s_polygon) <= q_dg_up(:,index_dg_local,2) <= sqrt(3)*(p_dg_up(:,index_dg_local,2) + s_polygon) ];
con_up = con_up + [ sqrt(3)*(p_dg_up(:,index_dg_local,3) - s_polygon) <= q_dg_up(:,index_dg_local,3) <= sqrt(3)*(p_dg_up(:,index_dg_local,3) + s_polygon) ];
