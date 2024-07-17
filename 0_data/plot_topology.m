clc;clear;

model_name = 'IEEE123';
model_name = [model_name, '_UNCC_Three_Phase_Revised'];

% back_dir = fileparts(pwd);
% file_path = fullfile(back_dir,'0_data',model_name);
% load(file_path)
load(model_name)

% switch_index = find(BRA.type == 2);
% BRA.name(switch_index) = [];
% BRA.no(switch_index) = [];
% BRA.busfrom(switch_index) = [];
% BRA.busto(switch_index) = [];
% BRA.nfrom(switch_index) = [];
% BRA.nto(switch_index) = [];
% BRA.phase(:,switch_index) = [];
% BRA.type(switch_index) = [];

% G = graph(BRA.nfrom, BRA.nto);
% plot(G,'XData',NODE.coordinates(:,1),'YData',NODE.coordinates(:,2));

black = [0,0,0]/255;
red = [255, 0, 0]/255;
orange = [	230, 149, 0]/255;
purple = [255, 27, 255]/255;
green = [0, 234, 0]/255;
yellow = [253, 235, 3]/255;
blue = [0, 0, 255]/255;
colororder = [blue; green; red ];

tiledlayout(1,1,'TileSpacing','Compact','Padding','Compact'); 
nexttile
hold on;
for g = 1:3
    phase = sum(BRA.phase,1);
    edge_index = find(phase==g);
    switch_index = find(BRA.type(edge_index)'==2);
    
    sg_nfrom = BRA.nfrom(edge_index);
    sg_nto = BRA.nto(edge_index);
    sw_from = sg_nfrom(switch_index);
    sw_to = sg_nto(switch_index);
    
    SG = graph(sg_nfrom,sg_nto);
    max_node = max(max(sg_nfrom),max(sg_nto));
    p(g) = plot(SG,'XData',NODE.coordinates(1:max_node,1),'YData',NODE.coordinates(1:max_node,2));
    
    p(g).MarkerSize = 2.0;
    p(g).EdgeColor = colororder(g,:);
    switch g
        case 1
            p(g).LineWidth = 1.0;
        case 2
            p(g).LineWidth = 1.3;
        case 3
            p(g).LineWidth = 1.8;
    end
    if g ~= 3
        p(g).LineStyle = '--';
    end
    if ~isempty(switch_index)        
        labeledge(p(g),sw_from,sw_to,'sw');
        p(g).EdgeFontSize = 12;
        p(g).EdgeFontAngle = 'normal';
        p(g).EdgeFontWeight = 'bold';
    end
%     p(g).NodeLabel = {};
    p(g).NodeLabel = NODE.name(1:max_node,1);
    p(g).NodeLabel{1} = ''; % source bus, name too long
    p(g).NodeColor = black;
    p(g).NodeFontSize = 8;
    
end
legend_name = {' 1-phase    ', ' 2-phase    ', ' 3-phase    '};
% legend(p,legend_name,'location','northeast','FontSize',14,'NumColumns',5,'Box','off')
% position: [left bottom width height]
legend(p,legend_name,'Position',[0.35 0.90 1.0 1.0],'FontSize',15,'NumColumns',5,'Box','off')

axis off 
hold off

width = 12*100;
height = 8*100;
set(gcf, 'Position',  [350, 150, width, height]) % set figure size
set(gcf, 'Color', [1,1,1])
set(gcf, 'renderer','painters')
set(gca,'FontName','Times New Roman','FontSize',16,'LineWidth',1.5)

annotation('rectangle',[0.16 0.15 .71 .80],'Color','w'); % [x y w h]
exportgraphics(gcf,'fig_toplogy.pdf','Resolution',900)
