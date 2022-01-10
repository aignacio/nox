module axi_rom_wrapper
  import utils_pkg::*;
(
  input                 clk,
  input                 arst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso
);
  logic [31:0] data;
  logic [15:0] addr_ff, addr_boot;
  logic req_ff;

  always_comb begin
    axi_miso.awready = '0;
    axi_miso.wready  = '0;
    axi_miso.bid     = '0;
    axi_miso.bresp   = aerror_t'('0);
    axi_miso.buser   = '0;
    axi_miso.bvalid  = '0;
    axi_miso.arready = 'd1;
    axi_miso.rid     = '0;
    axi_miso.rdata   = '0;
    axi_miso.rresp   = aerror_t'('0);
    axi_miso.rlast   = '0;
    axi_miso.ruser   = '0;
    axi_miso.rvalid  = '0;

    if (req_ff) begin
      axi_miso.rdata    = data;
      axi_miso.rvalid   = 1;
      axi_miso.rlast    = 1;
    end
  end

  /* verilator lint_off WIDTH */
  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      req_ff  <= '0;
      addr_ff <= '0;
    end
    else begin
      if (req_ff == '0) begin
        req_ff <= axi_mosi.arvalid;
        addr_ff<= axi_mosi.araddr[15:2];
      end
      else if (axi_mosi.rready) begin
        req_ff <= '0;
      end
    end
  end

  always_comb begin
    if (req_ff == '0) begin
      addr_boot = axi_mosi.araddr[15:2];
    end
    else if (req_ff && (axi_mosi.arvalid == '0) && (axi_mosi.rready == '0)) begin
      addr_boot = addr_ff;
    end
    else begin
      addr_boot = '0;
    end
  end

  boot_rom u_rom (
    .clk    (clk),
    .en     ('1),
    .addr_i (addr_boot),
    .dout_o (data)
  );

  /* verilator lint_off WIDTH */
endmodule
