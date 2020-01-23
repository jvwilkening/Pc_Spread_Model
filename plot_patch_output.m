%%A script for plotting the model predction with outlines of the patch, in
%%manuscript figures were further recolored and annotated in external program

clear all
close all


load('example_patch.mat')
load('Patch 1 Output.mat')

initial_patch=flip(patch1_1981);
final_patch=flip(patch1_1984);
pred_patch1=flip(infectedcells); %saved output from model run



% First let's trim and rotate the images
x_start=22;
x_end=88;
y_start=75;
y_end=145;

y_length=y_end-y_start+1;
x_length=x_end-x_start+1;
CP1 = pred_patch1(x_start:x_end,y_start:y_end);
pinitial = initial_patch(x_start:x_end,y_start:y_end);
pfinal = final_patch(x_start:x_end,y_start:y_end);

%%
[init_x, init_y] = smoothed_edges(pinitial,2,7); %might need to adjust final value depending on image
[pred1_x, pred1_y] = smoothed_edges(CP1,2,7);
[fin_x, fin_y] = smoothed_edges(pfinal,2,7);


figure('Color','white')


plot(pred1_x, pred1_y, '-', 'LineWidth', 6, 'Color', [.486275, .611765, .611765]);
hold on
plot(fin_x, fin_y, 'b-', 'LineWidth', 4);
plot(init_x, init_y, 'r-', 'LineWidth', 4);
axis equal
xlim([0 y_length]) %note axis names are flipped
ylim([0 x_length])