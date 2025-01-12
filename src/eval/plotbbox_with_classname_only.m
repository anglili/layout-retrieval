function plotbbox_with_classname_only(bbox, classname, color, linewidth)
if nargin < 3
    color = 'r';
    linewidth = 2;
end
rectangle('Position', bbox, 'edgecolor', color, 'linewidth', linewidth);
if ~isempty(classname)
text(bbox(1), bbox(2), classname, 'backgroundcolor', 'w', 'edgecolor', 'k', ...
    'interpreter', 'none', 'fontsize', 10, 'verticalalignment', 'top');
end