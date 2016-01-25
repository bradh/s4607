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
-module(sutils).

-export([
    trim_trailing_spaces/1,
    conditional_extract/5,
    conditional_display/3,
    extract_data/2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Utility functions

trim_trailing_spaces(Str) ->
    Rev = lists:reverse(Str),
    F = fun(C) -> C =:= $\  end,
    RStrip = lists:dropwhile(F, Rev),
    lists:reverse(RStrip).

%% Function to conditionally extract a paramater from the front of a binary
%% based on the state of a mask bit.
conditional_extract(Bin, MaskBit, Size, ConvFn, Default) ->
    case MaskBit of
        1 -> 
            {ok, Param, Bin1} = extract_data(Bin, Size),
            {ConvFn(Param), Bin1};
        0 ->
            {Default, Bin}
    end.

%% Function to conditionally display a parameter based on a mask bit
conditional_display(FmtStr, Params, MaskBit) ->
    case MaskBit of
        1 ->
            io:format(FmtStr, Params),
            ok;
        0 ->
            ok
    end.

%% Generic function to take the first part of a binary and return the rest.
extract_data(Bin, Len) ->
    Data = binary:part(Bin, 0, Len),
    Rem = binary:part(Bin, Len, (byte_size(Bin) - Len)),
    {ok, Data, Rem}.

