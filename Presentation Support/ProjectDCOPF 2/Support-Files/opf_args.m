function [baseMVA, bus, gen, branch, gencost, Au, lbu, ubu, ...
        mpopt, N, fparm, H, Cw, z0, zl, zu, userfcn, areas] = ...
    opf_args(baseMVA, bus, gen, branch, areas, gencost, Au, lbu, ubu, ...
        mpopt, N, fparm, H, Cw, z0, zl, zu)
%OPF_ARGS  Parses and initializes OPF input arguments.
%   [MPC, MPOPT] = OPF_ARGS( ... )
%   [BASEMVA, BUS, GEN, BRANCH, GENCOST, A, L, U, MPOPT, ...
%       N, FPARM, H, CW, Z0, ZL, ZU, USERFCN] = OPF_ARGS( ... )
%   Returns the full set of initialized OPF input arguments, filling in
%   default values for missing arguments. See Examples below for the
%   possible calling syntax options.
%
%   Examples:
%       Output argument options:
%
%       [mpc, mpopt] = opf_args( ... )
%       [baseMVA, bus, gen, branch, gencost, A, l, u, mpopt, ...
%           N, fparm, H, Cw, z0, zl, zu, userfcn] = opf_args( ... )
%       [baseMVA, bus, gen, branch, gencost, A, l, u, mpopt, ...
%           N, fparm, H, Cw, z0, zl, zu, userfcn, areas] = opf_args( ... )
%
%       Input arguments options:
%
%       opf_args(mpc)
%       opf_args(mpc, mpopt)
%       opf_args(mpc, userfcn, mpopt)
%       opf_args(mpc, A, l, u)
%       opf_args(mpc, A, l, u, mpopt)
%       opf_args(mpc, A, l, u, mpopt, N, fparm, H, Cw)
%       opf_args(mpc, A, l, u, mpopt, N, fparm, H, Cw, z0, zl, zu)
%
%       opf_args(baseMVA, bus, gen, branch, areas, gencost)
%       opf_args(baseMVA, bus, gen, branch, areas, gencost, mpopt)
%       opf_args(baseMVA, bus, gen, branch, areas, gencost, userfcn, mpopt)
%       opf_args(baseMVA, bus, gen, branch, areas, gencost, A, l, u)
%       opf_args(baseMVA, bus, gen, branch, areas, gencost, A, l, u, mpopt)
%       opf_args(baseMVA, bus, gen, branch, areas, gencost, A, l, u, ...
%                                   mpopt, N, fparm, H, Cw)
%       opf_args(baseMVA, bus, gen, branch, areas, gencost, A, l, u, ...
%                                   mpopt, N, fparm, H, Cw, z0, zl, zu)
%
%   The data for the problem can be specified in one of three ways:
%   (1) a string (mpc) containing the file name of a MATPOWER case
%     which defines the data matrices baseMVA, bus, gen, branch, and
%     gencost (areas is not used at all, it is only included for
%     backward compatibility of the API).
%   (2) a struct (mpc) containing the data matrices as fields.
%   (3) the individual data matrices themselves.
%   
%   The optional user parameters for user constraints (A, l, u), user costs
%   (N, fparm, H, Cw), user variable initializer (z0), and user variable
%   limits (zl, zu) can also be specified as fields in a case struct,
%   either passed in directly or defined in a case file referenced by name.
%   
%   When specified, A, l, u represent additional linear constraints on the
%   optimization variables, l <= A*[x; z] <= u. If the user specifies an A
%   matrix that has more columns than the number of "x" (OPF) variables,
%   then there are extra linearly constrained "z" variables. For an
%   explanation of the formulation used and instructions for forming the
%   A matrix, see the manual.
%
%   A generalized cost on all variables can be applied if input arguments
%   N, fparm, H and Cw are specified.  First, a linear transformation
%   of the optimization variables is defined by means of r = N * [x; z].
%   Then, to each element of r a function is applied as encoded in the
%   fparm matrix (see manual). If the resulting vector is named w,
%   then H and Cw define a quadratic cost on w: (1/2)*w'*H*w + Cw * w .
%   H and N should be sparse matrices and H should also be symmetric.
%
%   The optional mpopt vector specifies MATPOWER options. See MPOPTION
%   for details and default values.

%   MATPOWER
%   $Id: opf_args.m 1635 2010-04-26 19:45:26Z ray $
%   by Ray Zimmerman, PSERC Cornell
%   and Carlos E. Murillo-Sanchez, PSERC Cornell & Universidad Autonoma de Manizales
%   Copyright (c) 1996-2010 by Power System Engineering Research Center (PSERC)
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

if nargout == 2
  want_mpc = 1;
else
  want_mpc = 0;
end
userfcn = [];
if ischar(baseMVA) || isstruct(baseMVA)  %% passing filename or struct
  %---- opf(baseMVA,  bus,     gen, branch, areas, gencost, Au,    lbu, ubu, mpopt, N,  fparm, H, Cw, z0, zl, zu)
  % 12  opf(casefile, Au,      lbu, ubu,    mpopt, N,       fparm, H,   Cw,  z0,    zl, zu)
  % 9   opf(casefile, Au,      lbu, ubu,    mpopt, N,       fparm, H,   Cw)
  % 5   opf(casefile, Au,      lbu, ubu,    mpopt)
  % 4   opf(casefile, Au,      lbu, ubu)
  % 3   opf(casefile, userfcn, mpopt)
  % 2   opf(casefile, mpopt)
  % 1   opf(casefile)
  if any(nargin == [1, 2, 3, 4, 5, 9, 12])
    casefile = baseMVA;
    if nargin == 12
      zu    = fparm;
      zl    = N;
      z0    = mpopt;
      Cw    = ubu;
      H     = lbu;
      fparm = Au;
      N     = gencost;
      mpopt = areas;
      ubu   = branch;
      lbu   = gen;
      Au    = bus;
    elseif nargin == 9
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = ubu;
      H     = lbu;
      fparm = Au;
      N     = gencost;
      mpopt = areas;
      ubu   = branch;
      lbu   = gen;
      Au    = bus;
    elseif nargin == 5
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = areas;
      ubu   = branch;
      lbu   = gen;
      Au    = bus;
    elseif nargin == 4
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = mpoption;
      ubu   = branch;
      lbu   = gen;
      Au    = bus;
    elseif nargin == 3
      userfcn = bus;
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = gen;
      ubu   = [];
      lbu   = [];
      Au    = sparse(0,0);
    elseif nargin == 2
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = bus;
      ubu   = [];
      lbu   = [];
      Au    = sparse(0,0);
    elseif nargin == 1
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = mpoption;
      ubu   = [];
      lbu   = [];
      Au    = sparse(0,0);
    end
  else
    error('opf_args.m: Incorrect input parameter order, number or type');
  end
  mpc = loadcase(casefile);
  [baseMVA, bus, gen, branch, gencost] = ...
    deal(mpc.baseMVA, mpc.bus, mpc.gen, mpc.branch, mpc.gencost);
  if isfield(mpc, 'areas')
    areas = mpc.areas;
  else
    areas = [];
  end
  if isempty(Au) && isfield(mpc, 'A')
    [Au, lbu, ubu] = deal(mpc.A, mpc.l, mpc.u);
  end
  if isempty(N) && isfield(mpc, 'N')             %% these two must go together
    [N, Cw] = deal(mpc.N, mpc.Cw);
  end
  if isempty(H) && isfield(mpc, 'H')             %% will default to zeros
    H = mpc.H;
  end
  if isempty(fparm) && isfield(mpc, 'fparm')     %% will default to [1 0 0 1]
    fparm = mpc.fparm;
  end
  if isempty(z0) && isfield(mpc, 'z0')
    z0 = mpc.z0;
  end
  if isempty(zl) && isfield(mpc, 'zl')
    zl = mpc.zl;
  end
  if isempty(zu) && isfield(mpc, 'zu')
    zu = mpc.zu;
  end
  if isempty(userfcn) && isfield(mpc, 'userfcn')
    userfcn = mpc.userfcn;
  end
else    %% passing individual data matrices
  %---- opf(baseMVA, bus, gen, branch, areas, gencost, Au,      lbu, ubu, mpopt, N, fparm, H, Cw, z0, zl, zu)
  % 17  opf(baseMVA, bus, gen, branch, areas, gencost, Au,      lbu, ubu, mpopt, N, fparm, H, Cw, z0, zl, zu)
  % 14  opf(baseMVA, bus, gen, branch, areas, gencost, Au,      lbu, ubu, mpopt, N, fparm, H, Cw)
  % 10  opf(baseMVA, bus, gen, branch, areas, gencost, Au,      lbu, ubu, mpopt)
  % 9   opf(baseMVA, bus, gen, branch, areas, gencost, Au,      lbu, ubu)
  % 8   opf(baseMVA, bus, gen, branch, areas, gencost, userfcn, mpopt)
  % 7   opf(baseMVA, bus, gen, branch, areas, gencost, mpopt)
  % 6   opf(baseMVA, bus, gen, branch, areas, gencost)
  if any(nargin == [6, 7, 8, 9, 10, 14, 17])
    if nargin == 14
      zu    = [];
      zl    = [];
      z0    = [];
    elseif nargin == 10
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
    elseif nargin == 9
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = mpoption;
    elseif nargin == 8
      userfcn = Au;
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = lbu;
      ubu   = [];
      lbu   = [];
      Au    = sparse(0,0);
    elseif nargin == 7
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = Au;
      ubu   = [];
      lbu   = [];
      Au    = sparse(0,0);
    elseif nargin == 6
      zu    = [];
      zl    = [];
      z0    = [];
      Cw    = [];
      H     = sparse(0,0);
      fparm = [];
      N     = sparse(0,0);
      mpopt = mpoption;
      ubu   = [];
      lbu   = [];
      Au    = sparse(0,0);
    end
  else
    error('opf_args.m: Incorrect input parameter order, number or type');
  end
  if want_mpc
    mpc = struct(             ...
            'baseMVA',  baseMVA,    ...
            'bus',      bus,        ...
            'gen',      gen,        ...
            'branch',   branch,     ...
            'gencost',  gencost    ...
    );
  end
end
nw = size(N, 1);
if nw
  if size(Cw, 1) ~= nw
    error('opf_args.m: dimension mismatch between N and Cw in generalized cost parameters');
  end
  if ~isempty(fparm) && size(fparm, 1) ~= nw
    error('opf_args.m: dimension mismatch between N and fparm in generalized cost parameters');
  end
  if ~isempty(H) && (size(H, 1) ~= nw || size(H, 2) ~= nw)
    error('opf_args.m: dimension mismatch between N and H in generalized cost parameters');
  end
  if size(Au, 1) > 0 && size(N, 2) ~= size(Au, 2)
    error('opf_args.m: A and N must have the same number of columns');
  end
  %% make sure N and H are sparse
  if ~issparse(N)
    error('opf_args.m: N must be sparse in generalized cost parameters');
  end
  if ~issparse(H)
    error('opf_args.m: H must be sparse in generalized cost parameters');
  end
end
if ~issparse(Au)
  error('opf_args.m: Au must be sparse');
end
if isempty(mpopt)
  mpopt = mpoption;
end
if want_mpc
  if ~isempty(areas)
    mpc.areas = areas;
  end
  if ~isempty(Au)
    [mpc.A, mpc.l, mpc.u] = deal(Au, lbu, ubu);
  end
  if ~isempty(N)
    [mpc.N, mpc.Cw ] = deal(N, Cw);
    if ~isempty(fparm)
      mpc.fparm = fparm;
    end
    if ~isempty(H)
      mpc.H = H;
    end
  end
  if ~isempty(z0)
    mpc.z0 = z0;
  end
  if ~isempty(zl)
    mpc.zl = zl;
  end
  if ~isempty(zu)
    mpc.zu = zu;
  end
  if ~isempty(userfcn)
    mpc.userfcn = userfcn;
  end
  baseMVA = mpc;
  bus = mpopt;
end
