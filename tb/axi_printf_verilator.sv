module axi_printf_verilator import utils_pkg::*; (
  input                 clk,
  input                 arst,
  input   s_axi_mosi_t  axi_mosi,
  output  s_axi_miso_t  axi_miso
);
  logic next_bresp;
  logic bresp_ff;
  logic next_id;
  logic id_ff;

  always_comb begin
    next_bresp = bresp_ff;
    next_id = id_ff;

    axi_miso = s_axi_miso_t'('0);
    axi_miso.wready = 1'b1;
    axi_miso.awready = 1'b1;
    axi_miso.bresp = aerror_t'('0); // no errors
    axi_miso.bvalid = bresp_ff;
    axi_miso.bid = id_ff;

    if (bresp_ff) begin
      next_bresp = 1'b0;
    end
    else begin
      if (axi_mosi.wvalid && axi_mosi.wlast) begin
        next_bresp = 1'b1;
      end
    end

    if (axi_mosi.awvalid) begin
      next_id = axi_mosi.awid;
    end
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      bresp_ff <= '0;
      id_ff <= '0;
    end
    else begin
      bresp_ff <= next_bresp;
      id_ff <= next_id;
    end
  end

  function [7:0] getbufferReq;
    /* verilator public */
    begin
      getbufferReq = (axi_mosi.wdata[7:0]);
    end
  endfunction

  function printfbufferReq;
    /* verilator public */
    begin
      printfbufferReq = (axi_mosi.wvalid);
    end
  endfunction
endmodule
