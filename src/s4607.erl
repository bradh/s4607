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
-module(s4607).

-export([
    read_file/1,
    decode/1,
    extract_packet_header/1,
    extract_packet_data/2,
    display_packets/1,
    decode_packet_header/1,
    decode_us_packet_code/1,
    display_packet_header/1,
    get_version_id/1,
    get_packet_size/1,
    get_nationality/1,
    get_classification/1,
    get_class_system/1,
    get_packet_code/1,
    get_exercise_indicator/1,
    get_platform_id/1,
    get_mission_id/1,
    get_job_id/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Record definitions.

-record(packet, {header, segments}).

-record(pheader, {
    version, 
    packet_size,
    nationality, 
    classification, 
    class_system, 
    packet_code, 
    exercise_ind, 
    platform_id, 
    mission_id, 
    job_id}).

%-record(segment, {header, data}).

%-record(decode_status, {status, error_list}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% File handling functions.

%% Function to read a file in Stanag 4607 format.
read_file(File) ->
    {ok, Bin} = file:read_file(File),
    Bin.

%% Function to decode binary data in Stanag 4607 packet format and return 
%% a structured representation i.e. a list of packets with nested segments
%% as appropriate.
decode(Bin) ->
    decode_packets(Bin, []).

decode_packets(<<>>, Acc) ->
    lists:reverse(Acc);
decode_packets(Bin, Acc) ->
    {ok, Hdr, R1} = extract_packet_header(Bin),
    H1 = s4607:decode_packet_header(Hdr),
    
    % The size in the header includes the header itself.
    PayloadSize = H1#pheader.packet_size - byte_size(Hdr),
    
    % Get the packet data payload.
    {ok, PktData, R2} = extract_packet_data(R1, PayloadSize),

    % Loop through all the segments in the packet.
    SegRecList = decode_segments(PktData, []),

    % Build the packet structure.
    Pkt = #packet{header = H1, segments = SegRecList}, 

    % Loop over any remaining packets, adding each to the list. 
    decode_packets(R2, [Pkt|Acc]).

decode_segments(<<>>, Acc) ->
    lists:reverse(Acc);
decode_segments(Bin, Acc) ->
    % Get the segment header.
    {ok, SegHdr, SRem} = extract_segment_header(Bin),
    SH = seg_header:decode(SegHdr),

    % The size in the header includes the header itself.
    PayloadSize = seg_header:get_segment_size(SH) - byte_size(SegHdr),

    % Get the packet data payload.
    {ok, SegData, SRem2} = extract_segment_data(SRem, PayloadSize),

    % Switch on the segment type
    case seg_header:get_segment_type(SH) of
        mission -> 
            SegRec = {ok, SH, mission:decode(SegData)};
        dwell   ->
            SegRec = {ok, SH, dwell:decode(SegData)};
        job_definition ->
            SegRec = {ok, SH, job_def:decode(SegData)};
        _       -> 
            SegRec = {unknown_segment, SH, SegData}
    end,

    % Loop over any remaining segments contained in this packet.
    decode_segments(SRem2, [SegRec|Acc]).

%display_packets2(PktLst) ->
%    lists:map(fun display_packet/1, PktList).

%display_packet(Pkt) ->
    
%% Packet processing loop, prints out decoded information.
display_packets(<<>>) ->
    ok;
display_packets(Bin) ->
    {ok, Hdr, R1} = extract_packet_header(Bin),
    H1 = s4607:decode_packet_header(Hdr),
    %s4607:display_packet_header(H1),
    io:format("~n"),
    % The size in the header includes the header itself.
    PayloadSize = H1#pheader.packet_size - byte_size(Hdr),
    io:format("size ~p, len ~p~n", [byte_size(R1), PayloadSize]),
    % Get the packet data payload.
    {ok, PktData, R2} = extract_packet_data(R1, PayloadSize),

    % Loop through all the segments in the packet.
    display_segments(PktData),

    % Loop over any remaining packets.
    display_packets(R2).

%% Display all the segments within a packet.
display_segments(<<>>) ->
    ok;
display_segments(Bin) ->
    % Get the segment header.
    {ok, SegHdr, SRem} = extract_segment_header(Bin),
    SH = seg_header:decode(SegHdr),
    seg_header:display(SH),
    io:format("~n"),

    % The size in the header includes the header itself.
    PayloadSize = seg_header:get_segment_size(SH) - byte_size(SegHdr),

    % Get the packet data payload.
    {ok, SegData, SRem2} = extract_segment_data(SRem, PayloadSize),

    % Switch on the segment type
    case seg_header:get_segment_type(SH) of
        mission -> 
            MS = mission:decode(SegData),
            mission:display(MS);
        dwell   ->
            DS = dwell:decode(SegData),
            dwell:display(DS);
        job_definition ->
            JD = job_def:decode(SegData),
            job_def:display(JD);
        _       -> 
            ok
    end,

    % Loop over any remaining segments contained in this packet.
    display_segments(SRem2).

%% Function to display a segment. Segment should have been decoded prior to 
%% calling this function.
display_segment(SegHdr, SegRec) ->
    seg_header:display(SegHdr),
    
    % Switch on the segment type and display the segment data.
    case seg_header:get_segment_type(SegHdr) of
        mission -> 
            mission:display(SegRec);
        dwell   ->
            dwell:display(SegRec);
        job_definition ->
            job_def:display(SegRec); 
        _       -> 
            ok
    end. 

%% Extracts the first portion of the binary of the size required for a packet
%% header. Returns the unused portion to allow further processing.
extract_packet_header(<<Hdr:32/binary,Rest/binary>>) ->
    {ok, Hdr, Rest}.

%% Extracts the data payload from a packet from the supplied binary
%% (which should have had the header removed already).
extract_packet_data(Bin, Len) ->
    sutils:extract_data(Bin, Len).

%% Extracts the first binary portion associated with a segment header.
extract_segment_header(<<Hdr:5/binary,Rest/binary>>) ->
    {ok, Hdr, Rest}.

%% Extracts the segment payload from the supplied binary
%% (which should have had the header removed already).
extract_segment_data(Bin, Len) ->
    sutils:extract_data(Bin, Len).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Packet header decoding functions.

%% Function to decode a Stanag 4607 packet header. 
decode_packet_header(<<P1:2/binary, PktSize:32/integer-unsigned-big, 
    P3:2/binary, P4, P5:2/binary, P6:16/integer-unsigned-big, P7, 
    P8:10/binary, P9:4/binary, P10:4/binary>>) ->

    Ver = decode_version(P1),
    Nat = decode_nationality(P3),

    % Don't crash if we don't recognise the classification.
    Class = case decode_classification(P4) of
                {ok, X} -> X;
                {unknown_classification, _} -> unknown_classification
            end,

    {ok, Sys} = decode_class_system(P5), 
    {ok, Code} = decode_us_packet_code(P6),
    {ok, Ex} = decode_exercise_indicator(P7),
    PlatId = decode_platform_id(P8),
    MissId = stanag_types:i32_to_integer(P9),
    JobId = stanag_types:i32_to_integer(P10),
    
    #pheader{version = Ver, packet_size = PktSize, nationality = Nat, 
        classification = Class, class_system = Sys, packet_code = Code, 
        exercise_ind = Ex, platform_id = PlatId, mission_id = MissId, 
        job_id = JobId}.

decode_version(<<M,N>>) ->
    {M - $0, N - $0}.

decode_nationality(<<X:2/binary>>) ->
    binary_to_list(X).

decode_classification(1) -> {ok, top_secret};
decode_classification(2) -> {ok, secret};
decode_classification(3) -> {ok, confidential};
decode_classification(4) -> {ok, restricted};
decode_classification(5) -> {ok, unclassified};
decode_classification(X) -> {unknown_classification, X}.

decode_class_system(<<"  ">>) ->
    {ok, none};
decode_class_system(<<X:2/binary>>) ->
    {ok, binary_to_list(X)}.

decode_us_packet_code(16#0000) -> {ok, none};
decode_us_packet_code(16#0001) -> {ok, nocontract};
decode_us_packet_code(16#0002) -> {ok, orcon};
decode_us_packet_code(16#0004) -> {ok, propin};
decode_us_packet_code(16#0008) -> {ok, wnintel};
decode_us_packet_code(16#0010) -> {ok, national_only};
decode_us_packet_code(16#0020) -> {ok, limdis};
decode_us_packet_code(16#0040) -> {ok, fouo};
decode_us_packet_code(16#0080) -> {ok, efto};
decode_us_packet_code(16#0100) -> {ok, lim_off_use};
decode_us_packet_code(16#0200) -> {ok, noncompartment};
decode_us_packet_code(16#0400) -> {ok, special_control};
decode_us_packet_code(16#0800) -> {ok, special_intel};
decode_us_packet_code(16#1000) -> {ok, warning_notice};
decode_us_packet_code(16#2000) -> {ok, rel_nato};
decode_us_packet_code(16#4000) -> {ok, rel_4_eyes};
decode_us_packet_code(16#8000) -> {ok, rel_9_eyes};
decode_us_packet_code(_) -> {error, unknown_packet_code}.

decode_exercise_indicator(0) -> {ok, operation_real};
decode_exercise_indicator(1) -> {ok, operation_simulated};
decode_exercise_indicator(2) -> {ok, operation_synthesized};
decode_exercise_indicator(128) -> {ok, exercise_real};
decode_exercise_indicator(129) -> {ok, exercise_simulated};
decode_exercise_indicator(130) -> {ok, exercise_synthesized};
decode_exercise_indicator(_) -> {error, reserved}.

decode_platform_id(<<X:10/binary>>) ->
    sutils:trim_trailing_spaces(binary_to_list(X)).

display_packet_header(PktHdr) ->
    io:format("Version: ~p~n", [get_version_id(PktHdr)]),
    io:format("Packet size: ~p~n", [get_packet_size(PktHdr)]), 
    io:format("Nationality: ~p~n", [get_nationality(PktHdr)]),
    io:format("Classification: ~p~n", [get_classification(PktHdr)]),
    io:format("Classification System: ~p~n", [get_class_system(PktHdr)]),
    io:format("Packet code: ~p~n", [get_packet_code(PktHdr)]),
    io:format("Exercise Indication: ~p~n", [get_exercise_indicator(PktHdr)]),
    io:format("Platform ID: ~p~n", [get_platform_id(PktHdr)]),
    io:format("Mission ID: ~p~n", [get_mission_id(PktHdr)]),
    io:format("Job ID: ~p~n", [get_job_id(PktHdr)]).

%% Get the version ID from a packet header
get_version_id(#pheader{version = V}) -> V.

%% Get the packet size from the header. 
get_packet_size(#pheader{packet_size = S}) -> S.

%% Get the nationality from a header structure.
get_nationality(#pheader{nationality = N}) -> N.

%% Get the classification level
get_classification(#pheader{classification = C}) -> C.

%% Get the classification system from the header. 
get_class_system(#pheader{class_system = X}) -> X.

%% Get the packet security code from the header.
get_packet_code(#pheader{packet_code = X}) -> X.

%% Get the exercise indicator from the header structure.
get_exercise_indicator(#pheader{exercise_ind = X}) -> X.

%% Get the platform ID from the header structure.
get_platform_id(#pheader{platform_id = X}) -> X.

%% Get the mission ID from the header structure.
get_mission_id(#pheader{mission_id = X}) -> X.

%% Get the job ID from the header structure.
get_job_id(#pheader{job_id = X}) -> X.


