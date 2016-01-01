-module(stanag_types).

-export([
    i8_to_integer/1,
    integer_to_i8/1,
    i16_to_integer/1,
    integer_to_i16/1,
    i32_to_integer/1,
    integer_to_i32/1,
    s8_to_integer/1,
    integer_to_s8/1,
    s16_to_integer/1,
    integer_to_s16/1,
    s32_to_integer/1,
    integer_to_s32/1,
    s64_to_integer/1,
    integer_to_s64/1,
    b16_to_float/1,
    float_to_b16/1,
    b32_to_float/1,
    float_to_b32/1,
    h32_to_float/1,
    float_to_h32/1,
    ba16_to_float/1,
    float_to_ba16/1,
    ba32_to_float/1,
    float_to_ba32/1,
    sa16_to_float/1,
    float_to_sa16/1,
    sa32_to_float/1,
    float_to_sa32/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Unsigned integer type conversion functions. 

%% Function to convert unsigned I8 binary to an integer.
i8_to_integer(<<X>>) -> X.

%% Function to convert an unsigned integer to fixed width I8 binary.
integer_to_i8(I) when I >= 0, I =< 255 ->
    <<I:8/integer-unsigned-big>>.

%% Function to convert unsigned I16 binary to an integer.
i16_to_integer(<<X:16/integer-unsigned-big>>) -> X.

%% Function to convert an unsigned integer to fixed width I16 binary.
integer_to_i16(I) when I >= 0, I =< 65535 ->
    <<I:16/integer-unsigned-big>>.

%% Function to convert unsigned I32 binary to an integer.
i32_to_integer(<<X:32/integer-unsigned-big>>) -> X.

%% Function to convert an unsigned integer to fixed width I32 binary.
integer_to_i32(I) when I >= 0, I =< 4294967296 ->
    <<I:32/integer-unsigned-big>>.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Signed integer type conversion functions. 

s8_to_integer(<<X:8/integer-signed-big>>) -> X.

integer_to_s8(I) when I >= -128, I =< 127 ->
    <<I:8/integer-signed-big>>.

s16_to_integer(<<X:16/integer-signed-big>>) -> X.

integer_to_s16(I) when I >= -32768, I =< 32767 ->
    <<I:16/integer-signed-big>>.

s32_to_integer(<<X:32/integer-signed-big>>) -> X.

integer_to_s32(I) when I >= -2147483648, I =< 2147483647 ->
    <<I:32/integer-signed-big>>.

s64_to_integer(<<X:64/integer-signed-big>>) -> X.

integer_to_s64(I) when I >= -9223372036854775808, I =< 9223372036854775807 ->
    <<I:64/integer-signed-big>>.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Signed binary decimal conversion functions.

b16_to_float(<<S:1,I:8/integer-unsigned,F:7/integer-unsigned>>) ->
    Val = I + F / 128.0,
    case S of 
        1 -> -Val;
        0 -> Val
    end.

float_to_b16(X) when X >= 0 ->
    Scaled = round(X * 128),
    <<Scaled:16/integer-unsigned-big>>;
float_to_b16(X) ->
    Scaled = round(abs(X) * 128),
    <<1:1,Scaled:15/integer-unsigned-big>>.

b32_to_float(<<S:1,I:8/integer-unsigned,F:23/integer-unsigned>>) ->
    Val = I + F / 8388608.0,
    case S of 
        1 -> -Val;
        0 -> Val
    end.

float_to_b32(X) when X >= 0 ->
    Scaled = round(X * 8388608),
    <<Scaled:32/integer-unsigned-big>>;
float_to_b32(X) ->
    Scaled = round(abs(X) * 8388608),
    <<1:1,Scaled:31/integer-unsigned-big>>.

h32_to_float(<<S:1,I:15/integer-unsigned,F:16/integer-unsigned>>) ->
    Val = I + F / 65536.0,
    case S of 
        1 -> -Val;
        0 -> Val
    end.

float_to_h32(X) when X >= 0 ->
    Scaled = round(X * 65536),
    <<Scaled:32/integer-unsigned-big>>;
float_to_h32(X) ->
    Scaled = round(abs(X) * 65536),
    <<1:1,Scaled:31/integer-unsigned-big>>.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Binary angle conversion functions.

ba16_to_float(<<X:16/integer-unsigned-big>>) ->
    X * 1.40625 / 256.0.

float_to_ba16(X) ->
    Val = round(X * (64.0 / 45.0) * 128),
    <<Val:16/integer-unsigned-big>>.

ba32_to_float(<<X:32/integer-unsigned-big>>) ->
    X * 1.40625 / 16777216.0.

float_to_ba32(X) ->
    Val = round(X * (64.0 / 45.0) * 8388608),
    <<Val:32/integer-unsigned-big>>.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Signed binary angle conversion functions.
    
sa16_to_float(<<X:16/integer-signed-big>>) ->
    X * 1.40625 / 512.

float_to_sa16(X) ->
    Val = round(X * (64.0 / 45.0) * 256),
    <<Val:16/integer-signed-big>>.
    
sa32_to_float(<<X:32/integer-signed-big>>) ->
    X * 1.40625 / 33554432.

float_to_sa32(X) ->
    Val = round(X * (64.0 / 45.0) * 16777216),
    <<Val:32/integer-signed-big>>.
