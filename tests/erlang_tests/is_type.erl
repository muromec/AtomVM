%
% This file is part of AtomVM.
%
% Copyright 2018 Davide Bettio <davide@uninstall.it>
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% SPDX-License-Identifier: Apache-2.0 OR LGPL-2.1-or-later
%

-module(is_type).

-export([start/0, test_is_type/8, all_true/8, quick_exit/0]).

start() ->
    Pid = spawn(?MODULE, quick_exit, []),
    test_is_type(hello, <<"hello">>, 10, [1, 2, 3], 5, Pid, make_ref(), {1, 2}).

test_is_type(A, B, I, L, N, P, R, T) ->
    all_true(
        is_atom(A),
        is_binary(B),
        is_integer(I),
        is_list(L),
        is_number(N),
        is_pid(P),
        is_reference(R),
        is_tuple(T)
    ).

all_true(true, true, true, true, true, true, true, true) ->
    255;
all_true(false, false, false, false, false, false, false, false) ->
    0;
all_true(_, _, _, _, _, _, _, _) ->
    -1.

quick_exit() ->
    ok.
