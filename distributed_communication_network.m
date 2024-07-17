
%% ============== undirected graph for the communication network
s = [];
t = [];
% ==== communications inside each MG
for mg = 1:n_mg
    index = find(agent_data(:,19)==mg);
    s = [s; index(1:end-1)];
    t = [t; index(2:end)];
end
% === based on the index of agent in each MG
% s = [s;  1;  2;  3;  4;  5];
% t = [t; 16; 17; 18; 19; 20];
 s = [s;  1;  4;  7;  12];
 t = [t; 823; 878; 985; 888];


% ==== communications between different MGs, topology-based
% s = [s; 16; 1; 18; 19];
% t = [t;  2; 3;  4;  5];
s = [s; 823; 1;  1;  878; 985];
t = [t;  4;  7;  12; 985; 888];

G = graph(s,t);
%plot(G);
A_original = adjacency(G);
A_original = full(A_original);
D = diag(sum(A_original,2));
L = D-A_original;
e = eig(L); % e(2:end) should be greater than 0
alpha = 2/(e(end)+e(2));
W = eye(size(A_original,1)) - 1 * alpha * L;
W=sparse(W); % ping

