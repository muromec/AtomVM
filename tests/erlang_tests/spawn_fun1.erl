%
% This file is part of AtomVM.
%
% Copyright 2018-2019 Davide Bettio <davide@uninstall.it>
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

-module(spawn_fun1).

-export([start/0, loop/0]).

start() ->
    Pid = spawn(fun loop/0),
    Pid ! {self(), 21},
    Double =
        receive
            Any -> Any
        end,
    Pid ! terminate,
    Double.

loop() ->
    case handle_request() of
        ok ->
            loop();
        terminate ->
            terminate
    end.

handle_request() ->
    receive
        {Pid, N} ->
            Pid ! N * 2,
            ok;
        terminate ->
            terminate
    end.
