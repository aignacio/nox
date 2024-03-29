/**
 * File              : nox_sim.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 12.12.2021
 * Last Modified Date: 24.05.2022
 */
module nox_sim
  import amba_axi_pkg::*;
  import amba_ahb_pkg::*;
  import nox_utils_pkg::*;
(
  input               clk,
  input               rst
);
  s_axi_mosi_t  [1:0] masters_axi_mosi;
  s_axi_miso_t  [1:0] masters_axi_miso;

  s_axi_mosi_t  [2:0] slaves_axi_mosi;
  s_axi_miso_t  [2:0] slaves_axi_miso;

  assign slaves_axi_mosi[0]  = masters_axi_mosi[0];
  assign masters_axi_miso[0] = slaves_axi_miso[0];

  s_irq_t irq_stim;

  /* verilator lint_off PINMISSING */
`ifndef RV_COMPLIANCE

  typedef enum logic [1:0] {
    IDLE,
    IRAM_MIRROR,
    DRAM
  } mux_axi_t;

  mux_axi_t switch_ff, next_switch;
  logic slave_1_sel;
  logic slave_2_sel;

  // This mux is only used for the printf to work =)
  always_comb begin : axi_mux
    masters_axi_miso[1] = s_axi_miso_t'('0);
    slaves_axi_mosi[1]  = s_axi_mosi_t'('0);
    slaves_axi_mosi[2]  = s_axi_mosi_t'('0);

    slave_2_sel = (masters_axi_mosi[1].arvalid &&
                  (masters_axi_mosi[1].araddr[31:16] == 'h8000));
    slave_1_sel = ~slave_2_sel;

    next_switch = slave_2_sel ? IRAM_MIRROR : DRAM;

    if (switch_ff == IRAM_MIRROR) begin
      masters_axi_miso[1].rid    = slaves_axi_miso[2].rid;
      masters_axi_miso[1].rdata  = slaves_axi_miso[2].rdata;
      masters_axi_miso[1].rresp  = slaves_axi_miso[2].rresp;
      masters_axi_miso[1].rlast  = slaves_axi_miso[2].rlast;
      masters_axi_miso[1].ruser  = slaves_axi_miso[2].ruser;
      masters_axi_miso[1].rvalid = slaves_axi_miso[2].rvalid;

      masters_axi_miso[1].awready = slaves_axi_miso[1].awready;
      masters_axi_miso[1].wready = slaves_axi_miso[1].wready;
      masters_axi_miso[1].arready = slaves_axi_miso[1].arready;
    end

    if (switch_ff == DRAM) begin
      masters_axi_miso[1] = slaves_axi_miso[1];
    end

    // Write channel can be always connected to the DRAM
    slaves_axi_mosi[1].wdata   = masters_axi_mosi[1].wdata;
    slaves_axi_mosi[1].wvalid  = masters_axi_mosi[1].wvalid;
    slaves_axi_mosi[1].wstrb   = masters_axi_mosi[1].wstrb;
    slaves_axi_mosi[1].wlast   = masters_axi_mosi[1].wlast;
    slaves_axi_mosi[1].wuser   = masters_axi_mosi[1].wuser;
    slaves_axi_mosi[1].bready  = masters_axi_mosi[1].bready;
    masters_axi_miso[1].bvalid = slaves_axi_miso[1].bvalid;
    masters_axi_miso[1].bresp  = slaves_axi_miso[1].bresp;

    if (slave_2_sel)
      slaves_axi_mosi[2]  = masters_axi_mosi[1];
    else
      slaves_axi_mosi[1]  = masters_axi_mosi[1];
  end

  always_ff @ (posedge clk) begin
    if (~rst) begin
      switch_ff <= IDLE;
    end
    else begin
      switch_ff <= next_switch;
    end
  end

  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram_mirror (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[2]),
    .axi_miso (slaves_axi_miso[2])
  );

`else
  assign slaves_axi_mosi[1]  = masters_axi_mosi[1];
  assign masters_axi_miso[1] = slaves_axi_miso[1];
`endif

  axi_mem #(
    .MEM_KB(`IRAM_KB_SIZE)
  ) u_iram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[0]),
    .axi_miso (slaves_axi_miso[0])
  );

  axi_mem #(
    .MEM_KB(`DRAM_KB_SIZE)
  ) u_dram (
    .clk      (clk),
    .rst      (rst),
    .axi_mosi (slaves_axi_mosi[1]),
    .axi_miso (slaves_axi_miso[1])
  );
  /* verilator lint_on PINMISSING */

  nox u_nox(
    .clk              (clk),
    .arst             (rst),
    .start_fetch_i    ('b1),
    .start_addr_i     (`ENTRY_ADDR),
`ifndef RV_COMPLIANCE
    .irq_i            (irq_stim),
`else
    .irq_i            ('0),
`endif
    .instr_axi_mosi_o (masters_axi_mosi[0]),
    .instr_axi_miso_i (masters_axi_miso[0]),
    .lsu_axi_mosi_o   (masters_axi_mosi[1]),
    .lsu_axi_miso_i   (masters_axi_miso[1])
  );

  irq_stim u_irq_stim(
    .clk    (clk),
    .rst    (rst),
    .irq_o  (irq_stim)
  );

  // synthesis translate_off
  function automatic void writeWordIRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    u_iram.mem_loading[addr_val]        = word_val;
`ifndef RV_COMPLIANCE
    u_iram_mirror.mem_loading[addr_val] = word_val;
`endif
  endfunction

  function automatic void writeWordDRAM(addr_val, word_val);
    /*verilator public*/
    logic [31:0] addr_val;
    logic [31:0] word_val;
    u_dram.mem_loading[addr_val] = word_val;
  endfunction
  // synthesis translate_on
endmodule

module irq_stim(
  input           clk,
  input           rst,
  output s_irq_t  irq_o
);
  logic [7:0] msoft_cnt_ff, next_msoft;
  logic [7:0] mtime_cnt_ff, next_mtime;
  logic [7:0] mext_cnt_ff, next_mext;

  always_comb begin
    next_msoft =  msoft_cnt_ff+'d1; //msoft_cnt_ff[5] ? '0 : msoft_cnt_ff+'d1;
    next_mtime =  mtime_cnt_ff+'d2; //mtime_cnt_ff[6] ? '0 : mtime_cnt_ff+'d1;
    next_mext  =  mext_cnt_ff+'d1;  //mext_cnt_ff[7]  ? '0 : mext_cnt_ff+'d1;

    irq_o.sw_irq    = msoft_cnt_ff[4];
    irq_o.timer_irq = mtime_cnt_ff[5];
    irq_o.ext_irq   = mext_cnt_ff[6];
  end

  always_ff @ (posedge clk) begin
    if (~rst) begin
      msoft_cnt_ff <= '0;
      mtime_cnt_ff <= '0;
      mext_cnt_ff  <= '0;
    end
    else begin
      msoft_cnt_ff <= next_msoft;
      mtime_cnt_ff <= next_mtime;
      mext_cnt_ff  <= next_mext;
    end
  end
endmodule
