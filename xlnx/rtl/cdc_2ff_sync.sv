/**
 * File: cdc_2ff_sync.sv
 * Description: 2x Flip-Flop synchonizer
 * Author: Anderson Ignacio da Silva <aignacio@aignacio.com>
 *
 * MIT License
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module cdc_2ff_sync # (
  parameter int DATA_WIDTH = 1 // Data width in bits
)(
  input                           arst_master,
  input                           clk_sync,
  input         [DATA_WIDTH-1:0]  async_i,
  output  logic [DATA_WIDTH-1:0]  sync_o
);
  (* async_reg = "true" *) logic [1:0] [DATA_WIDTH-1:0] meta_ffs;

  always_comb begin
    sync_o = meta_ffs[1];
  end

  always_ff @ (posedge clk_sync or posedge arst_master) begin
    if (arst_master) begin
      meta_ffs <= '0;
    end
    else begin
      {meta_ffs[1],meta_ffs[0]} <= {meta_ffs[0],async_i};
    end
  end
endmodule
