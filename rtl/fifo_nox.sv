/**
 * File              : fifo_nox.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 16.10.2021
 * Last Modified Date: 26.06.2022
 *
 * Simple FIFO SLOTSxWIDTH with async reads
 */
module fifo_nox
#(
  parameter int SLOTS = 2,
  parameter int WIDTH = 8
)(
  input                                       clk,
  input                                       rst,
  input                                       clear_i,
  input                                       write_i,
  input                                       read_i,
  input         [WIDTH-1:0]                   data_i,
  output  logic [WIDTH-1:0]                   data_o,
  output  logic                               error_o,
  output  logic                               full_o,
  output  logic                               empty_o,
  output  logic [$clog2(SLOTS>1?SLOTS:2):0]   ocup_o
);
  `define MSB_SLOT  $clog2(SLOTS>1?SLOTS:2)

  logic [SLOTS-1:0] [WIDTH-1:0]     fifo_ff;
  logic [`MSB_SLOT:0] write_ptr_ff;
  logic [`MSB_SLOT:0] read_ptr_ff;
  logic [`MSB_SLOT:0] next_write_ptr;
  logic [`MSB_SLOT:0] next_read_ptr;
  logic [`MSB_SLOT:0] fifo_ocup;

  always_comb begin
    next_read_ptr = read_ptr_ff;
    next_write_ptr = write_ptr_ff;
    empty_o = (write_ptr_ff == read_ptr_ff);
    full_o  = (write_ptr_ff[`MSB_SLOT-1:0] == read_ptr_ff[`MSB_SLOT-1:0]) &&
              (write_ptr_ff[`MSB_SLOT] != read_ptr_ff[`MSB_SLOT]);
    data_o  = empty_o ? '0 : fifo_ff[read_ptr_ff[`MSB_SLOT-1:0]];

    if (write_i && ~full_o)
      next_write_ptr = write_ptr_ff + 'd1;

    if (read_i && ~empty_o)
      next_read_ptr = read_ptr_ff + 'd1;

    error_o = (write_i && full_o) || (read_i && empty_o);
    fifo_ocup = write_ptr_ff - read_ptr_ff;
    ocup_o = fifo_ocup;

    // Clear has high priority
    if (clear_i) begin
      next_read_ptr = 'd0;
      next_write_ptr = 'd0;
      data_o = 'd0;
      ocup_o = 'd0;
    end
  end

  `CLK_PROC(clk, rst) begin
    `RST_TYPE(rst) begin
      write_ptr_ff <= '0;
      read_ptr_ff <= '0;
      //fifo_ff <= '0;
    end
    else begin
      write_ptr_ff <= next_write_ptr;
      read_ptr_ff <= next_read_ptr;
      if (write_i && ~full_o)
        fifo_ff[write_ptr_ff[`MSB_SLOT-1:0]] <= data_i;
    end
  end

`ifndef NO_ASSERTIONS
  initial begin
    illegal_fifo_slot : assert (2**$clog2(SLOTS) == SLOTS)
    else $error("FIFO Slots must be power of 2");

    min_fifo_size : assert (SLOTS >= 2)
    else $error("FIFO size of SLOTS defined is illegal!");
  end
`endif

endmodule
