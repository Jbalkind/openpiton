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
//  Filename      : rf_l15_wmt.v
//  Created On    : 2014-02-04 18:14:58
//  Last Modified : 2014-12-18 17:10:02
//  Revision      :
//  Author        : Tri Nguyen
//  Company       : Princeton University
//  Email         : trin@princeton.edu
//
//  Description   :
//
//
//==================================================================================================
//rf_l15_wmt.v

// trin timing fix 12/16: move read s3 to s2
// timing 12/17: move write to s2 to s3

`include "l15.tmp.h"

module rf_l15_wmt #(
   parameter L15_L1D_LINE_SIZE = 64,
   localparam L1D_NUM_ENTRIES = `CONFIG_L1D_SIZE/L15_L1D_LINE_SIZE,
   localparam L15_NUM_ENTRIES = `CONFIG_L15_SIZE/L15_L1D_LINE_SIZE,
   localparam L1D_CACHE_INDEX_WIDTH = $clog2(L1D_NUM_ENTRIES) - $clog2(`CONFIG_L1D_ASSOCIATIVITY),
   localparam L15_SET_COUNT = L15_NUM_ENTRIES / `CONFIG_L15_ASSOCIATIVITY,
   localparam L1D_SET_COUNT = L1D_NUM_ENTRIES / `CONFIG_L1D_ASSOCIATIVITY,
   localparam L15_WMT_ALIAS_WIDTH = (L15_SET_COUNT > L1D_SET_COUNT) ? $clog2(L15_SET_COUNT/L1D_SET_COUNT) : 0,
   localparam L15_WMT_DATA_WIDTH = (`L15_WAY_WIDTH + L15_WMT_ALIAS_WIDTH)
) (
   input wire clk,
   input wire rst_n,

   input wire read_valid,
   input wire [L1D_CACHE_INDEX_WIDTH - 1 : 0] read_index,

   input wire write_valid,
   input wire [L1D_CACHE_INDEX_WIDTH - 1 : 0] write_index,
   input wire [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] write_mask,
   input wire [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] write_data,

   output wire [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] read_data
   );

// reg [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] data_out_f;

// reg [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] regfile [0:127];

// always @ (posedge clk)
// begin
//    if (read_valid)
//       data_out_f <= regfile[read_index];
// end


// assign read_data = data_out_f;


reg [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] data_out_f;
reg [L1D_CACHE_INDEX_WIDTH - 1 : 0] write_index_f;
reg [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] write_data_f;
reg [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] write_mask_f;
reg write_valid_f;

reg [(`L1D_WAY_COUNT*(L15_WMT_DATA_WIDTH+1))-1:0] regfile [0:L1D_SET_COUNT-1];

always @ (posedge clk)
begin
   if (read_valid)
      data_out_f <= regfile[read_index];
end


assign read_data = data_out_f;

// Write port

always @ (posedge clk)
begin
   write_valid_f <= write_valid;
   if (write_valid)
   begin
      write_data_f <= write_data;
      write_index_f <= write_index;
      write_mask_f <= write_mask;
   end
end

integer numset, numway;
always @ (posedge clk)
begin
   if (!rst_n)
   begin
      for (numset=0;numset<((`CONFIG_L1D_SIZE/`CONFIG_L1D_ASSOCIATIVITY)/L15_L1D_LINE_SIZE); numset = numset + 1) begin
         for (numway=0; numway<`CONFIG_L1D_ASSOCIATIVITY;numway = numway + 1) begin
            regfile[numset][(numway+1)*(L15_WMT_DATA_WIDTH+1)-1] <= 1'b0;
         end 
      end
   end
   else
   if (write_valid_f)
   begin
      // regfile[write_index] <= (write_data & write_mask) | (regfile[write_index] & ~write_mask);
      regfile[write_index_f] <= (write_data_f & write_mask_f) | (regfile[write_index_f] & ~write_mask_f);
   end
end
endmodule
