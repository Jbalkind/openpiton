/*
Copyright (c) 2015 Princeton University
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Princeton University nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//==================================================================================================
//  Filename      : simplenocbuffer.v
//  Created On    : 2014-03-03 20:20:43
//  Last Modified : 2014-04-17 19:30:07
//  Revision      :
//
//  Description   :
//
//
//==================================================================================================
//simplenocbuffer.v

`include "iop.h"
`include "l15.tmp.h"

//`default_nettype none
module simplenocbuffer #(
   parameter L15_L1D_LINE_SIZE = 64,
   localparam L15_MAX_DATA_PACKETS = L15_L1D_LINE_SIZE/`NOC_BYTES_WIDTH,
   localparam NOC2_MAX_FLIT_NUMBER = (`L1I_LINE_SIZE<L15_L1D_LINE_SIZE) ? (L15_MAX_DATA_PACKETS + 1) : (4+1) //Data packets + header
) (
   input wire clk,
   input wire rst_n,
   input wire noc_in_val,
   input wire [`NOC_DATA_WIDTH-1:0] noc_in_data,
   input wire msg_ack,
   output reg noc_in_rdy,
   output reg [64*NOC2_MAX_FLIT_NUMBER-1:0] msg,
   output reg msg_val
   );

localparam NOC2_MAX_FLIT_NUMBER_LOG2 = $clog2(NOC2_MAX_FLIT_NUMBER);

integer i;
reg [NOC2_MAX_FLIT_NUMBER_LOG2-1:0] index;
reg [NOC2_MAX_FLIT_NUMBER_LOG2-1:0] index_next;
reg [`MSG_LENGTH_WIDTH-1:0] msg_len;
reg [`NOC2_STATE_WIDTH-1:0] state;
reg [`NOC2_STATE_WIDTH-1:0] state_next;
reg [`NOC_DATA_WIDTH-1:0] buffer [0:NOC2_MAX_FLIT_NUMBER-1];
reg [`NOC_DATA_WIDTH-1:0] buffer_next [0:NOC2_MAX_FLIT_NUMBER-1];

// Reset logic & sequential
always @ (posedge clk)
begin

   if (~rst_n)
   begin
      for (i=0; i<NOC2_MAX_FLIT_NUMBER;i=i+1) begin
         buffer[i] <= 1'b0;
      end
      index <= 0;
      state <= 0;
   end
   else
   begin
      for (i=0; i<NOC2_MAX_FLIT_NUMBER;i=i+1) begin
         buffer[i] <= buffer_next[i];
      end
      index <= index_next;
      state <= state_next;
   end
end

// Combinational
always @ *
begin
   for (i=0; i<NOC2_MAX_FLIT_NUMBER;i=i+1) begin
         msg[(i+1)*64 - 1 -: 64] = buffer[i];
   end
end

always @ *
begin
   index_next = index;
   state_next = 0;
   msg_val = 0;
   msg_len = 0;
   for (i=0; i<NOC2_MAX_FLIT_NUMBER;i=i+1) begin
      buffer_next[i] = buffer[i];
   end
   noc_in_rdy = 1'b0;

   if (state == `NOC2_STATE_IDLE)
   begin
      noc_in_rdy = 1'b1;
      msg_len = noc_in_data[`MSG_LENGTH];
      if (noc_in_val)
      begin
         buffer_next[0] = noc_in_data;
         if (msg_len == 0)
         begin
            state_next = `NOC2_STATE_WAITING_ACK;
         end
         else
         begin
            state_next = `NOC2_STATE_RECEIVING;
            index_next = index + 1;
         end
      end
   end
   else if (state == `NOC2_STATE_RECEIVING)
   begin
      noc_in_rdy = 1'b1;
      msg_len = buffer[0][`MSG_LENGTH];
      if (noc_in_val)
      begin
         buffer_next[index] = noc_in_data;
         if (index == msg_len)
         begin
            state_next = `NOC2_STATE_WAITING_ACK;
         end
         else
         begin
            state_next = `NOC2_STATE_RECEIVING;
            index_next = index + 1;
         end
      end
      else state_next = state;
   end
   else if (state == `NOC2_STATE_WAITING_ACK)
   begin
      noc_in_rdy = 1'b0;
      msg_val = 1'b1;
      if (msg_ack)
      begin
         state_next = `NOC2_STATE_IDLE;
         index_next = 0;
      end
      else
         state_next = `NOC2_STATE_WAITING_ACK;
   end
end
endmodule
