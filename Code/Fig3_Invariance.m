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
Colors = linspecer(6,'sequential');
Fig_Color = [1 1 1];
LineWidth = 3;
Marker = 'none';
%Title = {'Trunk' 'Rotated' 'Translated' 'Scaled' 'Outliers'};
Title = {'(A) Random Forest' '(B) R''er F(s+d)' '(C) R''er F(s+d+r)'};
Units = 'pixels';
%FigPosition = [0 140 1150 650];
FigPosition = [0 140 1300 350];
%left = [50 350 650];
%bottom = [350 50];
%Axis_Left = repmat(left,1,2);
Axis_Left = [85 410 735];
%Axis_Bottom = cat(2,repmat(bottom(1),1,3),repmat(bottom(2),1,3));
Axis_Bottom = 63;
Axis_Width = 250;
Axis_Height = 250;
Legend_Width = 150;
Legend_Height = 160;
Legend_Left = 1075;
%Legend_Bottom = round(bottom(1)+Axis_Height/2-Legend_Height(1)/2);
Legend_Bottom = round(Axis_Bottom+Axis_Height/2-Legend_Height/2);
MarkerSize = 24;
Box = 'off';
Box_Legend = 'off';
FontSize = 24;

Filename = '~/LOVEFest/Figures/fig/Invariance_Trunk_v2.fig';

h_fig_old = openfig(Filename,'invisible');
h_ax_old = flipud(findobj(h_fig_old,'Type','axes'));

h_fig_new = figure('Visible','On');
set(h_fig_new,'Position',FigPosition,'PaperOrientation','landscape','PaperUnits','inches','PaperSize',[8.5*2.1 11*2.1],'PaperPositionMode','auto','Color',Fig_Color)

for i = 1:length(h_ax_old)
    %h_ax_new = subplot(2,3,i);
    h_ax_new = subplot(1,3,i);
    copyobj(allchild(h_ax_old(i)),h_ax_new);
    h_lines = allchild(h_ax_new);
    for j = 1:length(h_lines)
        ln = h_lines(j);
        if strcmp(ln.DisplayName,'Translated')
            delete(ln)
            rm_idx = j;
        end
    end
    h_lines(rm_idx) = [];
    xmax = zeros(1,length(h_lines));
    if i == 1
        ymax_ln = zeros(1,length(h_lines));
        for j = 1:length(h_lines)
            set(h_lines(j),'Color',Colors(j,:),'linewidth',LineWidth,'Marker',Marker,'MarkerFaceColor',Colors(j,:),'MarkerEdgeColor',Colors(j,:))
            xmax(j) = max(get(h_lines(j),'XData'));
            ymax_ln(j) = max(get(h_lines(j),'YData'));
        end
        xmax = max(xmax);
        ymax_ax = max(ymax_ln);
        ymax_idx = find(ymax_ln==ymax_ax);
        ymax_idx = ymax_idx(1);
        ymax_ax = ymax_ax + h_lines(ymax_idx).UData(find(h_lines(ymax_idx).YData==ymax_ln(ymax_idx)));
    else
        for j = 1:length(h_lines)
            set(h_lines(j),'Color',Colors(j,:),'linewidth',LineWidth,'Marker',Marker,'MarkerFaceColor',Colors(j,:),'MarkerEdgeColor',Colors(j,:))
            xmax(j) = max(get(h_lines(j),'XData'));
        end
        xmax = max(xmax);
    end
    XTick = logspace(0,log10(xmax),log10(xmax)+1);
    set(h_ax_new,'FontSize',FontSize,'XLim',[0 10^(log10(xmax)+0.1)],'YLim',[0 ymax_ax],'XScale','log','XTick',XTick,'XGrid','Off','YGrid','Off','Box',Box,'LineWidth',LineWidth,'Units',Units,'Position',[Axis_Left(i) Axis_Bottom Axis_Width Axis_Height])
    title(Title{i})
    xlabel('# of Ambient Dimensions')
    if i == 1
        ylabel('Error Rate')
    end
    %hL = legend(h_ax_new,'Random Forest','Sparse Randomer Forest w/ Mean Diff','Robust Sparse Randomer Forest w/ Mean Diff');
    hL = legend('Untransformed','Rotated','Scaled','Affine','Outlier');
    legend(h_ax_new,'hide')
    get(h_ax_new,'Position');
end
set(hL,'FontSize',FontSize,'Units',Units,'Position',[Legend_Left Legend_Bottom Legend_Width Legend_Height],'Visible','On','Box',Box_Legend)

fname = '~/LOVEFest/Figures/Fig3_Invariance_v2';
save_fig(gcf,fname)
