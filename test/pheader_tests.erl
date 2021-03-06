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

-module(pheader_tests).

-include_lib("eunit/include/eunit.hrl").

%% Define a test generator for the decoding of the packet header fields. 
pheader_test_() ->
    [version_checks(), size_checks(), nationality_checks(), class_checks(), 
     class_sys_checks(), sec_code_checks(), enc_sec_code_checks(),  
     exercise_ind_checks(), encode_exercise_ind_checks(), 
     platform_id_checks(), mission_id_checks(), job_id_checks(), 
     encode_decode_check1(), default_new_checks(), enc_class_checks(), 
     class_sys_checks()].

version_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual({1,2}, pheader:get_version_id(Hdr1))].

nationality_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual("UK", pheader:get_nationality(Hdr1))].

size_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual(32, pheader:get_packet_size(Hdr1))].
    
class_checks() -> 
    {ok, Hdr1} = pheader:decode(sample_header1()),
    {ok, Hdr2} = pheader:decode(sample_header2()),
    [?_assertEqual(top_secret, pheader:get_classification(Hdr1)),
     ?_assertEqual(no_classification, pheader:get_classification(Hdr2)),
     ?_assertEqual({ok, secret}, pheader:decode_classification(2)),
     ?_assertEqual({ok, confidential}, pheader:decode_classification(3)),
     ?_assertEqual({ok, restricted}, pheader:decode_classification(4)),
     ?_assertEqual({ok, unclassified}, pheader:decode_classification(5)),
     ?_assertEqual({unknown_classification, 7}, pheader:decode_classification(7))].

class_sys_checks() -> 
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual("XN", pheader:get_class_system(Hdr1)),
     ?_assertEqual(<<"  ">>, pheader:encode_class_system(none)),
     ?_assertEqual({ok, none}, pheader:decode_class_system(<<"  ">>))].

sec_code_checks() -> 
    {ok, Hdr1} = pheader:decode(sample_header1()),
    {ok, Hdr2} = pheader:decode(sample_header2()),
    [?_assertEqual(nocontract, pheader:get_packet_code(Hdr1)),
     ?_assertEqual(orcon, pheader:get_packet_code(Hdr2)),
     ?_assertEqual({ok, none}, pheader:decode_us_packet_code(0)),
     ?_assertEqual({ok, propin}, pheader:decode_us_packet_code(4)),
     ?_assertEqual({ok, wnintel}, pheader:decode_us_packet_code(8)),
     ?_assertEqual({ok, national_only}, pheader:decode_us_packet_code(16#10)),
     ?_assertEqual({ok, limdis}, pheader:decode_us_packet_code(16#20)),
     ?_assertEqual({ok, fouo}, pheader:decode_us_packet_code(16#40)),
     ?_assertEqual({ok, efto}, pheader:decode_us_packet_code(16#80)),
     ?_assertEqual({ok, lim_off_use}, pheader:decode_us_packet_code(16#100)),
     ?_assertEqual({ok, noncompartment}, pheader:decode_us_packet_code(16#200)),
     ?_assertEqual({ok, special_control}, pheader:decode_us_packet_code(16#400)),
     ?_assertEqual({ok, special_intel}, pheader:decode_us_packet_code(16#800)),
     ?_assertEqual({ok, warning_notice}, pheader:decode_us_packet_code(16#1000)),
     ?_assertEqual({ok, rel_nato}, pheader:decode_us_packet_code(16#2000)),
     ?_assertEqual({ok, rel_4_eyes}, pheader:decode_us_packet_code(16#4000)),
     ?_assertEqual({ok, rel_9_eyes}, pheader:decode_us_packet_code(16#8000)),
     ?_assertEqual({error, unknown_packet_code}, pheader:decode_us_packet_code(3))].

enc_sec_code_checks() -> 
    [?_assertEqual(<<16#0000:16>>, pheader:encode_us_packet_code(none)),
     ?_assertEqual(<<16#0001:16>>, pheader:encode_us_packet_code(nocontract)),
     ?_assertEqual(<<16#0002:16>>, pheader:encode_us_packet_code(orcon)),
     ?_assertEqual(<<16#0004:16>>, pheader:encode_us_packet_code(propin)),
     ?_assertEqual(<<16#0008:16>>, pheader:encode_us_packet_code(wnintel)),
     ?_assertEqual(<<16#0010:16>>, pheader:encode_us_packet_code(national_only)),
     ?_assertEqual(<<16#0020:16>>, pheader:encode_us_packet_code(limdis)),
     ?_assertEqual(<<16#0040:16>>, pheader:encode_us_packet_code(fouo)),
     ?_assertEqual(<<16#0080:16>>, pheader:encode_us_packet_code(efto)),
     ?_assertEqual(<<16#0100:16>>, pheader:encode_us_packet_code(lim_off_use)),
     ?_assertEqual(<<16#0200:16>>, pheader:encode_us_packet_code(noncompartment)),
     ?_assertEqual(<<16#0400:16>>, pheader:encode_us_packet_code(special_control)),
     ?_assertEqual(<<16#0800:16>>, pheader:encode_us_packet_code(special_intel)),
     ?_assertEqual(<<16#1000:16>>, pheader:encode_us_packet_code(warning_notice)),
     ?_assertEqual(<<16#2000:16>>, pheader:encode_us_packet_code(rel_nato)),
     ?_assertEqual(<<16#4000:16>>, pheader:encode_us_packet_code(rel_4_eyes)),
     ?_assertEqual(<<16#8000:16>>, pheader:encode_us_packet_code(rel_9_eyes))].

exercise_ind_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    {ok, Hdr2} = pheader:decode(sample_header2()),
    [?_assertEqual(exercise_real, pheader:get_exercise_indicator(Hdr1)),
     ?_assertEqual(exercise_simulated, pheader:get_exercise_indicator(Hdr2)),
     ?_assertEqual({ok, operation_real}, pheader:decode_exercise_indicator(0)),
     ?_assertEqual({ok, operation_simulated}, pheader:decode_exercise_indicator(1)),
     ?_assertEqual({ok, operation_synthesized}, pheader:decode_exercise_indicator(2)),
     ?_assertEqual({ok, exercise_synthesized}, pheader:decode_exercise_indicator(130)),
     ?_assertEqual({error, reserved}, pheader:decode_exercise_indicator(3))].

encode_exercise_ind_checks() ->
    [?_assertEqual(<<0>>, pheader:encode_exercise_indicator(operation_real)),
     ?_assertEqual(<<1>>, pheader:encode_exercise_indicator(operation_simulated)),
     ?_assertEqual(<<2>>, pheader:encode_exercise_indicator(operation_synthesized)),
     ?_assertEqual(<<128>>, pheader:encode_exercise_indicator(exercise_real)),
     ?_assertEqual(<<129>>, pheader:encode_exercise_indicator(exercise_simulated)),
     ?_assertEqual(<<130>>, pheader:encode_exercise_indicator(exercise_synthesized))].

platform_id_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual("ABCDEFGHIJ", pheader:get_platform_id(Hdr1))].

mission_id_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual(5, pheader:get_mission_id(Hdr1))].
    
job_id_checks() ->
    {ok, Hdr1} = pheader:decode(sample_header1()),
    [?_assertEqual(6, pheader:get_job_id(Hdr1))].

encode_decode_check1() ->
    PL = [{version, {3, 1}}, {packet_size, 250}, {nationality, "UK"},
          {classification, top_secret}, {class_system, "UK"}, 
          {packet_code, rel_9_eyes}, {exercise_ind, operation_real},
          {platform_id, "Pico1"}, {mission_id, 16#11223344},
          {job_id, 16#55667788}],

    % Construct a new packet header from the parameter list.
    PH = pheader:new(PL),   

    % Encode the header into binary form.
    EPH = pheader:encode(PH),

    % Decode it again
    {ok, DEPH} = pheader:decode(EPH),

    % Check the parameters in the decoded version are as expected.
    [?_assertEqual({3, 1}, pheader:get_version_id(DEPH)),
     ?_assertEqual(250, pheader:get_packet_size(DEPH)),
     ?_assertEqual("UK", pheader:get_nationality(DEPH)),
     ?_assertEqual(top_secret, pheader:get_classification(DEPH)),
     ?_assertEqual("UK", pheader:get_class_system(DEPH)),
     ?_assertEqual(rel_9_eyes, pheader:get_packet_code(DEPH)),
     ?_assertEqual(operation_real, pheader:get_exercise_indicator(DEPH)),
     ?_assertEqual("Pico1", pheader:get_platform_id(DEPH)),
     ?_assertEqual(16#11223344, pheader:get_mission_id(DEPH)),
     ?_assertEqual(16#55667788, pheader:get_job_id(DEPH))].
    
default_new_checks() ->
    % Create a new packet header with the default parameters.
    PH = pheader:new([]),

    % Display it (IO will be swallowed by eunit but at least exercises the 
    % diplay routine.
    pheader:display(PH),

    % Check the parameters in the decoded version are as expected.
    [?_assertEqual({3, 0}, pheader:get_version_id(PH)),
     ?_assertEqual(32, pheader:get_packet_size(PH)),
     ?_assertEqual("XN", pheader:get_nationality(PH)),
     ?_assertEqual(unclassified, pheader:get_classification(PH)),
     ?_assertEqual("  ", pheader:get_class_system(PH)),
     ?_assertEqual(none, pheader:get_packet_code(PH)),
     ?_assertEqual(exercise_real, pheader:get_exercise_indicator(PH)),
     ?_assertEqual("", pheader:get_platform_id(PH)),
     ?_assertEqual(0, pheader:get_mission_id(PH)),
     ?_assertEqual(0, pheader:get_job_id(PH))].

enc_class_checks() ->
    [?_assertEqual(1, pheader:enc_class(top_secret)),
     ?_assertEqual(2, pheader:enc_class(secret)),
     ?_assertEqual(3, pheader:enc_class(confidential)),
     ?_assertEqual(4, pheader:enc_class(restricted)),
     ?_assertEqual(5, pheader:enc_class(unclassified)),
     ?_assertEqual(6, pheader:enc_class(no_classification))].

%% Sample packet header for test data.
sample_header1() ->
    <<"12",0,0,0,32, "UK", 1, "XN", 0, 1, 128, "ABCDEFGHIJ", 0, 0, 0, 5, 0, 0, 0, 6>>.

sample_header2() ->
    <<"12",0,0,0,32, "UK", 6, "XN", 0, 2, 129, "ABCDEFGHIJ", 0, 0, 0, 5, 0, 0, 0, 6>>.

