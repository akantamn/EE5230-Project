function mpc = case3a
%CASE5  Power flow data for modified 5 bus, 5 gen case based on PJM 5-bus system
%   Please see CASEFORMAT for details on the case file format.
%
%   Based on data from ...
%     F.Li and R.Bo, "Small Test Systems for Power System Economic Studies",
%     Proceedings of the 2010 IEEE Power & Energy Society General Meeting

%   Created by Rui Bo in 2006, modified in 2010, 2014.
%   Distributed with permission.

%   MATPOWER
%   $Id: case5.m 2324 2014-05-23 18:01:41Z ray $

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
    1   3   200 0   0   0   1   1   0   230 1   1.1 0.9;
    2   2   300 0   0   0   2   1   0   230 1   1.1 0.9;
    3   2   150 0   0   0   3   1   0   230 1   1.1 0.9;
    
    
% 	1	2	0	0	0	0	1	1	0	230	1	1.1	0.9;
% 	2	1	300	98.61	0	0	1	1	0	230	1	1.1	0.9;
% 	3	2	300	98.61	0	0	1	1	0	230	1	1.1	0.9;
% 	4	3	400	131.47	0	0	1	1	0	230	1	1.1	0.9;
% 	5	2	0	0	0	0	1	1	0	230	1	1.1	0.9;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	1   200 0   0   0   1   0   1   500 50  0   0   0   0   0   0   0   0   0   0   0;
    2   300 0   0   0   1   0   1   600 50  0   0   0   0   0   0   0   0   0   0   0;
    3   250 0   0   0   1   0   1   250 50  0   0   0   0   0   0   0   0   0   0   0;    
    
    
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	2	0.1	0.1 0	100	100	100	0	0	1	-360	30;
	2	3	0.15 0.15   0   50  50  50 	0	0	1	-360	30;
	1	3	0.2 0.2  0   60  60  60 	0	0	1	-360	30;    
];

%%-----  OPF Data  -----%%
%% area data
%	area	refbus
mpc.areas = [
	1	1;
    2   2;
    3   3;
];

%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3   0.012   20  400;
	2   0   0   3   0.01    10  200;
	2	0   0   3   0.008   13  350;
];
