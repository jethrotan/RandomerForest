%Make Fig1 for LOVEFest (Randomer Forest)

close all
clear
clc

fpath = mfilename('fullpath');
findex = strfind(fpath,'/');
rootDir=fpath(1:findex(end-1));
p = genpath(rootDir);
gits=strfind(p,'.git');
colons=strfind(p,':');
for i=0:length(gits)-1
endGit=find(colons>gits(end-i),1);
p(colons(endGit-1):colons(endGit)-1)=[];
end
addpath(p);

%Colors = linspecer(3,'sequential');
Colors = repmat(linspecer(5,'sequential'),2,1);
Fig_Color = [1 1 1];
LineWidth = 3;
Marker = {'none' 'none' 'none' 'none' '.' '.' '.' '.'};
Units = 'pixels';
%FigPosition = [0 140 1150 650];
FigPosition = [0 140 1300 350];
%left = [50 350 650];
%bottom = [350 50];
%Axis_Left = repmat(left,1,2);
Axis_Left = [210 775];
%Axis_Bottom = cat(2,repmat(bottom(1),1,3),repmat(bottom(2),1,3));
Axis_Bottom = 60;
Axis_Width = 250;
Axis_Height = 250;
Legend_Width = 75;
Legend_Height = 80;
Legend_Left = 475;
Legend_Bottom = round(Axis_Bottom+Axis_Height/2-Legend_Height/2);
MarkerSize = 24;
Box = 'off';
Box_Legend = 'off';
Colorbar_Left = 1100;
Colorbar_Bottom = 30;
Colorbar_Width = 25;
Colorbar_Height = 280;
FontSize = 24;

BasePath = '~/LOVEFest/Figures/fig/';
Filename = {'Fig4_Real_Data_Panel_A_jovo.fig','Fig4_Real_Data_Panel_B_jovo.fig','Fig4_ntrees.fig'};

for i = 1:length(Filename)
    h{i} = openfig(strcat(BasePath,Filename{i}),'invisible');
    grid off
end

h{i+1} = figure('Visible','On');
set(h{i+1},'Position',FigPosition,'PaperOrientation','landscape','PaperUnits','inches','PaperSize',[8.5*2.1 11*2.1],'PaperPositionMode','auto','Color',Fig_Color)

set(h{i+1},'Units','normalized','position',[0 0 1 1]);
set(h{i+1},'Units','inches');
screenposition = get(h{i+1},'Position');
set(h{i+1},...
    'PaperPosition',[0 0 screenposition(3:4)],...
    'PaperSize',screenposition(3:4));

ax_old = get(h{1},'CurrentAxes');
ax_new = subplot(1,3,1);
copyobj(allchild(ax_old),ax_new);
Colors = flipud(repmat(ax_new.ColorOrder(1:4,:),2,1));
h_lines = allchild(ax_new);
for j = 1:length(h_lines)
    set(h_lines(j),'Color',Colors(j,:),'linewidth',LineWidth,'Marker',Marker{j},'MarkerSize',MarkerSize,'MarkerFaceColor',Colors(j,:),'MarkerEdgeColor',Colors(j,:))
end
set(ax_new,'FontSize',FontSize,'XGrid','Off','YGrid','Off','Box',Box,'LineWidth',LineWidth)
axis square
xlabel('Training Time (sec)')
ylabel('Error Rate')
title('(A) Avg. Error Rate vs. Time')
hL = legend('RF','RerF','RerF(d)','RerF(d+r)');
set(hL,'Units',Units,'Visible','On','Box',Box_Legend)
get(ax_new,'Position');

ax_old = get(h{2},'CurrentAxes');
ax_new = subplot(1,3,2);
copyobj(allchild(ax_old),ax_new);
h_lines = allchild(ax_new);
set(h_lines(1),'Color','k','linewidth',LineWidth)
for j = 2:length(h_lines)
    set(h_lines(j),'MarkerFaceColor',Colors(end,:),'MarkerEdgeColor',Colors(end,:))
end
set(ax_new,'FontSize',FontSize,'XGrid','Off','YGrid','Off','Box',Box,'LineWidth',LineWidth)
axis square
xlabel('RF')
ylabel('RerF')
title('(B) Individual Error Rates')
%hL = legend(ax_new,'Random Forest','Dense Randomer Forest','Sparse Randomer Forest','Sparse Randomer Forest w/ Mean Diff','Robust Sparse Randomer Forest w/ Mean Diff');
legend(ax_new,'hide')
get(ax_new,'Position');
rgb = map2color(transpose(linspace(1,1000,1000)),'log');
colormap([rgb(:,1) rgb(:,2) rgb(:,3)])
%colorbar
caxis([4 263])
%hc = colorbar('Units',Units,'Ticks',[10 25 50 100 200]);

ax_old = get(h{3},'CurrentAxes');
ax_new = subplot(1,3,3);
copyobj(allchild(ax_old),ax_new);
h_lines = allchild(ax_new);
for j = 1:length(h_lines)
    set(h_lines(j),'Color',Colors(j,:),'linewidth',LineWidth)
end
set(ax_new,'FontSize',FontSize,'XGrid','Off','YGrid','Off','Box',Box,'LineWidth',LineWidth,'XTick',[0 250 500])
xlim([0 500])
axis square
xlabel('# of Trees')
ylabel('OOB Error')
title('(C) Convergence')
%hL = legend(ax_new,'Random Forest','Dense Randomer Forest','Sparse Randomer Forest','Sparse Randomer Forest w/ Mean Diff','Robust Sparse Randomer Forest w/ Mean Diff');
hL = legend('RF','RerF','RerF(d)','RerF(d+r)');
set(hL,'Units',Units,'Visible','On','Box',Box_Legend)
   

fname = '~/LOVEFest/Figures/Fig4';
save_fig(gcf,fname)