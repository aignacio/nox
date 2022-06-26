// Simple AXI-SPI peripheral design by aignacio
// https://www.corelis.com/education/tutorials/spi-tutorial/
module axi_spi_master import utils_pkg::*; #(
  parameter int SLAVES          = 1,
  parameter int SPI_PINS        = 10,          // Extra pins used to drive some displays
  parameter int BASE_ADDR       = 'hB000_0000,
  parameter int FIFO_IN_SLOTS   = 2,
  parameter int FIFO_OUT_SLOTS  = 2,
  parameter int CLK_BETWEEN_TX  = 5
) (
  input                         clk,
  input                         arst,
  input   s_axi_mosi_t          axi_mosi,
  output  s_axi_miso_t          axi_miso,
  // SPI Pins
  output  logic                 sck_o,
  output  logic                 mosi_o,
  input                         miso_i,
  output  logic [SLAVES-1:0]    cs_n_o,
  output  logic [SPI_PINS-1:0]  spi_out_o
);
  /* verilator lint_off IMPLICIT */
  /* verilator lint_off WIDTH */
  localparam NUM_CSR = 5;
  localparam AXI_WIDTH_DATA = 32;

  typedef enum logic [1:0] {
    IDLE,
    TRANSFERING,
    BETWEEN_TXNS
  } spi_fsm_t;

  typedef enum logic [$clog2(NUM_CSR)-1:0] {
    CFG,
    GPIO_SEL,
    VERSION,
    FIFO_IN, // to   MOSI
    FIFO_OUT // from MISO
  } spi_csrs_t;

  typedef struct packed {
    logic                       vld;
    logic                       req;
    logic                       busy;
    logic [$clog2(NUM_CSR)-1:0] csr_addr;
  } s_req_t;

  typedef struct packed {
    logic [SLAVES-1:0]  slave_sel;
    logic [3:0]         clk_div; // Prescaler up to 16x input clk
    logic               cpha;
    logic               cpol;
  } s_cfg_spi_t;

  function automatic logic check_csr_pol(logic [$clog2(NUM_CSR)-1:0] csr, logic wr_or_rd);
    logic vld;

    vld = 1'b0;
    if (wr_or_rd) begin // writes
      case(csr)
        VERSION:  vld = 1'b0;
        FIFO_OUT: vld = 1'b0;
        default:  vld = 1'b1;
      endcase
    end
    else begin // reads
      case(csr)
        FIFO_IN:  vld = 1'b0;
        default:  vld = 1'b1;
      endcase
    end
    return vld;
  endfunction

  function automatic logic check_axi_pol(s_axi_mosi_t req, logic wr_or_rd);
    logic vld;

    vld = 1'b0;
    if (wr_or_rd) begin // writes
      vld = (req.awlen == 'b0) && (req.awsize <= 2); // We only handle single-beat bursts, up to word
    end
    else begin // reads
      vld = (req.arlen == 'b0) && (req.arsize <= 2); // We only handle single-beat bursts, up to word
    end
    return vld;
  endfunction

  logic [31:0]  wr_addr;
  logic [31:0]  rd_addr;
  s_req_t       wr_req_ff, wr_req_next;
  s_req_t       rd_req_ff, rd_req_next;
  logic         bresp_ff, bresp_next;
  logic         fifo_in_w;
  spi_fsm_t     fsm_spi_ff, next_spi_fsm;

  logic [7:0]   fifo_wr_data_in;
  logic [7:0]   fifo_wr_data_out;
  logic [7:0]   fifo_rd_data_in_ff;
  logic [7:0]   fifo_rd_data_out;
  logic [7:0]   next_fifo_rd_data_in;

  logic [4:0]   clk_counter_ff;
  logic [4:0]   next_clk_counter;
  logic         spi_clk_ff;
  logic         next_spi_clk;

  logic         spi_active;
  logic         txn_rd_from_axi;
  logic         write_fifo_empty;
  logic         fifo_rd_empty;

  logic [$clog2(CLK_BETWEEN_TX)-1:0]  cool_off_count_ff, next_cool_off_count;

  axi_tid_t rid_ff, next_rid;
  axi_tid_t wid_ff, next_wid;

  // CSRs
  s_cfg_spi_t                 cfg_spi_ff, cfg_spi_next;
  s_cfg_spi_t                 cfg_default;
  logic [SPI_PINS-1:0]        spi_ios_ff, spi_ios_next;
  logic [AXI_WIDTH_DATA-1:0]  axi_wdata;
  logic                       bvalid_ff, bvalid_next;
  // MOSI
  logic                       fin_mosi_ff, next_fin_mosi;
  logic [2:0]                 count_mosi_ff, next_count_mosi;
  logic                       txn_mosi_done_ff, next_txn_mosi_done;
  // MISO
  logic                       txn_miso_done_ff, next_txn_miso_done;
  logic [2:0]                 count_miso_ff, next_count_miso;
  logic                       fin_miso_ff, next_fin_miso;

  always_comb begin : decode_axi_req
    axi_miso = s_axi_miso_t'('0);

    // CSRs
    cfg_spi_next = cfg_spi_ff;
    spi_ios_next = spi_ios_ff;
    // CSRs

    // Write AXI
    wr_req_next = wr_req_ff;
    if (wr_req_ff.csr_addr == FIFO_IN) begin
      axi_miso.wready = wr_req_ff.busy && ~fifo_in_w_full;
    end
    else begin
      axi_miso.wready = wr_req_ff.busy;
    end
    bvalid_next = bvalid_ff ? ~axi_mosi.bready : (axi_mosi.wlast && axi_miso.wready);
    axi_miso.bvalid = bvalid_ff;
    axi_miso.bresp  = bvalid_ff ? (wr_req_next.vld ? AXI_OKAY : AXI_SLVERR) : AXI_OKAY;
    axi_miso.awready = ~wr_req_ff.busy; // We only support 1-OT
    if (~wr_req_next.busy &&  ~axi_miso.bvalid) begin : wr_addr_ph
      wr_req_next.req = (axi_mosi.awvalid && axi_miso.awready);
      if (wr_req_next.req) begin
        wr_req_next.busy = 1'b1;
        wr_addr = (axi_mosi.awaddr-BASE_ADDR) >> 2; // Check boundaries of req. / All CSRs are word-aligned
        wr_req_next.csr_addr = wr_addr[$clog2(NUM_CSR)-1:0];
        if ((wr_addr <= NUM_CSR) && check_csr_pol(wr_req_next.csr_addr,1) && check_axi_pol(axi_mosi,1)) begin
          wr_req_next.vld = 1'b1;
        end
        else begin
          wr_req_next.vld = 1'b0;
        end
      end
    end

    for (int i=0;i<AXI_WIDTH_DATA/8;i++) begin
      axi_wdata[i*8+:8] = axi_mosi.wstrb[i] ? axi_mosi.wdata[i*8+:8] : 8'h0;
    end

    fifo_wr_data_in = '0;
    fifo_in_w    = 1'b0;
    if (axi_mosi.wvalid && wr_req_ff.vld && wr_req_ff.busy && axi_miso.wready) begin : wr_data_ph
      case(wr_req_ff.csr_addr)
        CFG:      cfg_spi_next = axi_wdata;
        GPIO_SEL: spi_ios_next = axi_wdata;
        FIFO_IN:  begin
                  fifo_wr_data_in = axi_wdata[7:0];
                  fifo_in_w    = 1'b1;
        end
        default:  begin
          `ifdef SIMULATION
            $error("Illegal SPI write");
          `else
            fifo_wr_data_in = '0;
            fifo_in_w    = 1'b0;
          `endif
        end
      endcase
      wr_req_next.busy = 1'b0;
    end
    else if (axi_miso.wready && axi_mosi.wvalid && ~wr_req_ff.vld && wr_req_ff.busy) begin
      wr_req_next.busy = 1'b0;
    end

    // Read AXI
    rd_req_next = rd_req_ff;
    axi_miso.arready = ~rd_req_ff.busy; // We only support 1-OT
    if (~rd_req_next.busy) begin : rd_addr_ph
      rd_req_next.req = axi_mosi.arvalid;
      if (rd_req_next.req) begin
        rd_req_next.busy = 1'b1;
        rd_addr = (axi_mosi.araddr-BASE_ADDR) >> 2; // Check boundaries of req. / All CSRs are word-aligned
        rd_req_next.csr_addr = rd_addr[$clog2(NUM_CSR)-1:0];
        if ((rd_addr <= NUM_CSR) && check_csr_pol(rd_req_next.csr_addr,0) && check_axi_pol(axi_mosi,0)) begin
          rd_req_next.vld = 1'b1;
        end
        else begin
          rd_req_next.vld = 1'b0;
        end
      end
    end

    txn_rd_from_axi = 1'b0;
    if (rd_req_ff.busy) begin
      axi_miso.rlast  = 1'b1;
      axi_miso.rresp  = rd_req_ff.vld ? AXI_OKAY : AXI_SLVERR;
      axi_miso.rvalid = 1'b1;
      rd_req_next.busy = ~axi_mosi.rready;

      if (rd_req_ff.vld) begin
        case(rd_req_ff.csr_addr)
          CFG:      axi_miso.rdata = cfg_spi_ff;
          GPIO_SEL: axi_miso.rdata = spi_ios_ff;
          VERSION:  axi_miso.rdata = {<<8{"v1.0"}}; // we use the stream op to send reversed
          FIFO_OUT: begin
            axi_miso.rdata  = fifo_rd_empty ? 'h0  : {24'h0,fifo_rd_data_out};
            txn_rd_from_axi = fifo_rd_empty ? 1'b0 : 1'b1;
          end
          `ifdef SIMULATION
            default:  $error("Illegal SPI read");
          `else
            default:  axi_miso.rdata = 'd0;
          `endif
        endcase
      end
    end
    // Way of avoiding destroying your FPGA =)
    cfg_spi_next.clk_div[0] = 1'b1;

    next_rid = rid_ff;
    next_wid = wid_ff;
    axi_miso.rid = rid_ff;
    axi_miso.bid = wid_ff;

    if (axi_mosi.arvalid && axi_miso.arready) begin
      next_rid = axi_mosi.arid;
    end

    if (axi_mosi.awvalid && axi_miso.awready) begin
      next_wid = axi_mosi.awid;
    end
  end

  always_comb begin : spi_txn_mosi
    mosi_o             = (next_spi_fsm == TRANSFERING) ? fifo_wr_data_out['d7-count_mosi_ff] : 1'b0;
    next_fin_mosi      = fin_mosi_ff;
    next_count_mosi    = count_mosi_ff;
    next_txn_mosi_done = 1'b0;

    if (~fin_mosi_ff && (fsm_spi_ff == TRANSFERING)) begin
      if (count_mosi_ff == 'd7) begin
        next_fin_mosi      = 1'b1;
        next_txn_mosi_done = 1'b1;
      end
      else begin
        next_count_mosi = count_mosi_ff + 'd1;
      end
    end

    if ((fsm_spi_ff == BETWEEN_TXNS) && (cool_off_count_ff == CLK_BETWEEN_TX)) begin
      next_fin_mosi = 1'b0;
      next_count_mosi = 'd0;
    end

    if (fsm_spi_ff == IDLE) begin
      next_count_mosi = 'd0;
      next_fin_mosi = 'd0;
    end
  end : spi_txn_mosi

  always_comb begin : spi_txn_miso
    next_fin_miso      = fin_miso_ff;
    next_count_miso    = count_miso_ff;

    next_txn_miso_done = 1'b0;

    next_fifo_rd_data_in = fifo_rd_data_in_ff;

    if (~fin_miso_ff && (next_spi_fsm == TRANSFERING)) begin
      if (count_miso_ff == 'd7) begin
        next_fin_miso      = 1'b1;
        next_txn_miso_done = 1'b1;
      end
      else begin
        next_count_miso = count_miso_ff + 'd1;
      end
      next_fifo_rd_data_in['d7-count_miso_ff] = miso_i;
    end

    if ((fsm_spi_ff == BETWEEN_TXNS) && (cool_off_count_ff == CLK_BETWEEN_TX)) begin
      next_fin_miso = 1'b0;
      next_count_miso = 'd0;
    end

    if (((fsm_spi_ff == IDLE) && (next_spi_fsm == IDLE)) ||
        ((fsm_spi_ff == BETWEEN_TXNS) && (next_spi_fsm == BETWEEN_TXNS))) begin
      next_count_miso = 'd0;
      next_fin_miso = 'd0;
      next_fifo_rd_data_in = '0;
    end

    if (fsm_spi_ff != TRANSFERING && next_spi_fsm == TRANSFERING) begin
      next_count_miso = 'd1;
    end
  end : spi_txn_miso

  always_ff @ (posedge spi_clk_ff or posedge arst) begin
    if (arst) begin
      txn_mosi_done_ff   <= 1'b0;
      count_miso_ff      <= 'd0;
      fin_miso_ff        <= 1'b0;
      fifo_rd_data_in_ff <= 'd0;
      txn_miso_done_ff   <= 1'b0;
      fsm_spi_ff         <= IDLE;//spi_fsm_t'('0);
      cool_off_count_ff  <= 'd0;
    end
    else begin
      txn_mosi_done_ff   <= next_txn_mosi_done;
      count_miso_ff      <= next_count_miso;
      fin_miso_ff        <= next_fin_miso;
      fifo_rd_data_in_ff <= next_fifo_rd_data_in;
      txn_miso_done_ff   <= next_txn_miso_done;
      fsm_spi_ff         <= next_spi_fsm;
      cool_off_count_ff  <= next_cool_off_count;
    end
  end

  always_ff @ (negedge spi_clk_ff or posedge arst) begin
    if (arst) begin
      count_mosi_ff <= 'd0;
      fin_mosi_ff   <= 1'b0;
    end
    else begin
      count_mosi_ff <= next_count_mosi;
      fin_mosi_ff   <= next_fin_mosi;
    end
  end

  always_comb begin
    next_spi_fsm = fsm_spi_ff;
    spi_active = 1'b0;
    next_cool_off_count = cool_off_count_ff;

    unique case(fsm_spi_ff)
      IDLE:         next_spi_fsm = ~write_fifo_empty ? TRANSFERING : IDLE;
      TRANSFERING:  begin
        next_cool_off_count = 'd0;
        spi_active = 1'b1;
        if (fin_mosi_ff && fin_miso_ff) begin
          if (~write_fifo_empty) begin
            next_spi_fsm = BETWEEN_TXNS;
            spi_active = 1'b0;
          end
          else begin
            next_spi_fsm = IDLE;
          end
        end
      end
      BETWEEN_TXNS: begin
        if (cool_off_count_ff < CLK_BETWEEN_TX) begin
          next_cool_off_count = cool_off_count_ff + 'd1;
          next_spi_fsm = write_fifo_empty ? IDLE : BETWEEN_TXNS;
        end
        else begin
          next_spi_fsm = TRANSFERING;
        end
      end
      default: next_spi_fsm = fsm_spi_ff;
    endcase

    if (cfg_spi_ff.cpha == 1) begin
      spi_active = (next_spi_fsm == TRANSFERING) ? 1'b1 : 1'b0;
    end
  end

  logic spi_clk_not;

  always_comb begin : clk_div
    next_spi_clk = spi_clk_ff;
    spi_clk_not  = ~spi_clk_ff;
    if (clk_counter_ff == (cfg_spi_ff.clk_div+'d1)) begin
      next_clk_counter = '0;
      next_spi_clk     = ~spi_clk_ff;
    end
    else begin
      next_clk_counter = clk_counter_ff + 'd1;
    end
  end

  always_comb begin : wireup_spi_pins
    if (spi_active) begin
      if (cfg_spi_ff.cpol == ~cfg_spi_ff.cpha) begin
        sck_o = spi_clk_not;
      end
      else begin
        sck_o = spi_clk_ff;
      end
    end
    else begin
      sck_o = cfg_spi_ff.cpol ? 1'b1 : 1'b0;
    end
    cs_n_o    = ~cfg_spi_ff.slave_sel;
    spi_out_o = spi_ios_ff;

    // clk_div needs to be careful chosen once it
    // can destroy FPGA CTS, let's ensure
    // clk_div[0] == 1 once division will be mult of 2
    cfg_default.clk_div   = 'd9; // Divide input clock by 16x times
    cfg_default.cpha      = 1'b0;
    cfg_default.cpol      = 1'b0;
    cfg_default.slave_sel = 'h0;
  end

  always_ff @ (posedge clk or posedge arst) begin
    if (arst) begin
      wr_req_ff          <= s_req_t'('0);
      rd_req_ff          <= s_req_t'('0);
      cfg_spi_ff         <= cfg_default; //s_cfg_spi_t'('0);
      spi_ios_ff         <= '0;
      bvalid_ff          <= 1'b0;
      clk_counter_ff     <= '0;
      spi_clk_ff         <= 1'b0;
      rid_ff             <= '0;
      wid_ff             <= '0;
    end
    else begin
      wr_req_ff          <= wr_req_next;
      rd_req_ff          <= rd_req_next;
      cfg_spi_ff         <= cfg_spi_next;
      spi_ios_ff         <= spi_ios_next;
      bvalid_ff          <= bvalid_next;
      clk_counter_ff     <= next_clk_counter;
      spi_clk_ff         <= next_spi_clk;
      rid_ff             <= next_rid;
      wid_ff             <= next_wid;
    end
  end

  cdc_async_fifo # (
    .SLOTS(FIFO_IN_SLOTS),
    .WIDTH(8)
  ) u_fifo_in (
    .clk_wr     (clk),
    .arst_wr    (arst),
    .wr_en_i    (fifo_in_w),
    .wr_data_i  (fifo_wr_data_in),
    .wr_full_o  (fifo_in_w_full),
    .clk_rd     (spi_clk_ff),
    .arst_rd    (arst),
    .rd_en_i    (txn_mosi_done_ff),
    .rd_data_o  (fifo_wr_data_out),
    .rd_empty_o (write_fifo_empty)
  );

  cdc_async_fifo # (
    .SLOTS(FIFO_OUT_SLOTS),
    .WIDTH(8)
  ) u_fifo_out (
    .clk_wr     (spi_clk_ff),
    .arst_wr    (arst),
    .wr_en_i    (txn_miso_done_ff),
    .wr_data_i  (fifo_rd_data_in_ff),
    .wr_full_o  (),
    .clk_rd     (clk),
    .arst_rd    (arst),
    .rd_en_i    (txn_rd_from_axi),
    .rd_data_o  (fifo_rd_data_out),
    .rd_empty_o (fifo_rd_empty)
  );

  /* verilator lint_on IMPLICIT */
  /* verilator lint_on WIDTH */
endmodule
