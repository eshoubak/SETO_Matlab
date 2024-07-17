file_name = ['C:\Users\wt000\Desktop\1_IEEE123_Three_Phase_reduced_function_based_v0\','result_correct'];
file_name = [file_name,'_',num2str(result_track.period_dn),'.mat'];
load(file_name)
max_p_dg = max(max(abs(result_correct.p_dg_dn - to_field.p_dg_dn)));
max_soc_dn = max(max(abs(result_correct.soc_dn - to_field.soc_dn)));
max_p_es_ch = max(max(abs(result_correct.p_es_ch_dn - to_field.p_es_ch_dn)));
max_p_es_dis = max(max(abs(result_correct.p_es_dis_dn - to_field.p_es_dis_dn)));
max_p_pv = max(max(abs(result_correct.p_pv_dn - to_field.p_pv_dn)));
max_p_load = max(max(abs(result_correct.p_load_dn - to_field.p_load_dn)));

max_error = 1e-06;
if max([max_p_dg max_soc_dn max_p_es_ch max_p_es_dis max_p_pv max_p_load] >= max_error)
    fprintf('\t ')
end
if max_p_dg >= max_error
    fprintf('max_p_dg: %.6f || ',max_p_dg);
end
if max_soc_dn >= max_error
    fprintf('max_soc_dn: %.6f || ', max_soc_dn );
end
if max_p_es_ch >= max_error
    fprintf('max_p_es_ch: %.6f || ',max_p_es_ch);
end
if max_p_es_dis >= max_error
    fprintf('max_p_es_dis: %.6f || ',max_p_es_dis);
end
if max_p_pv >= max_error
    fprintf(' max_p_pv: %.6f || ',max_p_pv );
end
if max_p_load >= max_error
    fprintf('max_p_load: %.6f',max_p_load );
end
if max([max_p_dg max_soc_dn max_p_es_ch max_p_es_dis max_p_pv max_p_load] >= max_error)
    fprintf('\n');
end

% fprintf('\t max_p_dg: %.6f || max_soc_dn: %.6f || max_p_es_ch: %.6f || max_p_es_dis: %.6f || max_p_pv: %.6f || max_p_load: %.6f\n',...
%          max_p_dg, max_soc_dn, max_p_es_ch, max_p_es_dis, max_p_pv, max_p_load );