function t_nested_struct_copy(quiet)
%T_NESTED_STUCT_COPY  Tests for NESTED_STUCT_COPY.

%   MATPOWER
%   $Id: t_nested_struct_copy.m 2336 2014-06-17 20:07:13Z ray $
%   by Ray Zimmerman, PSERC Cornell
%   Copyright (c) 2013 by Power System Engineering Research Center (PSERC)
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

if nargin < 1
    quiet = 0;
end

t_begin(9, quiet);

%% set up some structs
D = struct( ...
    'a', 1, ...
    'b', struct( ...
        'd', [2;3], ...
        'e', 4), ...
    'c', struct( ...
        'f', {{'hello', 'world'}}, ...
        'g', 'bye'));

S = struct( ...
    'a', 10, ...
    'b', struct(...
        'x', 100, ...
        'y', 200), ...
    'c', struct( ...
        'g', 'chau', ...
        'h', 'oops'), ...
    'u', struct( ...
        'v', -1, ...
        'w', -2) );

%% default
t = 'DS = nested_struct_copy(D, S)';
DS = nested_struct_copy(D, S);
E = struct( ...
    'a', 10, ...
    'b', struct( ...
        'd', [2;3], ...
        'e', 4, ...
        'x', 100, ...
        'y', 200), ...
    'c', struct( ...
        'f', {{'hello', 'world'}}, ...
        'g', 'chau', ...
        'h', 'oops'), ...
    'u', struct( ...
        'v', -1, ...
        'w', -2 ) );
t_ok(isequal(DS, E), t);

t = 'check = 0';
opt = struct('check', 0);
DS = nested_struct_copy(D, S, opt);
t_ok(isequal(DS, E), t);

t = 'check = -1';
opt = struct('check', -1);
DS = nested_struct_copy(D, S, opt);
E = struct( ...
    'a', 10, ...
    'b', struct( ...
        'd', [2;3], ...
        'e', 4), ...
    'c', struct( ...
        'f', {{'hello', 'world'}}, ...
        'g', 'chau'));
t_ok(isequal(DS, E), t);

t = 'check = 1 ==> error';
opt = struct('check', 1);
if have_fcn('octave')
    %% Octave 3.4 and earlier do not support 'catch me'
    try
        DS = nested_struct_copy(D, S, opt);
        t_ok(0, t);
    catch
        me = lasterr;
        TorF = strcmp(me, 'nested_struct_copy: ''b.x'' is not a valid field name');
        t_ok(TorF, t);
        if ~TorF
            me
        end
    end
else
    try
        DS = nested_struct_copy(D, S, opt);
        t_ok(0, t);
    catch me
        TorF = strcmp(me.message, 'nested_struct_copy: ''b.x'' is not a valid field name');
        t_ok(TorF, t);
        if ~TorF
            me
        end
    end
end

t = 'check = 1, copy_mode = ''=''';
S2 = rmfield(S, 'u');
opt = struct('check', 1, 'copy_mode', '=');
DS = nested_struct_copy(D, S2, opt);
t_ok(isequal(DS, S2), t);

t = 'exceptions = <''b'', ''=''>';
ex = struct('name', 'b', 'copy_mode', '=');
opt = struct('exceptions', ex);
DS = nested_struct_copy(D, S2, opt);
E = struct( ...
    'a', 10, ...
    'b', struct( ...
        'x', 100, ...
        'y', 200), ...
    'c', struct( ...
        'f', {{'hello', 'world'}}, ...
        'g', 'chau', ...
        'h', 'oops'));
t_ok(isequal(DS, E), t);

t = 'exceptions = <''b'', ''=''>, <''c'', ''=''>';
ex = struct('name', {'b', 'c'}, 'copy_mode', {'=', '='});
opt = struct('exceptions', ex);
DS = nested_struct_copy(D, S2, opt);
t_ok(isequal(DS, S2), t);

t = 'exceptions = <''b'', ''=''>, <''c.g'', @upper>';
ex = struct('name', {'b', 'c.g'}, 'copy_mode', {'=', @upper});
opt = struct('exceptions', ex);
DS = nested_struct_copy(D, S2, opt);
E = struct( ...
    'a', 10, ...
    'b', struct( ...
        'x', 100, ...
        'y', 200), ...
    'c', struct( ...
        'f', {{'hello', 'world'}}, ...
        'g', 'CHAU', ...
        'h', 'oops'));
t_ok(isequal(DS, E), t);

t = 'check = 1, exceptions = <''b'', ck=-1>, <''c'', ck=0>';
ex = struct('name', {'b', 'c'}, 'check', {-1,0});
opt = struct('check', 1, 'exceptions', ex);
DS = nested_struct_copy(D, S2, opt);
E = struct( ...
    'a', 10, ...
    'b', struct( ...
        'd', [2;3], ...
        'e', 4), ...
    'c', struct( ...
        'f', {{'hello', 'world'}}, ...
        'g', 'chau', ...
        'h', 'oops'));
t_ok(isequal(DS, E), t);


% DS
% DS.b
% DS.c
% 
% E
% E.b
% E.c

t_end;
