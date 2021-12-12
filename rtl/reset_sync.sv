/**
 * File              : reset_sync.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 06.11.2021
 * Last Modified Date: 04.12.2021
 */
module reset_sync
#(
  parameter int RST_MODE = 0 // 0 - Active Low, 1 - Active High
)(
  input         arst_i,
  input         clk,
  output  logic rst_o
);
  logic rst_ff, meta_rst_ff;
  logic rstn_ff, meta_rstn_ff;

  always_comb begin
    rst_o = rst_ff;
  end

  generate
    if (RST_MODE == 1) begin : gen_rst_act_h
      always @ (posedge clk or posedge arst_i) begin : act_high
        if (arst_i) begin
          {rst_ff,meta_rst_ff} <= 2'b11;
        end
        else begin
          {rst_ff,meta_rst_ff} <= {meta_rst_ff, 1'b0};
        end
      end : act_high
    end
    else begin : gen_rst_act_l
      always @(posedge clk or negedge arst_i) begin : act_low
        if (!arst_i) begin
          {rst_ff,meta_rst_ff} <= 2'b00;
        end
        else begin
          {rst_ff,meta_rst_ff} <= {meta_rst_ff,1'b1};
        end
      end : act_low
    end
  endgenerate
endmodule
