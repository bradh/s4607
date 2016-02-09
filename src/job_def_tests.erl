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

-module(job_def_tests).

-export([sample_job_def/0]).

-include_lib("eunit/include/eunit.hrl").

%% Define a test generator for the decoding of the mission segment. 
job_def_test_() ->
    [job1_checks(), job_def_encode_decode()].

job1_checks() ->
    {ok, JD1} = job_def:decode(job_def1()),
    [?_assertEqual(16909060, job_def:get_job_id(JD1)),
     ?_assertEqual(global_hawk_sensor, job_def:get_sensor_id_type(JD1)),
     ?_assertEqual("Model1", job_def:get_sensor_id_model(JD1)),
     ?_assertEqual(no_filtering, job_def:get_target_filt_flag(JD1)),
     ?_assertEqual(23, job_def:get_priority(JD1)),
     ?_assertEqual(flat_earth, job_def:get_geoid_model(JD1))].

job_def_encode_decode() ->
    JD = sample_job_def(),
    EJD = job_def:encode(JD),
    {ok, DEJD} = job_def:decode(EJD),
    Delta = 0.00001,
    [?_assertEqual(100, job_def:get_job_id(DEJD)),
     ?_assertEqual(rotary_wing_radar, job_def:get_sensor_id_type(DEJD)),
     ?_assertEqual("Heli 1", job_def:get_sensor_id_model(DEJD)),
     ?_assertEqual(no_filtering, job_def:get_target_filt_flag(DEJD)),
     ?_assertEqual(30, job_def:get_priority(DEJD)),
     ?_assert(almost_equal(33.3, job_def:get_bounding_a_lat(DEJD), Delta)),
     ?_assert(almost_equal(3.45, job_def:get_bounding_a_lon(DEJD), Delta)),
     ?_assert(almost_equal(23.4, job_def:get_bounding_b_lat(DEJD), Delta)),
     ?_assert(almost_equal(350.0, job_def:get_bounding_b_lon(DEJD), Delta)),
     ?_assert(almost_equal(-45.0, job_def:get_bounding_c_lat(DEJD), Delta)),
     ?_assert(almost_equal(2.45, job_def:get_bounding_c_lon(DEJD), Delta)),
     ?_assert(almost_equal(-60.0, job_def:get_bounding_d_lat(DEJD), Delta)),
     ?_assert(almost_equal(140.0, job_def:get_bounding_d_lon(DEJD), Delta)),

     ?_assertEqual({monopulse_calibration, asars_aip}, job_def:get_radar_mode(DEJD)),
     ?_assertEqual(100, job_def:get_ns_val_det_prob(DEJD)),
     ?_assertEqual(254, job_def:get_ns_val_false_alarm_density(DEJD)),
     ?_assertEqual(dgm50, job_def:get_terr_elev_model(DEJD)),
     ?_assertEqual(geo96, job_def:get_geoid_model(DEJD))].


job_def1() ->
    <<1,2,3,4, 5, "Model1", 0, 23, 
      64,0,0,0, "õUUU", 64,0,0,0, "õUUU", 64,0,0,0, "õUUU", 64,0,0,0, "õUUU",
      1, 1,0, 255,255, 1,0, 16#27,16#10, 45, 0,128, 
      255,255, 127,74, 0,100, 5, 90, 3, 1, 3>>.

sample_job_def() ->
    P = [{job_id, 100}, {sensor_id_type, rotary_wing_radar},
         {sensor_id_model, "Heli 1"}, {target_filt_flag, no_filtering}, {priority, 30},
         {bounding_a_lat, 33.3}, {bounding_a_lon, 3.45},
         {bounding_b_lat, 23.4}, {bounding_b_lon, 350},
         {bounding_c_lat, -45.0}, {bounding_c_lon, 2.45},
         {bounding_d_lat, -60.0}, {bounding_d_lon, 140},
         {radar_mode, {monopulse_calibration, asars_aip}}, {nom_rev_int, 65000},
         {ns_pos_unc_along_track, no_statement}, 
         {ns_pos_unc_cross_track, 5000}, {ns_pos_unc_alt, 20000},
         {ns_pos_unc_heading, 45}, {ns_pos_unc_sensor_speed, 65534},
         {ns_val_slant_range_std_dev, 100}, 
         {ns_val_cross_range_std_dev, no_statement},
         {ns_val_tgt_vel_los_std_dev, 4000}, {ns_val_mdv, no_statement},
         {ns_val_det_prob, 100}, {ns_val_false_alarm_density, 254},
         {terr_elev_model, dgm50}, {geoid_model, geo96}],

    job_def:new(P).

%% Utility function to compare whether floating point values are within a 
%% specified range.
almost_equal(V1, V2, Delta) ->
    abs(V1 - V2) =< Delta.
 
