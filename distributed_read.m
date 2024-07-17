%% read
load(file_sys); % branch, node, and load

% ===================== NODE
n_node = length(NODE.number);
n_mg = length(unique(NODE.mg));


% ===================== branch
BRA.phase = BRA.phase';
% for k = 1:numel(BRA.Z)
%     BRA.Z{k} = BRA.Z{k} * 10; %%revised by anping
% end
BRA.Z = BRA.Z'; 
n_bra = length(BRA.busfrom);
% assume no resistence and reactance in switches
index_sw = find(BRA.type==2);
for i = 1:length(index_sw)
    BRA.Z{index_sw(i),1} = zeros(3,3);
end

% % to avoid numerical issues
for i = 1:n_bra
    index = find(BRA.Z{i,1}<1e-8);
    BRA.Z{i,1}(index) = 0.0;
end


% ===================== LOAD
LOAD.p_spot = LOAD.p_spot / s_base;
LOAD.q_spot = LOAD.q_spot / s_base;

n_load = length(LOAD.node);
% increase the weight difference between different loads
LOAD.weight(LOAD.priority == 1,1) = 1;
LOAD.weight(LOAD.priority == 2,1) = 2;
LOAD.weight(LOAD.priority == 3,1) = 6;
LOAD.weight(LOAD.priority == 4,1) = 24;
LOAD.weight(LOAD.priority == 5,1) = 100;


% ===================== DG
data_read = readmatrix(file_dg,'Sheet','dg');
DG.node_name = cell(size(data_read,1),1);
for i = 1:size(data_read,1)
    DG.node_name{i} = num2str(data_read(i,2));
end
[~,DG.node] = ismember(DG.node_name,NODE.name);

DG.p_max = data_read(:,3)/s_base;
DG.q_max = data_read(:,4)/s_base;
DG.ramp = data_read(:,5)/s_base;
DG.type = data_read(:,6);
DG.mg = data_read(:,7);
n_dg = length(DG.node);
n_pcc = length(find(DG.type==1));
%n_pcc = 4;
n_local_dg = length(find(DG.type==2));


% ===================== ess
data_read = readmatrix(file_dg,'Sheet','ess');
ES.node_name = cell(size(data_read,1),1);
for i = 1:size(data_read,1)
    ES.node_name{i} = num2str(data_read(i,2));
end
[~,ES.node] = ismember(ES.node_name,NODE.name);

ES.p_max = data_read(:,3)/s_base;
ES.q_max = data_read(:,4)/s_base;
ES.ramp = data_read(:,5)/s_base;
ES.e_max = data_read(:,6)/s_base;
ES.e_min = data_read(:,7)/s_base;
ES.e_ini = data_read(:,8)/s_base;
ES.mg = data_read(:,9);
n_es = length(ES.node);


% ===================== PV
data_read = readmatrix(file_dg,'Sheet','pv');
PV.node_name = cell(size(data_read,1),1);
for i = 1:size(data_read,1)
    PV.node_name{i} = num2str(data_read(i,2));
end
[~,PV.node] = ismember(PV.node_name,NODE.name);

PV.p_max = data_read(:,3)/s_base;
PV.q_max = data_read(:,4)/s_base;
PV.mg = data_read(:,5);
n_pv = length(PV.node);
   

% ===================== LOAD and PV PROFILE
data_read = readmatrix(file_load,'Sheet','LOAD');
PROFILE.load_up = data_read(1:24*1*60/interval_up,2); % used for the upper level
PROFILE.load_up = repmat(PROFILE.load_up,2,1); % duplicate one day

PROFILE.load_dn = data_read(1:24*1*60/interval_dn,3); % used for the lower level
PROFILE.load_dn = repmat(PROFILE.load_dn,2,1); % duplicate one day


data_read = readmatrix(file_load,'Sheet','PV');
PROFILE.pv_up = data_read(1:24*60/interval_up,2); % used for the upper level
PROFILE.pv_up = repmat(PROFILE.pv_up,2,1); % duplicate one day

PROFILE.pv_dn = data_read(1:24*60/interval_dn,4); % used for the lower level
PROFILE.pv_dn = repmat(PROFILE.pv_dn,2,1); % duplicate one day


%% process
% use another matrix to store Z matrix
Z=zeros(3*n_node, 3*n_node);
BRA.R = zeros(n_bra,3);
for i=1:n_bra
    nfrom = BRA.nfrom(i);
    nto = BRA.nto(i);
    % nfrom = BRA.busfrom(i);
    % nto = BRA.busto(i);
	Z(3*nfrom-2 : 3*nfrom,  3*nto-2 : 3*nto ) = BRA.Z{i,1};
	Z(3*nto-2 : 3*nto,  3*nfrom-2 : 3*nfrom ) = BRA.Z{i,1};
% Z(3*nfrom-5 : 3*nfrom-3,  3*nto-5 : 3*nto-3 ) = BRA.Z{i,1};
% 	Z(3*nto-5 : 3*nto-3,  3*nfrom-5 : 3*nfrom-3 ) = BRA.Z{i,1};
	BRA.R(i,:) = diag(real(BRA.Z{i,1}))';
end
BRA.R = reshape(BRA.R,[1,size(BRA.R,1),size(BRA.R,2)]);


% calculate chronological LOAD data
% ========= upper level
LOAD.p_up = reshape(LOAD.p_spot,[1,size(LOAD.p_spot,1),size(LOAD.p_spot,2)]);
LOAD.p_up = repmat(LOAD.p_up,length(PROFILE.load_up),1,1);
LOAD.p_up = LOAD.p_up .* repmat(PROFILE.load_up,1,n_load,3);

LOAD.q_up = reshape(LOAD.q_spot,[1,size(LOAD.q_spot,1),size(LOAD.q_spot,2)]);
LOAD.q_up = repmat(LOAD.q_up,length(PROFILE.load_up),1,1);
LOAD.q_up = LOAD.q_up .* repmat(PROFILE.load_up,1,n_load,3);

% ========= lower level
LOAD.p_dn = reshape(LOAD.p_spot,[1,size(LOAD.p_spot,1),size(LOAD.p_spot,2)]);
LOAD.p_dn = repmat(LOAD.p_dn,length(PROFILE.load_dn),1,1);
LOAD.p_dn = LOAD.p_dn .* repmat(PROFILE.load_dn,1,n_load,3);

LOAD.q_dn = reshape(LOAD.q_spot,[1,size(LOAD.q_spot,1),size(LOAD.q_spot,2)]);
LOAD.q_dn = repmat(LOAD.q_dn,length(PROFILE.load_dn),1,1);
LOAD.q_dn = LOAD.q_dn .* repmat(PROFILE.load_dn,1,n_load,3);

% LOAD.p_dn = kron(LOAD.p_up,ones(4,1));
LOAD.p_diff_A = kron(LOAD.p_up(:,:,1),ones(4,1)) - LOAD.p_dn(:,:,1);
LOAD.p_diff_B = kron(LOAD.p_up(:,:,2),ones(4,1)) - LOAD.p_dn(:,:,2);
LOAD.p_diff_C = kron(LOAD.p_up(:,:,3),ones(4,1)) - LOAD.p_dn(:,:,3);

% calculate chronological PV data
% ========= upper level
PV.p_max_up = reshape(PV.p_max,1,[]);
PV.p_max_up = repmat(PV.p_max_up,length(PROFILE.pv_up),1,1);
PV.p_max_up = PV.p_max_up .* repmat(PROFILE.pv_up,1,n_pv);

% ========= lower level
PV.p_max_dn = reshape(PV.p_max,1,[]);
PV.p_max_dn = repmat(PV.p_max_dn,length(PROFILE.pv_dn),1,1);
PV.p_max_dn = PV.p_max_dn .* repmat(PROFILE.pv_dn,1,n_pv);


%% element-node connection matrix
% DG NODE Matrix
for i = 1:n_dg
    for j = 1:n_node
        if DG.node(i) == NODE.number(j)
            M_DG_NODE(i,j)=1;  
        else
            M_DG_NODE(i,j)=0;
        end
    end
end

% PV NODE Matrix
for i = 1:n_pv
    for j = 1:n_node
        if PV.node(i) == NODE.number(j)
            M_PV_NODE(i,j) = 1;  
        else
            M_PV_NODE(i,j) = 0;
        end
    end
end

% ES NODE Matrix
for i = 1:n_es
    for j = 1:n_node
        if ES.node(i) == NODE.number(j)
            M_ES_NODE(i,j) = 1;  
        else
            M_ES_NODE(i,j) = 0;
        end
    end
end

% LOAD NODE Matrix
for i = 1:n_load
    for j = 1:n_node
        if LOAD.node(i) == NODE.number(j)
            M_LOAD_NODE(i,j) = -1;%
        else
            M_LOAD_NODE(i,j) = 0;
        end
    end
end

% Branch NODE Matrix
for i = 1:n_bra
    for j = 1:n_node
        if BRA.nfrom(i) == NODE.number(j)
            M_BRA_NODE(i,j) = -1;
        else
            if BRA.nto(i) == NODE.number(j)
                M_BRA_NODE(i,j) = 1;
            else
                M_BRA_NODE(i,j) = 0;
            end
        end
    end
end

%% other useful information
index_dg_pcc = find( DG.type==1 );
index_dg_local = find( DG.type==2 );

index_load_noncurtail = find( LOAD.type == 1 );
index_load_curtail = find( LOAD.type == 2 );
n_load_noncurtail = length(index_load_noncurtail);
n_load_curtail = length(index_load_curtail);

index_nonswitch = find( BRA.type == 1 );
index_switch = find( BRA.type == 2 );
