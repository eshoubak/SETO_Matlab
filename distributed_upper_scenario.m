
% ================== PV outage
OUTAGE_PV = ones(n_t_up,n_pv);
% OUTAGE_PV([5]) = 0;
% OUTAGE_PV([7,8]) = 0;

% ================== DG outage
OUTAGE_DG = ones(n_t_up,n_local_dg);
% OUTAGE_DG([1]) = 0;

% ================== ESS outage
OUTAGE_ESS = ones(n_t_up,n_es);
% OUTAGE_ESS([5]) = 0;

% ================== Line outage
OUTAGE_BRA = ones(n_t_up,n_bra);
% OUTAGE_BRA([54]) = 0;

