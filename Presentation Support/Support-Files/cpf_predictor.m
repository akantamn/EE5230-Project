function [V0, lam0, z] = cpf_predictor(V, lam, Ybus, Sxfr, pv, pq, ...
                            step, z, Vprv, lamprv, parameterization)
%CPF_PREDICTOR  Performs the predictor step for the continuation power flow
%   [V0, LAM0, Z] = CPF_PREDICTOR(VPRV, LAMPRV, YBUS, SXFR, PV, PQ, STEP, Z)
%
%   Computes a prediction (approximation) to the next solution of the
%   continuation power flow using a normalized tangent predictor.
%
%   Inputs:
%       V : complex bus voltage vector at current solution
%       LAM : scalar lambda value at current solution
%       YBUS : complex bus admittance matrix
%       SXFR : complex vector of scheduled transfers (difference between
%              bus injections in base and target cases)
%       PV : vector of indices of PV buses
%       PQ : vector of indices of PQ buses
%       STEP : continuation step length
%       Z : normalized tangent prediction vector from previous step
%       VPRV : complex bus voltage vector at previous solution
%       LAMPRV : scalar lambda value at previous solution
%       PARAMETERIZATION : Value of cpf.parameterization option.
%
%   Outputs:
%       V0 : predicted complex bus voltage vector
%       LAM0 : predicted lambda continuation parameter
%       Z : the normalized tangent prediction vector

%   MATPOWER
%   $Id: cpf_predictor.m 2235 2013-12-11 13:44:13Z ray $
%   by Shrirang Abhyankar, Argonne National Laboratory
%   and Ray Zimmerman, PSERC Cornell
%   Copyright (c) 1996-2013 by Power System Engineering Research Center (PSERC)
%
%   This file is part of MATPOWER.
%   See http://www.pserc.cornell.edu/matpower/ for more info.
%
%   MATPOWER is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published
%   by the Free Software Foundation, either version 3 of the License,
%   or (at your option) any later version.
%
%   MATPOWER is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with MATPOWER. If not, see <http://www.gnu.org/licenses/>.
%
%   Additional permission under GNU GPL version 3 section 7
%
%   If you modify MATPOWER, or any covered work, to interface with
%   other modules (such as MATLAB code and MEX-files) available in a
%   MATLAB(R) or comparable environment containing parts covered
%   under other licensing terms, the licensors of MATPOWER grant
%   you additional permission to convey the resulting work.

%% sizes
nb = length(V);
npv = length(pv);
npq = length(pq);

%% compute Jacobian for the power flow equations
[dSbus_dVm, dSbus_dVa] = dSbus_dV(Ybus, V);
    
j11 = real(dSbus_dVa([pv; pq], [pv; pq]));
j12 = real(dSbus_dVm([pv; pq], pq));
j21 = imag(dSbus_dVa(pq, [pv; pq]));
j22 = imag(dSbus_dVm(pq, pq));

J = [   j11 j12;
        j21 j22;    ];

dF_dlam = -[real(Sxfr([pv; pq])); imag(Sxfr(pq))];
[dP_dV, dP_dlam] = cpf_p_jac(parameterization, z, V, lam, Vprv, lamprv, pv, pq);

%% linear operator for computing the tangent predictor
J = [   J   dF_dlam; 
      dP_dV dP_dlam ];

% J = [ J, dF_dlam; 
%       z([pv; pq; nb+pq; 2*nb+1])'];

Vaprv = angle(V);
Vmprv = abs(V);

%% compute normalized tangent predictor
s = zeros(npv+2*npq+1, 1);
s(end,1) = 1;                       %% increase in the direction of lambda
z([pv; pq; nb+pq; 2*nb+1]) = J\s;   %% tangent vector
z = z/norm(z);                      %% normalize tangent predictor

Va0 = Vaprv;
Vm0 = Vmprv;
lam0 = lam;

%% prediction for next step
Va0([pv; pq]) = Vaprv([pv; pq]) + step * z([pv; pq]);
Vm0([pq]) = Vmprv([pq]) + step * z([nb+pq]);
lam0 = lam + step * z(2*nb+1);
V0 = Vm0 .* exp(1j * Va0);
