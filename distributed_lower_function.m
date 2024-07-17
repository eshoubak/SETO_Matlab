
function [ to_field, result_track ] = distributed_lower_function(from_upper, from_field, from_sys, agent_data, load_data, pv_data, result_track)
%% ======================================= data exchange
% from_sys: data from system. constant value
% from_upper: data from upper-level, updated hourly
% from_field: data from field devices, updated every 15-minutes now

% agent_data: constant and variable values of agents.
% the definition of each column can also be found in the spreadsheet "inputs_outputs"
% or distributed_agent_data.m file

% load_data and pv data: used to recover the order of to_field.p_load_dn
% and to_field.p_pv_dn. We do not need them to complete the distributed calculation in this function

% result_track: used to store tracking results. can be removed


% ======================================== input from system
% ========================= constant value
% === these value can also be stored inside the agent
n_agent = from_sys.n_agent;
n_phase = from_sys.n_phase;

% smaller value indicates higher accuracy
error_estimation = from_sys.error_estimation; % local mistmach
error_constraint = from_sys.error_constraint; % power mismatch

error_consensus = from_sys.error_consensus; % used for lambda

n_alpha = from_sys.n_alpha;% larger value indicates better consensus
n_iter = from_sys.n_iter;
    
delt_t_dn = from_sys.delt_t_dn; % time horizon of lower-control; 15 minutes now.
  

% ======================================== input from upper level
% ========================= updated every hour
n_nmg = from_upper.n_nmg; % number of networked MGs

% weight of communication network for each networked MG
% denote the communication topology and the amount of information two neighboring agents exchange
% we still use one W matrix to do the consensus process
% however, the formation of the new W is different from our previous code
% The new W is able to consider the change of the system physical topology
% thus agents can complete consensus parallelly for all networked MGs
W = from_upper.W; % related to system topology


% ======================================== input from field device
% ========================= updated every 15 minutes
% if x_s is changed during the lower tracking process, then lower-level should stop and go back to upper
SOC_NEW_DN= from_field.SOC_NEW_DN; % latest SOC value


% ======================================== input from agent_data
% ========== this structure includes both constant and variable value
P_REF = agent_data(:,10:12); % reference setpoints; updated every hour
P_MAX = agent_data(:,4:6);% max output; updated every 15 minutes
P_MIN = agent_data(:,7:9);% min output; updated every 15 minutes

% net load of the networked MG where agents belong to
% agents in the same networked MG have the same value
NET_LOAD = agent_data(:,22:24);% updated every 15 minutes

coe_a = agent_data(:,17); % constant value
coe_b = -2.0 .* agent_data(:,10:12) .* agent_data(:,16); % related to P_REF; updated every hour

AA = agent_data(:,2);% constant value
rho = agent_data(:,18);% constant value, ping
tao = agent_data(:,25)*0.52;% constant value, ping

% the number of agents in each NMG
% related to system topology decided at the upper-level
n_agent_nmg = agent_data(:,21); % updated every hour

%% =========================================== calculation begin
% ================ vectors for calculation
p_global = zeros(n_agent, n_phase);
p_local = zeros(n_agent, n_phase);

y_global = agent_data(:,2) .* p_global;
y_local = agent_data(:,2) .* p_global;

lmd_global = 0.1 * ones(n_agent, n_phase);
lmd_local = 0.1 * ones(n_agent, n_phase);

result_cumulative=eye(985); 
for u=1:n_alpha
    result_cumulative=result_cumulative*W; %ping
end

for iter = 1:n_iter
    % consensus process: communicate with neighboring agents 
    % lmd_local(:,:,iter) = (W^n_alpha)*lmd_global(:,:,iter);
    % y_local(:,:,iter) = (W^n_alpha)*y_global(:,:,iter);  
      lmd_local(:,:,iter) = result_cumulative*lmd_global(:,:,iter);
    y_local(:,:,iter) = result_cumulative*y_global(:,:,iter); 

    % ============= local calculation and update for each agent (begin)
    p_local(:,:,iter) = ( -coe_b - AA.*lmd_local(:,:,iter) - rho.*AA.*( n_agent_nmg.*y_local(:,:,iter) - AA.*p_global(:,:,iter) - NET_LOAD ) )./(2.*coe_a + rho);
    p_local(:,:,iter) = min( max(p_local(:,:,iter), P_MIN), P_MAX ); % projection
   
    SOC_MIN = (SOC_NEW_DN - agent_data(agent_data(:,3) == 1, 13)) ./ (agent_data(agent_data(:,3) == 1, 2).*delt_t_dn);
    SOC_MAX = (SOC_NEW_DN - agent_data(agent_data(:,3) == 1, 14)) ./ (agent_data(agent_data(:,3) == 1, 2).*delt_t_dn);
    p_local(agent_data(:,3) == 1,:,iter) = min( max( p_local(agent_data(:,3) == 1,:,iter), SOC_MIN), SOC_MAX); % further projection for battery
    
    p_global(:,:,iter+1) = p_global(:,:,iter) + tao.*(p_local(:,:,iter) - p_global(:,:,iter)); % update

    y_global(:,:,iter+1) = y_local(:,:,iter) + AA.*(p_global(:,:,iter+1) - p_global(:,:,iter)); % update

    lmd_global(:,:,iter+1) = lmd_local(:,:,iter) + tao.*rho.*( n_agent_nmg.*y_global(:,:,iter+1)- NET_LOAD ); % update
    % ================== local calculation and update for each agent (end)
    
    
    % ============= evaluate if the distributed algorithm converges
    if iter >= 100
        converge = 0;
        
        % this vector confirms the agents that are used to check if the algorithm converges.
        % As we consider 5 MGs, I selected 5 local DGs from the 5 MGs
        stop_check_agent = [14, 15, 16, 17]; 
        
        % difference between two consective iterations
        diff_lmd = abs(lmd_global(stop_check_agent,:,iter) - lmd_global(stop_check_agent,:,iter-1));
        if max(diff_lmd(:)) <= error_consensus
            result_track.solution{result_track.count,1} = "Converged";
            converge = 1;
        end

        
        % ================================== for debug
        % the following code is used to store the max errors of local mismatch and power mismatchfor
        % it is for debugging. can be removed
        dev_local = abs(p_local(:,:,iter) - p_global(:,:,iter)); % calculate the mismatch
        supply = AA.*p_global(:,:,iter);        
        for nmg_index = 1:n_nmg % applied to each networked MG
            net_load = agent_data(agent_data(:,20)==nmg_index,22:24); % fetch the net load for the current networked MG
            dev_load = abs(sum(supply(agent_data(:,20)==nmg_index,:),1)-net_load(1,:)); % calculate the power mismatch

            result_track.dev_local{result_track.count,nmg_index} = max(dev_local(agent_data(:,20)==nmg_index));
            result_track.dev_load{result_track.count,nmg_index} = max(dev_load);
            
            result_track.dev_local_status{result_track.count,nmg_index} = max(dev_local(agent_data(:,20)==nmg_index)) <= error_estimation;
            result_track.dev_load_status{result_track.count,nmg_index} = max(dev_load) <= error_constraint;
        end
        % ================================== for debug
        
        
        if converge == 1
            break
        end
        
    end % end if iter >= 100
    
    if iter >= n_iter
        result_track.solution{result_track.count,1} = "Reach maximum iteration";
        fprintf('\n!!! Reach maximum iteration !!!\n')                
    end
    
end % end for iter = 1:n_iter

% ============= store results for verification
result_track.P_REF{result_track.count,1} = P_REF;
result_track.p_local{result_track.count,1} = p_local;
result_track.NET_LOAD{result_track.count,1} = unique(agent_data(:,18:20),'rows','stable');
result_track.n_nmg{result_track.count,1} = from_upper.n_nmg;
result_track.iter(result_track.count,1) = iter;

result_track.lmd{result_track.count,1} = lmd_global;
result_track.y{result_track.count,1} = y_global;

result_track.lmd_diff{result_track.count,1} = abs(lmd_global(:,:,end) - lmd_global(:,:,end-1));
result_track.y_diff{result_track.count,1} = abs(y_global(:,:,end) - y_global(:,:,end-1));

% =========== final results sent to field devices
to_field.obj_dn = sum( sum( (p_local(:,:,end)-P_REF).^2 ) ) / n_agent;

to_field.p_dg_dn = p_local(agent_data(:,3)==2 | agent_data(:,3)==3,:,end);

to_field.soc_dn = SOC_NEW_DN - agent_data(agent_data(:,3)==1,2).*p_local(agent_data(:,3)==1,:,end) * delt_t_dn;
to_field.p_es_ch_dn = -p_local(agent_data(:,3)==1,:,end).*(p_local(agent_data(:,3)==1,:,end)<0);
to_field.p_es_dis_dn = p_local(agent_data(:,3)==1,:,end).*(p_local(agent_data(:,3)==1,:,end)>=0);
to_field.p_es = to_field.p_es_dis_dn - to_field.p_es_ch_dn;

% we did not directly use pv_data and load_data in the calculation of this function.
% the calculation of net load is done out of this function.
to_field.p_pv_dn = pv_data(:,3); 

p_load_dn_curtail = [ agent_data(agent_data(:,3)==4,1) p_local(agent_data(:,3)==4,:,end)];
p_load_dn_noncurtail = load_data(:,[1,3:5]);
p_load_dn = [p_load_dn_curtail;p_load_dn_noncurtail];
p_load_dn = sortrows(p_load_dn,1);
to_field.p_load_dn = p_load_dn(:,2:4);

%run result_compare

end