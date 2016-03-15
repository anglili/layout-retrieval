function [x, y, z] = plot_cuboid(p, q, c)
x = [p(1) q(1) q(1) p(1); p(1) q(1) q(1) p(1); p(1) p(1) p(1) p(1); q(1) q(1) q(1) q(1); p(1) p(1) q(1) q(1); p(1) p(1) q(1) q(1)]';
y = [p(2) p(2) q(2) q(2); p(2) p(2) q(2) q(2); p(2) q(2) q(2) p(2); p(2) q(2) q(2) p(2); p(2) p(2) p(2) p(2); q(2) q(2) q(2) q(2)]';
z = [p(3) p(3) p(3) p(3); q(3) q(3) q(3) q(3); p(3) p(3) q(3) q(3); p(3) p(3) q(3) q(3); p(3) q(3) q(3) p(3); p(3) q(3) q(3) p(3)]';
fill3(x, y, z, c);