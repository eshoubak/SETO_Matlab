%% ================================= update constraint 
period_up = t:t+n_t_up-1;
con_up_update = [];

% ========= switch
con_up_update = con_up_update + [[ x_br_up(:,index_nonswitch) == OUTAGE_BRA(:,index_nonswitch) ]:'non_switch'];
con_up_update = con_up_update + [[ x_br_up(:,index_switch) <= networked ]:'switch'];

% ========= load curtailment
if x_s(1) == 1 % normal condition
    con_up_update = con_up_update + [[ p_load_up == LOAD.p_up(period_up,:,:) ]:'p_load'];
    con_up_update = con_up_update + [[ q_load_up == LOAD.q_up(period_up,:,:) ]:'q_load'];
else % emergency condition
    con_up_update = con_up_update + [[ p_load_up(:,index_load_noncurtail,:) == LOAD.p_up(period_up,index_load_noncurtail,:) ]:'p_load_noncurtail'];
    con_up_update = con_up_update + [[ q_load_up(:,index_load_noncurtail,:) == LOAD.q_up(period_up,index_load_noncurtail,:) ]:'q_load_noncurtail'];

    con_up_update = con_up_update + [[ 0 < p_load_up(:,index_load_curtail,:) <= LOAD.p_up(period_up,index_load_curtail,:) ]:'p_load_curtail'];
    if value(LOAD.q_up(period_up,index_load_curtail,:))>=0
    con_up_update = con_up_update + [[ 0 <= q_load_up(:,index_load_curtail,:) <= LOAD.q_up(period_up,index_load_curtail,:) ]:'q_load_curtail'];
    else
    %con_up_update = con_up_update + [[ q_load_up(:,index_load_curtail,:) <= LOAD.q_up(period_up,index_load_curtail,:) ]:'q_load_curtail'];
    con_up_update = con_up_update + [[ LOAD.q_up(period_up,index_load_curtail,:) <= q_load_up(:,index_load_curtail,:) ]:'q_load_curtail'];
    end
    % con_up_update = con_up_update + [[ p_load_up == LOAD.p_up(period_up,:,:) ]:'p_load'];
    % con_up_update = con_up_update + [[ q_load_up == LOAD.q_up(period_up,:,:) ]:'q_load'];
end

% ================================== DG
% =================== PCC
con_up_update = con_up_update + [[ 0 <= p_dg_up(:,index_dg_pcc,:) <= repmat(DG.p_max(index_dg_pcc)'.*x_s',n_t_up,1,3) ]:'p_dg_pcc'];
con_up_update = con_up_update + [[ -repmat(DG.q_max(index_dg_pcc)'.*x_s',n_t_up,1,3) <= q_dg_up(:,index_dg_pcc,:) <= repmat(DG.q_max(index_dg_pcc)'.*x_s',n_t_up,1,3) ]:'q_dg_pcc'];
if x_s(1) == 1
    con_up_update = con_up_update + [ vm_up(:,DG.node(index_dg_pcc),:) == 1.0 ];
end

% =================== local DG ramping
t_pre = 1:n_t_up-1;
t_now = 2:n_t_up;
% ==== time = 1
con_up_update = con_up_update + [[ -DG.ramp(index_dg_local)' - (1-repmat(OUTAGE_DG(1,:),1,1,3))*M <= p_dg_up(1,index_dg_local,:) - p_dg_pre_up ]:'p_dg_up_1'];
con_up_update = con_up_update + [[ p_dg_up(1,index_dg_local,:) - p_dg_pre_up <= DG.ramp(index_dg_local)' + (1-repmat(OUTAGE_DG(1,:),1,1,3))*M ]:'p_dg_dn_1'];
% ==== time = [2,n_t_up]
con_up_update = con_up_update + [[ -repmat(DG.ramp(index_dg_local)',n_t_up-1,1,3) - (1-repmat(OUTAGE_DG(t_now,:),1,1,3))*M <= p_dg_up(t_now,index_dg_local,:) - p_dg_up(t_pre,index_dg_local,:) ]:'p_dg_up_2_T'];
con_up_update = con_up_update + [[ p_dg_up(t_now,index_dg_local,:) - p_dg_up(t_pre,index_dg_local,:) <= repmat(DG.ramp(index_dg_local)',n_t_up-1,1,3) + (1-repmat(OUTAGE_DG(t_now,:),1,1,3))*M ]:'p_dg_up_2_T'];

if t~=1
    con_up_update = con_up_update + [[ p_dg_pre_up == P_DG_NEW_UP ]:'p_dg_initial'];
end

% ================================== ES SOC
con_up_update = con_up_update + [[ soc_pre_up == SOC_NEW_UP ]:'soc_initial'];
if t ~= 1
    con_up_update = con_up_update + [[ p_es_ch_pre_up == P_ES_CH_NEW_UP ]:'p_es_ch_initial'];
    con_up_update = con_up_update + [[ p_es_dis_pre_up == P_ES_DIS_NEW_UP ]:'p_es_dis_initial'];
end

% =================== consideration of component failure
% =================== ES operation status
con_up_update = con_up_update + [ x_ch_up + x_dis_up <= OUTAGE_ESS ];

% =================== PV output
% con_up_update = con_up_update + [[  p_pv_up == PV.p_max_up(period_up,:).*OUTAGE_PV ]:'p_pv'];
con_up_update = con_up_update + [[  0 <= p_pv_up <= PV.p_max_up(period_up,:).*OUTAGE_PV ]:'p_pv'];
con_up_update = con_up_update + [[ -tan(acos(0.95))*p_pv_up.*OUTAGE_PV <= q_pv_up <= tan(acos(0.95))*p_pv_up.*OUTAGE_PV ]:'q_pv'];

% ========== local DG
con_up_update = con_up_update + [[ 0 <= p_dg_up(:,index_dg_local,:) <= repmat(DG.p_max(index_dg_local)',n_t_up,1,3).*repmat(OUTAGE_DG,1,1,3) ]:'p_dg_local'];
con_up_update = con_up_update + [[ q_dg_up(:,index_dg_local,:) >= -repmat(DG.q_max(index_dg_local)',n_t_up,1,3).*repmat(OUTAGE_DG,1,1,3) ]:'q_dg_local_lb'];
con_up_update = con_up_update + [[ q_dg_up(:,index_dg_local,:) <=  repmat(DG.q_max(index_dg_local)',n_t_up,1,3).*repmat(OUTAGE_DG,1,1,3) ]:'q_dg_local_ub'];


%% ================================== objective function
% power loss minimization
power_loss = repmat(BRA.R,n_t_up,1,1) .* (p_f_up.*p_f_up + q_f_up.*q_f_up);
obj_normal = sum(power_loss(:));

% resilience enhancement
load_pick = p_load_up.*repmat(LOAD.weight',n_t_up,1,3);
obj_emergency = sum(load_pick(:));

obj_up = obj_normal*x_s(1) - obj_emergency*(1-x_s(1));

% ================================= final model
cons_up = [ con_up, con_up_update ];
options_up = sdpsettings('verbose',0, 'solver','gurobi');

if x_s(1) == 1 % 0: emergency;  1: normalcy
    options_up.gurobi.mipgap = 0.5/100;
else
    options_up.gurobi.mipgap = 0.5/100;
end
options_up.gurobi.FeasibilityTol = 1e-8; % accuracy of constraint violations
sol_up = optimize(cons_up, obj_up, options_up);

%%
%[model, ~] = export(cons_up, obj_up, sdpsettings('solver', 'gurobi'));
%gurobi_write(model, ['up_',num2str(t),'.mps'])
