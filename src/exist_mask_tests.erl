%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2016 Pentland Edge Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License"); you may not
%% use this file except in compliance with the License. 
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software 
%% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
%% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
%% License for the specific language governing permissions and limitations 
%% under the License.
%%

-module(exist_mask_tests).

-include_lib("eunit/include/eunit.hrl").

%% Define a test generator for the existence mask. 
exist_mask_test_() ->
    [exist_mask_checks()].

exist_mask_checks() ->
    EM = exist_mask:new([spu_cross_track]), 
    [?_assertEqual(1, exist_mask:get_spu_cross_track(EM)),
     ?_assertEqual(0, exist_mask:get_target_rcs(EM))].


