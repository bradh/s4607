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
    display_packets/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Record definitions.

-record(packet, {header, segments}).

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
    H1 = pheader:decode(Hdr),
    
    % The size in the header includes the header itself.
    PayloadSize = pheader:get_packet_size(H1) - byte_size(Hdr),
    
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
    H1 = pheader:decode(Hdr),
    %s4607:display_packet_header(H1),
    io:format("~n"),
    % The size in the header includes the header itself.
    PayloadSize = pheader:get_packet_size(H1) - byte_size(Hdr),
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
            {ok, MS} = mission:decode(SegData),
            mission:display(MS);
        dwell   ->
            {ok, DS} = dwell:decode(SegData),
            dwell:display(DS);
        job_definition ->
            {ok, JD} = job_def:decode(SegData),
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


