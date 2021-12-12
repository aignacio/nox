/**
 * File              : skid_buffer.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 25.10.2021
 * Last Modified Date: 04.12.2021
 * Description       : http://fpgacpu.ca/fpga/Pipeline_Skid_Buffer.html
 */
module skid_buffer
  import utils_pkg::*;
#(
  parameter int DATA_WIDTH = 1
)(
  input                          clk,
  input                          rst,
  // Input I/F
  input                          in_valid_i,
  output  logic                  in_ready_o,
  input   [DATA_WIDTH-1:0]       in_data_i,

  // Output I/F
  output  logic                  out_valid_o,
  input                          out_ready_i,
  output  logic [DATA_WIDTH-1:0] out_data_o
);
  typedef logic [DATA_WIDTH-1:0] dw_t;
  typedef enum logic [1:0] {
    EMPTY,
    BUSY,
    FULL
  } fsm_t;

  fsm_t st_ff, next_st;
  dw_t data_bf_ff, next_data_bf;
  dw_t data_out_ff, next_data_out;

  always_comb begin : out_ctrl
    in_ready_o  = 'b0;
    out_valid_o = 'b0;
    next_data_bf  = data_bf_ff;
    next_data_out = data_out_ff;
    out_data_o    = data_out_ff;

    unique case (st_ff)
      EMPTY: begin
        in_ready_o = 'b1;
        if (in_valid_i) begin
          next_data_out = in_data_i;
        end
      end
      BUSY: begin
        in_ready_o = 'b1;
        out_valid_o = 'b1;
        if (in_valid_i && ~out_ready_i) begin
          next_data_bf = in_data_i;
        end
        if (in_valid_i && out_ready_i) begin
          next_data_out = in_data_i;
        end
      end
      FULL: begin
        out_valid_o = 'b1;
        if (out_ready_i) begin
          next_data_out = data_bf_ff;
        end
      end
      default: out_data_o = 'b0;
    endcase
  end : out_ctrl

  always_comb begin : fsm_ctrl
    next_st = st_ff;

    unique case (st_ff)
      EMPTY: begin
        if (in_valid_i) begin
          next_st = BUSY;
        end
      end
      BUSY: begin
        if (in_valid_i && ~out_ready_i) begin
          next_st = FULL;
        end
        if (~in_valid_i && out_ready_i) begin
          next_st = EMPTY;
        end
      end
      FULL: begin
        if (out_ready_i) begin
          next_st = BUSY;
        end
      end
      default: next_st = EMPTY;
    endcase
  end : fsm_ctrl

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      st_ff       <= fsm_t'(EMPTY);
      data_bf_ff  <= `OP_RST_L;
      data_out_ff <= `OP_RST_L;
    end
    else begin
      st_ff       <= next_st;
      data_bf_ff  <= next_data_bf;
      data_out_ff <= next_data_out;
    end
  end

`ifdef COCOTB_SIM
  `ifdef XCELIUM
    `DUMP_WAVES_XCELIUM
  `endif
`endif
endmodule

