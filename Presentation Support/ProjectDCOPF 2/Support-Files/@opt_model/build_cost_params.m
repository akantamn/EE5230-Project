function om = build_cost_params(om, force)
%BUILD_COST_PARAMS  Builds and saves the full generalized cost parameters.
%   OM = BUILD_COST_PARAMS(OM)
%   OM = BUILD_COST_PARAMS(OM, 'force')
%
%   Builds the full set of cost parameters from the individual named
%   sub-sets added via ADD_COSTS. Skips the building process if it has
%   already been done, unless a second input argument is present.
%
%   These cost parameters can be retrieved by calling GET_COST_PARAMS
%   and the user-defined costs evaluated by calling COMPUTE_COST.
%
%   See also OPT_MODEL, ADD_COSTS, GET_COST_PARAMS, COMPUTE_COST.

%   MATPOWER
%   $Id: build_cost_params.m 2137 2013-03-29 18:52:50Z ray $
%   by Ray Zimmerman, PSERC Cornell
%   Copyright (c) 2008-2012 by Power System Engineering Research Center (PSERC)
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

if nargin > 1 || ~isfield(om.cost.params, 'N')
    %% initialize parameters
    nw = om.cost.N;
    nnzN = 0;
    nnzH = 0;
    for k = 1:om.cost.NS
        name = om.cost.order(k).name;
        idx  = om.cost.order(k).idx;
        if isempty(idx)
            nnzN = nnzN + nnz(om.cost.data.N.(name));
            if isfield(om.cost.data.H, name)
                nnzH = nnzH + nnz(om.cost.data.H.(name));
            end
        else
            s = substruct('.', name, '{}', idx);
            nnzN = nnzN + nnz(subsref(om.cost.data.N, s));
            if isfield(om.cost.data.H, name)
                nnzH = nnzH + nnz(subsref(om.cost.data.H, s));
            end
        end
    end
    NNt = sparse([], [], [], om.var.N, nw, nnzN);   %% use NN transpose for speed
    Cw = zeros(nw, 1);
    H = sparse([], [], [], nw, nw, nnzH);   %% default => no quadratic term
    dd = ones(nw, 1);                       %% default => linear
    rh = Cw;                                %% default => no shift
    kk = Cw;                                %% default => no dead zone
    mm = dd;                                %% default => no scaling
    
    %% fill in each piece
    for k = 1:om.cost.NS
        name = om.cost.order(k).name;
        idx  = om.cost.order(k).idx;
        if isempty(idx)
            N = om.cost.idx.N.(name);       %% number of rows to add
        else
            s1 = substruct('.', name, '()', idx);
            s2 = substruct('.', name, '{}', idx);
            N = subsref(om.cost.idx.N, s1); %% number of rows to add
        end
        if N                                %% non-zero number of rows to add
            if isempty(idx)
                Nk = om.cost.data.N.(name);         %% N for kth cost set
                i1 = om.cost.idx.i1.(name);         %% starting row index
                iN = om.cost.idx.iN.(name);         %% ending row index
                vsl = om.cost.data.vs.(name);       %% var set list
            else
                Nk = subsref(om.cost.data.N, s2);   %% N for kth cost set
                i1 = subsref(om.cost.idx.i1, s1);   %% starting row index
                iN = subsref(om.cost.idx.iN, s1);   %% ending row index
                vsl = subsref(om.cost.data.vs, s2); %% var set list
            end
            if isempty(vsl)         %% full rows
                if size(Nk,2) == om.var.N
                    NNt(:, i1:iN) = Nk';     %% assign as columns in transpose for speed
                else                %% must have added vars since adding
                                    %% this cost set
                    NNt(1:size(Nk,2), i1:iN) = Nk';  %% assign as columns in transpose for speed
                end
            else                    %% selected columns
                kN = 0;                             %% initialize last col of Nk used
                Ni = sparse(N, om.var.N);
                for v = 1:length(vsl)
                    s = substruct('.', vsl(v).name, '()', vsl(v).idx);
                    j1 = subsref(om.var.idx.i1, s); %% starting column in N
                    jN = subsref(om.var.idx.iN, s); %% ending column in N
                    k1 = kN + 1;                    %% starting column in Nk
                    kN = kN + subsref(om.var.idx.N, s);%% ending column in Nk
                    Ni(:, j1:jN) = Nk(:, k1:kN);
                end
                NNt(:, i1:iN) = Ni';    %% assign as columns in transpose for speed
            end

            if isempty(idx)
                Cw(i1:iN) = om.cost.data.Cw.(name);
                if isfield(om.cost.data.H, name)
                    H(i1:iN, i1:iN) = om.cost.data.H.(name);
                end
                if isfield(om.cost.data.dd, name)
                    dd(i1:iN) = om.cost.data.dd.(name);
                end
                if isfield(om.cost.data.rh, name)
                    rh(i1:iN) = om.cost.data.rh.(name);
                end
                if isfield(om.cost.data.kk, name)
                    kk(i1:iN) = om.cost.data.kk.(name);
                end
                if isfield(om.cost.data.mm, name)
                    mm(i1:iN) = om.cost.data.mm.(name);
                end
            else
                Cw(i1:iN) = subsref(om.cost.data.Cw, s2);
                if isfield(om.cost.data.H, name) && ~isempty(subsref(om.cost.data.H, s2))
                    H(i1:iN, i1:iN) = subsref(om.cost.data.H, s2);
                end
                if isfield(om.cost.data.dd, name) && ~isempty(subsref(om.cost.data.dd, s2))
                    dd(i1:iN) = subsref(om.cost.data.dd, s2);
                end
                if isfield(om.cost.data.rh, name) && ~isempty(subsref(om.cost.data.rh, s2))
                    rh(i1:iN) = subsref(om.cost.data.rh, s2);
                end
                if isfield(om.cost.data.kk, name) && ~isempty(subsref(om.cost.data.kk, s2))
                    kk(i1:iN) = subsref(om.cost.data.kk, s2);
                end
                if isfield(om.cost.data.mm, name) && ~isempty(subsref(om.cost.data.mm, s2))
                    mm(i1:iN) = subsref(om.cost.data.mm, s2);
                end
            end
        end
    end

    %% save in object   
    om.cost.params = struct( ...
        'N', NNt', 'Cw', Cw, 'H', H, 'dd', dd, 'rh', rh, 'kk', kk, 'mm', mm );
end
