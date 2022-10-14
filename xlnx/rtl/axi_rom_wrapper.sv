module axi_rom_wrapper
  import amba_axi_pkg::*;
  import amba_ahb_pkg::*;
  import nox_utils_pkg::*;
(
  input                 clk,
  input                 rst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso
);
  logic [31:0] data;
  logic [15:0] addr_ff, next_addr;
  logic req_ff, next_req;
  logic bvalid_ff, next_bvalid;
  axi_tid_t    axi_rid_ff, next_rid;

  always_comb begin
    axi_miso.awready = '0;
    axi_miso.wready  = '0;
    axi_miso.bid     = '0;
    axi_miso.bresp   = axi_error_t'('0);
    axi_miso.buser   = '0;
    axi_miso.bvalid  = bvalid_ff;
    axi_miso.arready = 'd1;
    axi_miso.rid     = axi_rid_ff;
    axi_miso.rdata   = '0;
    axi_miso.rresp   = axi_error_t'('0);
    axi_miso.rlast   = '0;
    axi_miso.ruser   = '0;
    axi_miso.rvalid  = '0;

    next_rid = axi_rid_ff;
    next_req = (req_ff && ~axi_mosi.arvalid) ?  ~axi_mosi.rready : axi_mosi.arvalid;
    next_bvalid = req_ff;

    if (axi_mosi.arvalid) begin
      next_rid = axi_mosi.arid;
    end

    if (req_ff) begin
      axi_miso.rdata    = data;
      axi_miso.rvalid   = 1;
      axi_miso.rlast    = 1;
    end
  end

  /* verilator lint_off WIDTH */
  always_ff @ (posedge clk) begin
    if (rst == 'b0) begin
      req_ff  <= '0;
      bvalid_ff <= '0;
      axi_rid_ff <= '0;
    end
    else begin
      req_ff  <= next_req;
      bvalid_ff <= next_bvalid;
      axi_rid_ff <= next_rid;
    end
  end

  boot_rom u_rom (
    .clk    (clk),
    .en     (axi_mosi.arvalid),
    .addr_i (axi_mosi.araddr[15:2]),
    .dout_o (data)
  );

  /* verilator lint_off WIDTH */
endmodule
