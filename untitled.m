%% Problem 1
f = [-5; -4];
A = [4 2; 2 3];
b = [32; 24];
Aeq = [];
beq = [];
lb = [0 0];
ub = [inf inf];
opts = optimoptions('linprog', 'Algorithm', 'dual-simplex', 'Display', 'final');

x = linprog(f,A,b,Aeq,beq,lb,ub,opts)