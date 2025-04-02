`timescale 1ns/1ns
module final_top (
  input  wire         aclk,         // 系统时钟
  input  wire         aresetn,      // 系统复位（低有效）
  
  // CMAC所需时钟和复位信号
  input  wire         cmac_rx_clk,
  input  wire         cmac_tx_clk,
  input  wire         cmac_rst,
  input  wire         gt_ref_clk_p,
  input  wire         gt_ref_clk_n,
  input  wire         init_clk,
  
  // CMAC的高速输出接口（将通过收发器输出数据）
  output wire [3:0]   gt_txp_out,
  output wire [3:0]   gt_txn_out
);

  // =========================================================================
  // 1. 实例化ERNIC顶层模块（exdes_top）
  //    这里的exdes_top包含了包生成、接收、RDMA协议处理等逻辑，
  //    并将生成的数据流输出到一个FIFO接口（wqe_proc_top_m_axis_*信号）。
  // =========================================================================
  wire [511:0] ernic_out_tdata;
  wire [63:0]  ernic_out_tkeep;
  wire         ernic_out_tvalid;
  wire         ernic_out_tlast;
  
  // 注意：exdes_top内部已包含了ERNIC的所有功能逻辑以及CMAC接口的处理，
  //       此处假设exdes_top中有一个输出端口（例如wqe_proc_top_m_axis_tdata等），
  //       用于传出需要发送的包数据。
  // 这里我们将exdes_top模块的相应输出信号声明为内部信号：
  wire [511:0] wqe_proc_top_m_axis_tdata;
  wire [63:0]  wqe_proc_top_m_axis_tkeep;
  wire         wqe_proc_top_m_axis_tvalid;
  wire         wqe_proc_top_m_axis_tlast;
  
  exdes_top ernic_top_inst (
    .aclk                   (aclk),
    .aresetn_1              (aresetn),
    .cmac_rx_clk            (cmac_rx_clk),
    .cmac_tx_clk            (cmac_tx_clk),
    .cmac_rst               (cmac_rst),
    .num_send_pkt_rcvd      (), // 可根据需要连接监控信号
    .num_rd_resp_pkt_rcvd   (),
    .num_rdma_rd_wr_wqe     (),
    .num_ack_rcvd           (),
    .rdma_write_payload_chk_pass_cnt(), 
    .send_capsule_matched   (),
    .rd_rsp_payload_matched (),
    .final_reg_read_done    (),
    .rqci_completions_written_out()
    // 内部exdes_top模块会产生输出流信号（例如通过FIFO输出的wqe_proc_top_m_axis_tdata等）
  );
  
  // 假设exdes_top模块内部已经将待发送数据以以下信号输出：
  assign ernic_out_tdata  = wqe_proc_top_m_axis_tdata;
  assign ernic_out_tkeep  = wqe_proc_top_m_axis_tkeep;
  assign ernic_out_tvalid = wqe_proc_top_m_axis_tvalid;
  assign ernic_out_tlast  = wqe_proc_top_m_axis_tlast;
  
  // =========================================================================
  // 2. 使用XPM FIFO跨域缓冲/转换ERNIC输出数据到CMAC输入数据
  //    CMAC通常工作在自己的时钟域（例如cmac_tx_clk），
  //    因此我们通过FIFO进行时钟域交叉，保证数据稳定传输。
  // =========================================================================
  wire [511:0] fifo_m_axis_tdata;
  wire [63:0]  fifo_m_axis_tkeep;
  wire         fifo_m_axis_tvalid;
  wire         fifo_m_axis_tlast;
  
  xpm_fifo_axis #(
    .CDC_SYNC_STAGES       (2),
    .CLOCKING_MODE         ("independent_clock"),
    .ECC_MODE              ("no_ecc"),
    .FIFO_DEPTH            (32),
    .FIFO_MEMORY_TYPE      ("auto"),
    .PACKET_FIFO           ("true"),
    .PROG_EMPTY_THRESH     (5),
    .PROG_FULL_THRESH      (5),
    .RD_DATA_COUNT_WIDTH   (1),
    .RELATED_CLOCKS        (0),
    .TDATA_WIDTH           (512),
    .TDEST_WIDTH           (1),
    .TID_WIDTH             (1),
    .TUSER_WIDTH           (1),
    .USE_ADV_FEATURES      ("1000"),
    .WR_DATA_COUNT_WIDTH   (1)
  )
  fifo_inst (
    .m_axis_tdata    (fifo_m_axis_tdata),
    .m_axis_tkeep    (fifo_m_axis_tkeep),
    .m_axis_tlast    (fifo_m_axis_tlast),
    .m_axis_tvalid   (fifo_m_axis_tvalid),
    .m_axis_tready   (1'b1),  // 此处简单拉高，实际可根据设计需要连接回反馈
    .s_axis_tdata    (ernic_out_tdata),
    .s_axis_tkeep    (ernic_out_tkeep),
    .s_axis_tlast    (ernic_out_tlast),
    .s_axis_tvalid   (ernic_out_tvalid),
    .s_axis_tready   ()       // FIFO的s_axis_tready信号
  );
  
  // =========================================================================
  // 3. 实例化CMAC模块，将FIFO的输出数据连接到CMAC的输入
  //    CMAC模块负责高速数据发送，通常它有一组AXI-Stream输入端口（s_axis_tdata/keep/valid/last）
  //    我们将FIFO的输出信号连接到CMAC模块相应的输入端口。
  // =========================================================================
  // 以下信号是CMAC模块的输入端口（假设CMAC模块设计为接收AXI-Stream数据）：
  wire [511:0] cmac_s_axis_tdata;
  wire [63:0]  cmac_s_axis_tkeep;
  wire         cmac_s_axis_tvalid;
  wire         cmac_s_axis_tlast;
  
  // 将FIFO的输出直接作为CMAC的输入
  assign cmac_s_axis_tdata  = fifo_m_axis_tdata;
  assign cmac_s_axis_tkeep  = fifo_m_axis_tkeep;
  assign cmac_s_axis_tvalid = fifo_m_axis_tvalid;
  assign cmac_s_axis_tlast  = fifo_m_axis_tlast;
  
  // 实例化CMAC模块（cmac_usplus_0_exdes）
  cmac_usplus_0_exdes cmac_inst (
    .gt_txp_out              (gt_txp_out),
    .gt_txn_out              (gt_txn_out),
    .send_continuous_pkts    (1'b1),          // 可由外部控制
    .lbus_tx_rx_restart_in   (1'b0),
    .simplex_mode_rx_aligned (1'b0),
    .tx_gt_locked_led        (),              // 可接LED显示
    .tx_done_led             (),
    .tx_busy_led             (),
    .sys_reset               (cmac_rst),
    .gt_ref_clk_p            (gt_ref_clk_p),
    .gt_ref_clk_n            (gt_ref_clk_n),
    .init_clk                (init_clk)
    // 此处CMAC模块内部需要有AXI-Stream接收接口，
    // 假设CMAC模块内部将s_axis_tdata/keep/valid/last与cmac_s_axis_tdata等连接，
    // 具体连接方式参考CMAC IP的用户手册及生成的代码
  );
  
  // 注意：如果CMAC IP核的AXI-Stream接收端口在生成的实例中为s_axis_*，
  // 则需要将cmac_s_axis_tdata/keep/valid/last信号连接到该端口。
  // 例如，如果CMAC实例中有如下端口：
  //    .s_axis_tdata(cmac_s_axis_tdata),
  //    .s_axis_tkeep(cmac_s_axis_tkeep),
  //    .s_axis_tvalid(cmac_s_axis_tvalid),
  //    .s_axis_tlast(cmac_s_axis_tlast)
  // 那么在CMAC生成时应将这些端口与我们的fifo输出信号相连。
  
  // 如果CMAC模块没有直接的AXI-Stream输入端口，而是内部封装了数据流生成（例如用于测试模式），
  // 则需要修改CMAC配置或者利用自定义逻辑将外部数据传入CMAC。
  
endmodule