%
% This file is part of AtomVM.
%
% Copyright 2022 Davide Bettio <davide@uninstall.it>
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

-module(test_time_and_processes).
-export([start/0]).

-include("intervals.hrl").

start() ->
    Ref1 = erlang:make_ref(),
    Ref2 = erlang:make_ref(),
    T1 = erlang:system_time(millisecond),
    Pid1 = spawn(mod_a, proc1, [self(), Ref1]),
    Pid2 = spawn(mod_b, proc2, [self(), Ref2]),
    receive
        {foo2, Pid2, [Ref2]} -> ok
    end,
    T2 = erlang:system_time(millisecond),
    receive
        {foo1, Pid1, [Ref1]} -> ok
    end,
    T3 = erlang:system_time(millisecond),
    eval_time(T3 - T1, ?INTERVAL_1, 2) +
        eval_time(T2 - T1, ?INTERVAL_2, 4).

eval_time(I, Interval, _Num) when I < Interval ->
    0;
eval_time(_I, _Interval, Num) ->
    Num.
