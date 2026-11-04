// P1 阶段 - I2C 配置 A2020 + MIPI D-PHY 接收验证
//
// LED 含义（led_o[7]→led_o[0]，低电平点亮）：
//   led_o[7] = 1Hz 心跳（证明 clk_24m=24MHz 在跑）
//   led_o[6] = VSYNC 脉冲锁存（亮=证明 MIPI 数据流动 ✅）
//   led_o[5:0] = I2C 已完成条数（应该停在 46 = 0b101110）
//
// peri.xml 用厂商完整 Ti60_Demo.peri.xml，端口名匹配厂商 GPIO name。
`timescale 1ns/1ns

module p1_top
(
    (* syn_peri_port = 0 *) input               clk_24m,
    (* syn_peri_port = 0 *) input               sys_pll_lock,
    (* syn_peri_port = 0 *) input               clk_sys,
    (* syn_peri_port = 0 *) input               clk_pixel,
    (* syn_peri_port = 0 *) input               clk_pixel_2x,
    (* syn_peri_port = 0 *) input               clk_pixel_10x,
    (* syn_peri_port = 0 *) input               csi_rxc_i,
    (* syn_peri_port = 0 *) input               csi_rxc_lp_n_i,
    (* syn_peri_port = 0 *) input               csi_rxc_lp_p_i,
    (* syn_peri_port = 0 *) input  [7:0]        csi_rxd0_hs_i,
    (* syn_peri_port = 0 *) input               csi_rxd0_lp_n_i,
    (* syn_peri_port = 0 *) input               csi_rxd0_lp_p_i,
    (* syn_peri_port = 0 *) input               csi_scl_i,
    (* syn_peri_port = 0 *) input               csi_sda_i,
    (* syn_peri_port = 0 *) output reg [7:0]    led_o,
    (* syn_peri_port = 0 *) output              sys_pll_rstn_o,
    (* syn_peri_port = 0 *) output              csi_scl_o,
    (* syn_peri_port = 0 *) output              csi_scl_oe,
    (* syn_peri_port = 0 *) output              csi_sda_o,
    (* syn_peri_port = 0 *) output              csi_sda_oe,
    (* syn_peri_port = 0 *) output              csi_sda_io_PULL_UP_ENA,
    (* syn_peri_port = 0 *) output              csi_scl_io_PULL_UP_ENA,
    (* syn_peri_port = 0 *) output              csi_rxd0_rst_o,
    (* syn_peri_port = 0 *) output              csi_rxd1_rst_o,
    (* syn_peri_port = 0 *) output              csi_rxd2_rst_o,
    (* syn_peri_port = 0 *) output              csi_rxd3_rst_o,
    (* syn_peri_port = 0 *) output              csi_rxc_hs_en_o,
    (* syn_peri_port = 0 *) output              csi_rxc_hs_term_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd0_hs_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd0_hs_term_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd1_hs_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd1_hs_term_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd2_hs_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd2_hs_term_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd3_hs_en_o,
    (* syn_peri_port = 0 *) output              csi_rxd3_hs_term_en_o,
    // LCD RGB 800x480 (SC233HGS) - 彩条图案验证通路
    // 注意：lcd_pclk_o 由 peri 的 clkout 资源产生，RTL 不声明该端口
    (* syn_peri_port = 0 *) output              lcd_hs_o,
    (* syn_peri_port = 0 *) output              lcd_vs_o,
    (* syn_peri_port = 0 *) output              lcd_de_o,
    (* syn_peri_port = 0 *) output              lcd_blen_o,
    (* syn_peri_port = 0 *) output              lcd_pwm_o,
    (* syn_peri_port = 0 *) output [7:0]        lcd_r7_0_o,
    (* syn_peri_port = 0 *) output [7:0]        lcd_r7_0_oe,
    (* syn_peri_port = 0 *) input  [7:0]        lcd_r7_0_i,
    (* syn_peri_port = 0 *) output [7:0]        lcd_g7_0_o,
    (* syn_peri_port = 0 *) output [7:0]        lcd_g7_0_oe,
    (* syn_peri_port = 0 *) input  [7:0]        lcd_g7_0_i,
    (* syn_peri_port = 0 *) output [7:0]        lcd_b7_0_o,
    (* syn_peri_port = 0 *) output [7:0]        lcd_b7_0_oe,
    (* syn_peri_port = 0 *) input  [7:0]        lcd_b7_0_i,
    // LVDS 1024x600 屏（GPIOT 差分对，照厂商 05-2 SC233HGS LVDS 工程）
    (* syn_peri_port = 0 *) input               clk_lvds_1x,
    (* syn_peri_port = 0 *) input               clk_lvds_7x,
    (* syn_peri_port = 0 *) input               lvds_pll_lock,
    (* syn_peri_port = 0 *) output              lvds_txc_oe,
    (* syn_peri_port = 0 *) output [6:0]        lvds_txc_o,
    (* syn_peri_port = 0 *) output              lvds_txc_rst_o,
    (* syn_peri_port = 0 *) output              lvds_txd0_oe,
    (* syn_peri_port = 0 *) output [6:0]        lvds_txd0_o,
    (* syn_peri_port = 0 *) output              lvds_txd0_rst_o,
    (* syn_peri_port = 0 *) output              lvds_txd1_oe,
    (* syn_peri_port = 0 *) output [6:0]        lvds_txd1_o,
    (* syn_peri_port = 0 *) output              lvds_txd1_rst_o,
    (* syn_peri_port = 0 *) output              lvds_txd2_oe,
    (* syn_peri_port = 0 *) output [6:0]        lvds_txd2_o,
    (* syn_peri_port = 0 *) output              lvds_txd2_rst_o,
    (* syn_peri_port = 0 *) output              lvds_txd3_oe,
    (* syn_peri_port = 0 *) output [6:0]        lvds_txd3_o,
    (* syn_peri_port = 0 *) output              lvds_txd3_rst_o
);

//------------------------------------------------------------------
// I2C 内部弱上拉打开（peri 默认 pull_option="none"）
assign csi_sda_io_PULL_UP_ENA = 1'b1;
assign csi_scl_io_PULL_UP_ENA = 1'b1;

//------------------------------------------------------------------
// 内部上电复位（没有外部 rst_n 引脚，用 clk_24m 计数生成）
reg [15:0] up_cnt;
reg        rst_n;
always @(posedge clk_24m)
begin
    if(up_cnt < 16'd500)
    begin
        up_cnt <= up_cnt + 16'd1;
        rst_n  <= 1'b0;
    end
    else
        rst_n <= 1'b1;
end

//------------------------------------------------------------------
// PLL 复位释放
assign sys_pll_rstn_o = 1'b1;

//------------------------------------------------------------------
// peri 未使用的 D-PHY 引脚（保持悬空即可，避免多驱动）
wire [7:0]  csi_rxc_HS_IN;
wire        csi_rxc_LP_N_OUT;
wire        csi_rxc_LP_P_OUT;
wire        csi_rxc_LP_P_OE;
wire        csi_rxc_LP_N_OE;
wire        csi_rxc_FIFO_EMPTY;
wire        csi_rxc_RST;
wire        csi_rxc_FIFO_RD;
wire        csi_rxc_DLY_RST;
wire        csi_rxc_DLY_INC;
wire        csi_rxc_DLY_ENA;

wire        csi_rxd0_LP_N_OUT;
wire        csi_rxd0_LP_P_OUT;
wire        csi_rxd0_LP_P_OE;
wire        csi_rxd0_LP_N_OE;
wire        csi_rxd0_fifo_empty_i;
wire        csi_rxd0_fifo_rd_o;
wire        csi_rxd0_DLY_RST;
wire        csi_rxd0_DLY_INC;
wire        csi_rxd0_DLY_ENA;
wire        csi_rxd0_CLKOUT;

//------------------------------------------------------------------
// 系统复位（MIPI RX 域，等 PLL 锁定后释放）
reg [1:0] pll_lock_sync;
always @(posedge clk_sys or negedge rst_n)
begin
    if(!rst_n) pll_lock_sync <= 2'd0;
    else       pll_lock_sync <= {pll_lock_sync[0], sys_pll_lock};
end
wire sys_rst = ~pll_lock_sync[1];

//------------------------------------------------------------------
// 上电延时 100ms
localparam [21:0] PWR_DELAY = 22'd2_400_000;
reg [21:0] pwr_cnt;
always @(posedge clk_24m or negedge rst_n)
begin
    if(!rst_n)                      pwr_cnt <= 22'd0;
    else if(pwr_cnt < PWR_DELAY)    pwr_cnt <= pwr_cnt + 1'b1;
end
wire pwr_done = (pwr_cnt >= PWR_DELAY);

//------------------------------------------------------------------
// I2C 配置表
wire [5:0]  lut_idx;
wire [23:0] lut_data;
wire [5:0]  lut_size;

i2c_ad2020_cfg u_cfg
(
    .LUT_INDEX  (lut_idx),
    .LUT_DATA   (lut_data),
    .LUT_SIZE   (lut_size)
);

//------------------------------------------------------------------
// I2C 主机
wire busy, done, nack;
wire [2:0] master_state;   // I2C master 当前状态
wire [7:0] rdata_w;
wire       rd_done_w;
wire       rd_nack_w;

reg  start_req;
reg  rd_req;
reg  done_d;
reg  [7:0] rdata_lat;
reg        rd_done_seen;
reg        wr_done_seen;
reg        nack_seen;
wire       done_pulse = done & ~done_d;

// 事务分段：
//   stage0 = 写配置表第 0..12 条
//   stage1 = 再写一次 0x358B=0x0A（同时把从机寄存器指针指到 0x358B）
//   stage2 = 读回 0x358B（期望 0x0A）
//   stage3 = 写最后一条 0x3000=0x00（开流，必须最后）
reg  [1:0] stage;
reg  [5:0] idx;

wire [23:0] w_data_sel = (stage == 2'd1) ? {16'h358B, 8'h0A} :
                         (stage == 2'd3) ? {16'h3000, 8'h00} : lut_data;

// 读事务（stage=2）的 reg_addr 必须强制为 0x358B，不能用 w_data_sel
wire [15:0] reg_addr_w = (stage == 2'd2) ? 16'h358B : w_data_sel[23:8];
wire [7:0]  wdata_w    = w_data_sel[7:0];

always @(posedge clk_24m or negedge rst_n)
begin
    if(!rst_n)
    begin
        stage     <= 2'd0;
        idx       <= 6'd0;
        start_req <= 1'b0;
        rd_req    <= 1'b0;
        done_d    <= 1'b0;
        rdata_lat <= 8'h00;
        rd_done_seen <= 1'b0;
        wr_done_seen <= 1'b0;
        nack_seen    <= 1'b0;
    end
    else
    begin
        start_req <= 1'b0;
        rd_req    <= 1'b0;
        done_d    <= done;

        if(rd_done_w)
        begin
            rdata_lat    <= rdata_w;
            rd_done_seen <= 1'b1;
        end

        if(done_pulse)
        begin
            wr_done_seen <= 1'b1;
            if(nack) nack_seen <= 1'b1;
        end

        case(stage)
        2'd0: if(done_pulse)
              begin
                  if(idx == 6'd16) begin idx <= 6'd17; stage <= 2'd1; end
                  else             idx <= idx + 6'd1;
              end
        2'd1: if(done_pulse) stage <= 2'd2;
        2'd2: if(rd_done_w)  stage <= 2'd3;
        2'd3: if(done_pulse) stage <= 2'd4;
        default: ;
        endcase

        // 发起写事务
        if(pwr_done && !busy && !done && !start_req && !rd_req)
        begin
            if((stage == 2'd0) && (idx < 6'd17)) start_req <= 1'b1;
            if((stage == 2'd1) || (stage == 2'd3)) start_req <= 1'b1;
        end

        // 发起读事务
        if((stage == 2'd2) && !busy && !done && !rd_req)
            rd_req <= 1'b1;
    end
end

assign lut_idx = idx;

i2c_write_master #(
    .CLK_FREQ (24_000_000),
    .I2C_FREQ (10_000)
) u_i2c
(
    .clk        (clk_24m),
    .rst_n      (rst_n),
    .scl_o      (csi_scl_o),
    .scl_oe     (csi_scl_oe),
    .scl_i      (csi_scl_i),
    .sda_o      (csi_sda_o),
    .sda_oe     (csi_sda_oe),
    .sda_i      (csi_sda_i),
    .start      (start_req),
    .dev_addr   (7'h35),
    .reg_addr   (reg_addr_w),
    .wdata      (wdata_w),
    .busy       (busy),
    .done       (done),
    .nack       (nack),
    .debug_state(master_state),
    .rd_start   (rd_req),
    .rdata      (rdata_w),
    .rd_done    (rd_done_w),
    .rd_nack    (rd_nack_w)
);

//------------------------------------------------------------------
// CSI-2 接收：厂商 demo 实际使用的 csi_rx 软 IP（1 lane）
wire        rstn_sys = ~sys_rst;

wire        csi_rx_vsync;
wire        csi_rx_hsync;
wire        csi_rx_dvalid;
wire [63:0] csi_rx_data;
wire [5:0]  csi_rx_datatype;
wire [15:0] csi_rx_wordcnt;
wire        csi_rx_irq;
wire [3:0]  csi_rx_fifo_rd;
wire [3:0]  csi_rx_dly_en;
wire [3:0]  csi_rx_dly_inc;

wire [3:0]  hs_en_d;
wire [3:0]  term_en_d;
wire        hs_en_c_nc;
wire        term_en_c_nc;

assign csi_rxd0_hs_en_o      = hs_en_d[0];
assign csi_rxd0_hs_term_en_o = term_en_d[0];

csi_rx u_csi_rx
(
    .reset_n                (rstn_sys),
    .clk                    (clk_sys),
    .reset_byte_HS_n        (rstn_sys),
    .clk_byte_HS            (csi_rxc_i),
    .reset_pixel_n          (rstn_sys),
    .clk_pixel              (clk_sys),

    .Rx_LP_CLK_P            (csi_rxc_lp_p_i),
    .Rx_LP_CLK_N            (csi_rxc_lp_n_i),
    .Rx_HS_enable_C         (csi_rxc_hs_en_o),
    .LVDS_termen_C          (csi_rxc_hs_term_en_o),

    .Rx_LP_D_P              ({csi_rxd3_lp_p_i, csi_rxd2_lp_p_i, csi_rxd1_lp_p_i, csi_rxd0_lp_p_i}),
    .Rx_LP_D_N              ({csi_rxd3_lp_n_i, csi_rxd2_lp_n_i, csi_rxd1_lp_n_i, csi_rxd0_lp_n_i}),
    .Rx_HS_D_0              (csi_rxd0_hs_i),
    .Rx_HS_D_1              (csi_rxd1_hs_i),
    .Rx_HS_D_2              (csi_rxd2_hs_i),
    .Rx_HS_D_3              (csi_rxd3_hs_i),
    .Rx_HS_D_4              (8'h00),
    .Rx_HS_D_5              (8'h00),
    .Rx_HS_D_6              (8'h00),
    .Rx_HS_D_7              (8'h00),

    .Rx_HS_enable_D         (hs_en_d),
    .LVDS_termen_D          (term_en_d),
    .fifo_rd_enable         (csi_rx_fifo_rd),
    .fifo_rd_empty          (4'hF),
    .DLY_enable_D           (csi_rx_dly_en),
    .DLY_inc_D              (csi_rx_dly_inc),
    .u_dly_enable_D         (4'h0),
    .u_dly_inc_D            (4'h0),

    .vsync_vc0              (csi_rx_vsync),
    .hsync_vc0              (csi_rx_hsync),
    .irq                    (csi_rx_irq),
    .pixel_data_valid       (csi_rx_dvalid),
    .pixel_data             (csi_rx_data),
    .datatype               (csi_rx_datatype),
    .word_count             (csi_rx_wordcnt),

    .axi_rready             (1'b1),
    .axi_rvalid             (),
    .axi_rdata              (),
    .axi_arready            (),
    .axi_arvalid            (1'b0),
    .axi_araddr             (6'h00),
    .axi_bready             (1'b1),
    .axi_bvalid             (),
    .axi_wready             (),
    .axi_wvalid             (1'b0),
    .axi_wdata              (32'h0),
    .axi_awready            (),
    .axi_awaddr             (6'h00),
    .axi_awvalid            (1'b0),
    .axi_clk                (clk_sys),
    .axi_reset_n            (rstn_sys)
);

//------------------------------------------------------------------
// D-PHY 数据 lane 复位：常释放（厂商版本接 rst_sys，这里不让它卡住）
assign csi_rxd0_rst_o = 1'b0;
assign csi_rxd1_rst_o = 1'b0;
assign csi_rxd2_rst_o = 1'b0;
assign csi_rxd3_rst_o = 1'b0;

assign csi_rxd1_hs_en_o      = hs_en_d[1];
assign csi_rxd2_hs_en_o      = hs_en_d[2];
assign csi_rxd3_hs_en_o      = hs_en_d[3];
assign csi_rxd1_hs_term_en_o = term_en_d[1];
assign csi_rxd2_hs_term_en_o = term_en_d[2];
assign csi_rxd3_hs_term_en_o = term_en_d[3];

//------------------------------------------------------------------
// MIPI 诊断（在 24MHz 晶振域采样）
reg  [1:0] bc_sync;          // csi_rxc_i 同步
reg        byteclk_seen;     // byte clock 有翻转
reg        dt_seen;          // CSI-2 数据类型码出现过
reg        dvalid_seen;      // 有有效像素输出
reg        dat_act_seen;     // 像素数据非 0
reg        vsync_seen;       // VSYNC 出现
reg        rxd0_hs_seen;     // 数据 lane0 进入 HS 态（LP 双线为 0）
reg  [7:0] hs_prev;          // HS 字节总线上一次值
reg        hs_act_seen;      // HS 字节总线出现过变化（数据在动）
reg        hs_dat_seen;      // HS 字节总线出现非 00 / 非 FF 的有效字节
reg        lp_seen_11;       // LP 停在 11（空闲态）
reg        lp_seen_00;       // LP 停在 00（HS 模式）
reg        lp_seen_01;       // LP 停在 01（P低 N高）
reg        lp_seen_10;       // LP 停在 10（P高 N低）
reg  [7:0] hs1_prev;
reg  [7:0] hs2_prev;
reg  [7:0] hs3_prev;
reg        hs1_act;          // lane1 HS 总线有变化
reg        hs2_act;          // lane2 HS 总线有变化
reg        hs3_act;          // lane3 HS 总线有变化
reg        sda_high_seen;    // I2C SDA 读到过高电平
reg  [15:0] sda_hi_cnt;      // SDA 连续为高的计数
reg        sda_stable_high;  // SDA 连续高 >= 1ms（证明真的有稳定上拉）

wire [1:0] rxd0_lp = {csi_rxd0_lp_p_i, csi_rxd0_lp_n_i};

always @(posedge clk_24m or negedge rst_n)
begin
    if(!rst_n)
    begin
        bc_sync      <= 2'b00;
        byteclk_seen <= 1'b0;
        dt_seen      <= 1'b0;
        dvalid_seen  <= 1'b0;
        dat_act_seen <= 1'b0;
        vsync_seen   <= 1'b0;
        rxd0_hs_seen <= 1'b0;
        hs_prev      <= 8'h00;
        hs_act_seen  <= 1'b0;
        hs_dat_seen  <= 1'b0;
        lp_seen_11   <= 1'b0;
        lp_seen_00   <= 1'b0;
        lp_seen_01   <= 1'b0;
        lp_seen_10   <= 1'b0;
        hs1_prev     <= 8'h00;
        hs2_prev     <= 8'h00;
        hs3_prev     <= 8'h00;
        hs1_act      <= 1'b0;
        hs2_act      <= 1'b0;
        hs3_act      <= 1'b0;
        sda_high_seen <= 1'b0;
        sda_hi_cnt    <= 16'd0;
        sda_stable_high <= 1'b0;
    end
    else
    begin
        bc_sync <= {bc_sync[0], csi_rxc_i};

        if(bc_sync[0] ^ bc_sync[1])          byteclk_seen <= 1'b1;
        if(csi_rx_datatype != 6'd0)          dt_seen      <= 1'b1;
        if(csi_rx_dvalid)                    dvalid_seen  <= 1'b1;
        if(csi_rx_data != 64'd0)             dat_act_seen <= 1'b1;
        if(csi_rx_vsync)                     vsync_seen   <= 1'b1;
        if(!csi_rxd0_lp_p_i && !csi_rxd0_lp_n_i) rxd0_hs_seen <= 1'b1;

        hs_prev <= csi_rxd0_hs_i;
        if(csi_rxd0_hs_i != hs_prev)                                  hs_act_seen <= 1'b1;
        if((csi_rxd0_hs_i != 8'h00) && (csi_rxd0_hs_i != 8'hFF))       hs_dat_seen <= 1'b1;

        case(rxd0_lp)
        2'b11: lp_seen_11 <= 1'b1;
        2'b00: lp_seen_00 <= 1'b1;
        2'b01: lp_seen_01 <= 1'b1;
        2'b10: lp_seen_10 <= 1'b1;
        endcase

        hs1_prev <= csi_rxd1_hs_i;
        hs2_prev <= csi_rxd2_hs_i;
        hs3_prev <= csi_rxd3_hs_i;
        if(csi_rxd1_hs_i != hs1_prev) hs1_act <= 1'b1;
        if(csi_rxd2_hs_i != hs2_prev) hs2_act <= 1'b1;
        if(csi_rxd3_hs_i != hs3_prev) hs3_act <= 1'b1;

        if(csi_sda_i) sda_high_seen <= 1'b1;
        // SDA 连续高 >= 1ms：证明线上有稳定上拉（浮空线做不到）
        if(csi_sda_i)
        begin
            if(sda_hi_cnt < 16'd23_999) sda_hi_cnt <= sda_hi_cnt + 1'b1;
            else                        sda_stable_high <= 1'b1;
        end
        else
            sda_hi_cnt <= 16'd0;
    end
end

//------------------------------------------------------------------
// D-PHY 数据 lane 延迟自动扫描
// 每 150ms 步进一格（约 5 帧），一旦解出 CSI-2 包就停止
wire cal_done = dt_seen | dvalid_seen;

reg [21:0] dly_tick;
reg        dly_inc_r;

always @(posedge clk_24m or negedge rst_n)
begin
    if(!rst_n)
    begin
        dly_tick  <= 22'd0;
        dly_inc_r <= 1'b0;
    end
    else if(cal_done)
    begin
        dly_tick  <= 22'd0;
        dly_inc_r <= 1'b0;
    end
    else if(dly_tick == 22'd3_599_975)
    begin
        dly_inc_r <= 1'b1;          // 1us 宽脉冲
        dly_tick  <= dly_tick + 1'b1;
    end
    else if(dly_tick == 22'd3_599_999)
    begin
        dly_inc_r <= 1'b0;
        dly_tick  <= 22'd0;         // 循环扫描
    end
    else
        dly_tick <= dly_tick + 1'b1;
end

assign csi_rxd0_DLY_INC = 1'b0;
assign csi_rxd0_DLY_RST = 1'b0;
assign csi_rxd0_DLY_ENA = 1'b0;

//------------------------------------------------------------------
// clk_sys 域心跳（分频 24_000_000）
// 若 clk_sys≈96MHz，应与 led7 同速闪烁(1Hz)；明显更慢说明 PLL 输出频率不对
reg [24:0] sys_hb_cnt;
reg        sys_hb;
always @(posedge clk_sys or negedge rst_n)
begin
    if(!rst_n) begin
        sys_hb_cnt <= 25'd0;
        sys_hb     <= 1'b0;
    end else if(sys_hb_cnt == 25'd23_999_999) begin
        sys_hb_cnt <= 25'd0;
        sys_hb     <= ~sys_hb;
    end else
        sys_hb_cnt <= sys_hb_cnt + 1'b1;
end

//------------------------------------------------------------------
// 心跳 (24MHz 域)：25bit 计数器取最高位 ≈ 1Hz 闪烁
reg [24:0] hb_cnt;
always @(posedge clk_24m or negedge rst_n)
    if(!rst_n) hb_cnt <= 25'd0; else hb_cnt <= hb_cnt + 1'd1;
wire heartbeat = hb_cnt[24];

//------------------------------------------------------------------
// D-PHY 使能 / 终端电阻"曾经开通过"锁存器
reg hs_en_seen, term_en_seen;
always @(posedge clk_24m or negedge rst_n)
begin
    if(!rst_n)
    begin
        hs_en_seen   <= 1'b0;
        term_en_seen <= 1'b0;
    end
    else
    begin
        if(hs_en_d[0])                        hs_en_seen   <= 1'b1;
        if(term_en_d[0])                      term_en_seen <= 1'b1;
    end
end

//------------------------------------------------------------------
// LED 输出统一放在文件末尾（心跳 / 缺陷报警 / 缺陷段数）

//------------------------------------------------------------------
// LCD RGB 800x480 (SC233HGS) - 彩条图案验证
// 时序照抄厂商 lcd_para.v 的 VGA_800_480 组：
//   H_SYNC=32, H_BACK=48, H_DISP=800, H_FRONT=80, H_TOTAL=960
//   V_SYNC=3,  V_BACK=5,  V_DISP=480, V_FRONT=12, V_TOTAL=500
// 12MHz / (960*500) = 25Hz 刷新率
// HS / VS 为行/帧同步，低有效（与厂商 lcd_driver.v 完全一致）

// 像素时基：clk_pixel_10x = sys_pll 输出3，out_divider=124 → 2970/124 ≈ 24MHz
// PCLK 由 peri 的 clkout 直接从该时钟输出（delay=15），RTL 不驱动该引脚
wire rst_lcd_n = rst_n & sys_pll_lock;

// lcd_blen_o 在文件末尾复用为舵机 PWM 输出（RGB 屏未使用）
assign lcd_pwm_o  = 1'b1;   // 背光亮度 100%

// 水平/垂直计数器 + HS/VS（照抄厂商写法）
reg [9:0] h_cnt;
reg [9:0] v_cnt;
reg       hs_r;
reg       vs_r;
always @(posedge clk_pixel_10x or negedge rst_lcd_n)
begin
    if(!rst_lcd_n)
    begin
        h_cnt <= 10'd0;
        v_cnt <= 10'd0;
        hs_r  <= 1'b1;
        vs_r  <= 1'b1;
    end
    else
    begin
        // 行计数
        if(h_cnt < 10'd959) h_cnt <= h_cnt + 10'd1;
        else                h_cnt <= 10'd0;

        hs_r <= (h_cnt <= 10'd31) ? 1'b0 : 1'b1;      // 行同步，低有效 32 拍

        // 列计数，每行结束加一；帧首 V_SYNC=3 行拉低
        if(h_cnt == 10'd959)
        begin
            if(v_cnt < 10'd499) v_cnt <= v_cnt + 10'd1;
            else                v_cnt <= 10'd0;
            vs_r <= (v_cnt <= 10'd2) ? 1'b0 : 1'b1;
        end
    end
end

//------------------------------------------------------------------
// 8 色竖彩条，每条 100 像素，正好铺满 800
wire [9:0] x = h_cnt - 10'd80;

reg [7:0] bar_r, bar_g, bar_b;
always @(*)
begin
    if     (x < 10'd100) {bar_r, bar_g, bar_b} = {8'hFF, 8'hFF, 8'hFF}; // 白
    else if(x < 10'd200) {bar_r, bar_g, bar_b} = {8'hFF, 8'hFF, 8'h00}; // 黄
    else if(x < 10'd300) {bar_r, bar_g, bar_b} = {8'h00, 8'hFF, 8'hFF}; // 青
    else if(x < 10'd400) {bar_r, bar_g, bar_b} = {8'h00, 8'hFF, 8'h00}; // 绿
    else if(x < 10'd500) {bar_r, bar_g, bar_b} = {8'hFF, 8'h00, 8'hFF}; // 品红
    else if(x < 10'd600) {bar_r, bar_g, bar_b} = {8'hFF, 8'h00, 8'h00}; // 红
    else if(x < 10'd700) {bar_r, bar_g, bar_b} = {8'h00, 8'h00, 8'hFF}; // 蓝
    else                 {bar_r, bar_g, bar_b} = {8'h00, 8'h00, 8'h00}; // 黑
end

// 有效显示区：h 80..879（800 像素），v 8..487（480 行）
wire lcd_de_act = (h_cnt >= 10'd80) && (h_cnt < 10'd880) &&
                  (v_cnt >= 10'd8)  && (v_cnt < 10'd488);

// DE 与 RGB 同一拍寄存器输出，保证相位一致；无效区数据强制为 0
reg       lcd_de_r;
reg [7:0] r_r, r_g, r_b;
always @(posedge clk_pixel_10x or negedge rst_lcd_n)
begin
    if(!rst_lcd_n)
    begin
        lcd_de_r <= 1'b0;
        r_r      <= 8'h00;
        r_g      <= 8'h00;
        r_b      <= 8'h00;
    end
    else
    begin
        lcd_de_r <= lcd_de_act;
        r_r      <= lcd_de_act ? bar_r : 8'h00;
        r_g      <= lcd_de_act ? bar_g : 8'h00;
        r_b      <= lcd_de_act ? bar_b : 8'h00;
    end
end

// 厂商 example_top.v 端口注释明确写：HS/VS "Fixed to 1. Use DE-Only mode."
// （它们的实际代码也把 lcd_hs_o/lcd_vs_o 接到视频 IP 的同步输出，
//   该 IP 在 DE-only 模式下这两根就是常高）
assign lcd_hs_o    = 1'b1;
assign lcd_vs_o    = 1'b1;
assign lcd_de_o    = lcd_de_r;
// RGB 是 inout 总线：必须显式把 OE 拉高，否则引脚高阻（屏上啥都没有）
assign lcd_r7_0_o  = r_r;
assign lcd_r7_0_oe = 8'hFF;
assign lcd_g7_0_o  = r_g;
assign lcd_g7_0_oe = 8'hFF;
assign lcd_b7_0_o  = r_b;
assign lcd_b7_0_oe = 8'hFF;

//------------------------------------------------------------------
// LVDS 1024x600 输出（参数与映射照厂商 05-2 SC233HGS LCD-LVDS 工程）
// clk_lvds_1x ≈ 48MHz 像素时钟，clk_lvds_7x ≈ 336MHz 串行时钟
// 时序取厂商 lcd_para.v 的 VGA_1024_600_60FPS_50MHz 组：
//   H_SYNC=40, H_BACK=120, H_DISP=1024, H_FRONT=160, H_TOTAL=1344
//   V_SYNC=3,  V_BACK=20,  V_DISP=600,  V_FRONT=12,  V_TOTAL=635

assign lvds_txc_oe   = 1'b1;
assign lvds_txd0_oe  = 1'b1;
assign lvds_txd1_oe  = 1'b1;
assign lvds_txd2_oe  = 1'b1;
assign lvds_txd3_oe  = 1'b1;
assign lvds_txc_rst_o  = 1'b0;
assign lvds_txd0_rst_o = 1'b0;
assign lvds_txd1_rst_o = 1'b0;
assign lvds_txd2_rst_o = 1'b0;
assign lvds_txd3_rst_o = 1'b0;

//------------------------------------------------------------------
// 【像素格式诊断采集】clk_sys 域（csi_rx 的像素时钟就是 clk_sys）
//   diag_dt = 最近一次 CSI-2 数据类型码（RAW8=6'h2A / RAW10=6'h2B）
//   diag_wc = 最近一次 long packet 的 word_count
//   diag_px = 每行 pixel_data_valid 脉冲数（每个脉冲含 4 个像素）
//   diag_ln = 每帧 hsync 个数（= 帧行数）
reg  [5:0]  diag_dt;
reg  [15:0] diag_wc;
reg  [15:0] diag_px;
reg  [15:0] diag_ln;
reg  [15:0] px_run;
reg  [15:0] ln_run;
reg         hs_d, vs_d;

wire hs_rise = csi_rx_hsync & ~hs_d;
wire hs_fall = ~csi_rx_hsync & hs_d;
wire vs_rise = csi_rx_vsync & ~vs_d;

always @(posedge clk_sys or negedge rstn_sys)
begin
    if(!rstn_sys)
    begin
        diag_dt <= 6'd0;  diag_wc <= 16'd0;
        diag_px <= 16'd0; diag_ln <= 16'd0;
        px_run  <= 16'd0; ln_run  <= 16'd0;
        hs_d    <= 1'b0;  vs_d    <= 1'b0;
    end
    else
    begin
        hs_d <= csi_rx_hsync;
        vs_d <= csi_rx_vsync;

        // datatype / word_count 随有效像素实时更新
        if(csi_rx_dvalid)
        begin
            diag_dt <= csi_rx_datatype;
            diag_wc <= csi_rx_wordcnt;
        end

        // 每行 pixel_data_valid 个数
        if(hs_rise)
            px_run <= 16'd0;
        else if(csi_rx_hsync && csi_rx_dvalid)
            px_run <= px_run + 1'b1;

        if(hs_fall)
            diag_px <= px_run;

        // 每帧行数
        if(vs_rise)
        begin
            diag_ln <= ln_run;
            ln_run  <= 16'd0;
        end
        else if(hs_rise)
            ln_run <= ln_run + 1'b1;
    end
end

// 标志位：{vsync_seen, dvalid_seen, dt_seen, hs_en_seen,
//          term_en_seen, byteclk_seen, hs_act_seen, 1}
wire [7:0] diag_flags = {vsync_seen, dvalid_seen, dt_seen, hs_en_seen,
                         term_en_seen, byteclk_seen, hs_act_seen, 1'b1};

//------------------------------------------------------------------
// LVDS 显示侧复位：和厂商一致，直接用 PLL 自己的 locked 信号
// lvds_pll_lock 和 clk_lvds_1x 同域，无需 CDC
wire rst_lvds_n = lvds_pll_lock;

//------------------------------------------------------------------
// 【像素格式诊断显示】把读数画成黑白位带（白=1，暗灰=0）
//   band0 (y   0.. 99)：datatype 6 位，每段 128px，左起 bit5
//   band1 (y 100..199)：word_count 16 位，每段 64px，左起 bit15
//   band2 (y 200..299)：每行 pixel_data_valid 数（×4 = 每行像素），16 位
//   band3 (y 300..399)：每帧行数（hsync 计数），16 位
//   band4 (y 400..499)：diag_flags 8 位，每段 128px
//   band5 (y 500..599)：暗灰，用于确认有效区边界
reg [10:0] hcnt;
reg [10:0] vcnt;

wire de_h   = (hcnt >= 11'd160) && (hcnt < 11'd1184);   // 40+120=160, +1024=1184
wire de_v   = (vcnt >= 11'd23)  && (vcnt < 11'd623);    //  3+20= 23, + 600 = 623
wire de_act = de_h && de_v;

wire [10:0] dxv = hcnt - 11'd160;
wire [10:0] dyv = vcnt - 11'd23;
wire [9:0]  dx  = dxv[9:0];     // 0..1023
wire [9:0]  dy  = dyv[9:0];     // 0..599

wire [3:0]  idx16 = dx[9:6];    // 16 段，每段 64px
wire [2:0]  idx8  = dx[9:7];    //  8 段，每段 128px
wire [5:0]  sub16 = dx[5:0];
wire [6:0]  sub8  = dx[6:0];

wire gap16 = (sub16 >= 6'd60);  // 每段末尾 4px 缝隙
wire gap8  = (sub8  >= 7'd120); // 每段末尾 8px 缝隙

// 版式（y 为有效区内行号）：
//   0.. 59  : 纯白条（LVDS 通路自检，一定是干净的一条白带）
//   60..167 : datatype 6 位，128px/段（只用到 6 段，右侧 2 段灰）
//  168..275 : word_count 16 位，64px/段
//  276..383 : 每行 pixel_data_valid 数，16 位
//  384..491 : 每帧行数，16 位
//  492..599 : 标志位 8 位，128px/段
// 白=1，黑=0，缝隙/空段=暗灰
wire w_top  = (dy < 10'd60);
wire bA     = (dy >= 10'd60)  && (dy < 10'd168);
wire bB     = (dy >= 10'd168) && (dy < 10'd276);
wire bC     = (dy >= 10'd276) && (dy < 10'd384);
wire bD     = (dy >= 10'd384) && (dy < 10'd492);
wire bE     = (dy >= 10'd492);

// clk_sys → clk_lvds_1x 两级同步（数值准静态，慢变）
reg [5:0]  dt_d1, dt_d2;
reg [15:0] wc_d1, wc_d2, px_d1, px_d2, ln_d1, ln_d2;
reg [7:0]  fg_d1, fg_d2;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        dt_d1 <= 6'd0;  dt_d2 <= 6'd0;
        wc_d1 <= 16'd0; wc_d2 <= 16'd0;
        px_d1 <= 16'd0; px_d2 <= 16'd0;
        ln_d1 <= 16'd0; ln_d2 <= 16'd0;
        fg_d1 <= 8'd0;  fg_d2 <= 8'd0;
    end
    else
    begin
        dt_d1 <= diag_dt; dt_d2 <= dt_d1;
        wc_d1 <= diag_wc; wc_d2 <= wc_d1;
        px_d1 <= diag_px; px_d2 <= px_d1;
        ln_d1 <= diag_ln; ln_d2 <= ln_d1;
        fg_d1 <= diag_flags; fg_d2 <= fg_d1;
    end
end

// 每帧起始锁存一次，保证一屏内位带不跳变
reg [5:0]  disp_dt;
reg [15:0] disp_wc, disp_px, disp_ln;
reg [7:0]  disp_flg;
always @(posedge clk_lvds_1x)
begin
    if((hcnt == 11'd0) && (vcnt == 11'd0))
    begin
        disp_dt  <= dt_d2;
        disp_wc  <= wc_d2;
        disp_px  <= px_d2;
        disp_ln  <= ln_d2;
        disp_flg <= fg_d2;
    end
end

//------------------------------------------------------------------
// 【帧缓存 512×300 ×2 ping-pong】彻底消除读写撕裂
//   水平 1280→512：每个 dvalid 送 4 像素，用累加器保留 40%（平均 1.6 个/组）
//   垂直 960→300 ：每输入行 acc += 300，满 960 保留一行（16 行取 5 行）
//   双缓冲：摄像头每帧开头切换写入块，显示始终读“上一帧已写完”的那块
localparam FBW = 256;          // 每个 bank 每行字数（512 列 / 2）
localparam FBD = 300*FBW;      // 76800 字 / 每个缓冲 bank

// 两组缓冲 × 两个 bank：A0/A1（缓冲A 偶/奇列）与 B0/B1（缓冲B 偶/奇列）
reg [5:0] fbufA0 [0:FBD-1];
reg [5:0] fbufA1 [0:FBD-1];
reg [5:0] fbufB0 [0:FBD-1];
reg [5:0] fbufB1 [0:FBD-1];

reg        wr_buf;        // 0=A 1=B：当前写入缓冲
reg [8:0]  wr_row;        // 0..299
reg [8:0]  wr_col;        // 0..255
reg [2:0]  grp_ph;        // 0..4，ph==4 的组整组跳过（320 组 → 256 组）
reg [11:0] acc_v;         // 垂直累加器：每行 +300，满 960 保留一行
reg        row_keep;

wire [16:0] wr_addr  = ({8'd0, wr_row} << 8) + {9'd0, wr_col};
wire        grp_keep = (grp_ph != 3'd4);
wire        wr_en    = csi_rx_hsync & csi_rx_dvalid & row_keep & grp_keep;

// 同组 4 个 10bit 像素两两平均（2x1 binning）：A2020 是 Bayer 彩色传感器，
// 相邻像素颜色通道不同、亮度系统性不同；原来隔点抽样（只取第 0、2 个）会把
// 这种通道差直接变成颗粒噪点。平均后颗粒减半、亮度更接近真实，输出仍是 2 列。
wire [10:0] sum01 = {1'b0, csi_rx_data[39:30]} + {1'b0, csi_rx_data[29:20]};
wire [10:0] sum23 = {1'b0, csi_rx_data[19:10]} + {1'b0, csi_rx_data[ 9: 0]};

always @(posedge clk_sys or negedge rstn_sys)
begin
    if(!rstn_sys)
    begin
        wr_buf   <= 1'b0;
        wr_row   <= 9'd0;
        wr_col   <= 9'd0;
        grp_ph   <= 3'd0;
        acc_v    <= 12'd0;
        row_keep <= 1'b1;
    end
    else
    begin
        // 本组平均后的两个像素同时写入同一缓冲的两个 bank（取均值高 6 位）
        if(wr_en)
        begin
            if(wr_buf)
            begin
                fbufB0[wr_addr] <= sum01[10:5];
                fbufB1[wr_addr] <= sum23[10:5];
            end
            else
            begin
                fbufA0[wr_addr] <= sum01[10:5];
                fbufA1[wr_addr] <= sum23[10:5];
            end
            wr_col <= wr_col + 9'd1;
        end

        // 组相位：5 组里跳过 1 组 → 4/5 × 1280 = 512 列
        if(csi_rx_hsync & csi_rx_dvalid)
            grp_ph <= (grp_ph == 3'd4) ? 3'd0 : (grp_ph + 3'd1);

        if(vs_rise)
        begin
            wr_buf   <= ~wr_buf;     // 换到另一块写，上一帧保持不动
            wr_row   <= 9'd0;
            wr_col   <= 9'd0;
            grp_ph   <= 3'd0;
            acc_v    <= 12'd0;
            row_keep <= 1'b1;
        end
        else if(hs_rise)
        begin
            wr_col <= 9'd0;
            grp_ph <= 3'd0;
            acc_v  <= acc_v + 12'd300;
            if(acc_v + 12'd300 >= 12'd960)
            begin
                acc_v    <= acc_v + 12'd300 - 12'd960;
                row_keep <= 1'b1;
                wr_row   <= (wr_row == 9'd299) ? 9'd0 : (wr_row + 9'd1);
            end
            else
                row_keep <= 1'b0;
        end
    end
end

//------------------------------------------------------------------
// 【显示读地址】512×300 → 2× 整数放大，铺满 1024×600
//   屏上 (dx,dy) → 缓存像素 (dx>>1, dy>>1)，整数放大、地址单调
wire [9:0] src_col = {1'b0, dx[9:1]};            // 0..511
wire [9:0] src_row = {1'b0, dy[9:1]};            // 0..299

wire [7:0]  scol    = src_col[8:1];              // 每个 bank 字地址 0..255
wire        sbank   = src_col[0];
wire [16:0] rd_addr = ({8'd0, src_row} << 8) + {10'd0, scol};

// 写指针同步到显示时钟域；每显示帧开头锁存“未在写”的那块作为只读源
reg [1:0] wb_sync;
reg       rdBuf;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        wb_sync <= 2'b00;
        rdBuf   <= 1'b0;
    end
    else
    begin
        wb_sync <= {wb_sync[0], wr_buf};
        if(de_act && (dy == 10'd0) && (dx == 10'd0))
            rdBuf <= ~wb_sync[1];
    end
end

// 源像素是否变化（中值滤波流水线的 valid 门控：2× 放大下每两个时钟一个像素）
reg [9:0] col_d, row_d;
wire src_new = (src_col != col_d) | (src_row != row_d);

reg [5:0] ra0, ra1, rb0, rb1, rd_pix;
reg       sel_d, de_d1;
reg       vld_d, sof_d, eol_d;
reg       vld_d2, sof_d2, eol_d2, de_d2;

always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        col_d  <= 10'd0;
        row_d  <= 10'd0;
        ra0    <= 6'd0;
        ra1    <= 6'd0;
        rb0    <= 6'd0;
        rb1    <= 6'd0;
        rd_pix <= 6'd0;
        sel_d  <= 1'b0;
        de_d1  <= 1'b0;
        vld_d  <= 1'b0;
        sof_d  <= 1'b0;
        eol_d  <= 1'b0;
    end
    else
    begin
        col_d  <= src_col;
        row_d  <= src_row;
        ra0    <= fbufA0[rd_addr];
        ra1    <= fbufA1[rd_addr];
        rb0    <= fbufB0[rd_addr];
        rb1    <= fbufB1[rd_addr];
        sel_d  <= sbank;
        rd_pix <= rdBuf ? (sel_d ? rb1 : rb0) : (sel_d ? ra1 : ra0);
        de_d1  <= de_act;
        vld_d  <= src_new;
        sof_d  <= src_new & (src_col == 10'd0) & (src_row == 10'd0) & (dy == 10'd0);
        eol_d  <= src_new & (src_col == 10'd511);
        // 第二级延迟：rd_pix 相对地址晚 2 拍（BRAM 1 拍 + bank 选择 1 拍），
        // valid/sof/eol 也同步到第 2 拍，与 pix6 数据对齐
        vld_d2 <= vld_d;
        sof_d2 <= sof_d;
        eol_d2 <= eol_d;
        de_d2  <= de_d1;
    end
end

//------------------------------------------------------------------
// 【光照补偿】近距拍摄时照明集中在画面中心、四周存在明显暗角。
//   按“到画面中心的距离”施加 1.0x ~ 1.4x 的径向增益，把四周提亮。
//   增益同时作用于显示与检测，检测的亮度参考也随之自动抬高。
//------------------------------------------------------------------
reg [9:0] dsx1, dsx2, dsy1, dsy2;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n)
    begin
        dsx1 <= 10'd0; dsx2 <= 10'd0; dsy1 <= 10'd0; dsy2 <= 10'd0;
    end
    else
    begin
        dsx1 <= dx; dsx2 <= dsx1;
        dsy1 <= dy; dsy2 <= dsy1;
    end

wire [9:0]  rcx = (dsx2 > 10'd512) ? (dsx2 - 10'd512) : (10'd512 - dsx2);
wire [9:0]  rcy = (dsy2 > 10'd300) ? (dsy2 - 10'd300) : (10'd300 - dsy2);
wire [11:0] rrr = {2'b0, rcx} + {4'b0, rcy};            // 0 ~ 812
wire [11:0] rrg = (rrr > 12'd400) ? 12'd400 : rrr;      // 限制最大增益
wire [11:0] rmg = 12'd256 + {1'b0, rrg[11:1]};         // 中心 1.00x，边缘 1.78x
                                                        // （原 1.39x 不足以压平近距 LED 暗角 -> 暗区被误判缺陷）
wire [16:0] rmp = rd_pix * rmg;
wire [5:0]  pix6 = (rmp[13:8] > 8'd63) ? 6'd63 : rmp[13:8];

//------------------------------------------------------------------
// 【自适应增益】放在中值滤波之前，显示和检测共用
//   按上一帧平均亮度选一个 1x/2x/3x/4x 的全局增益，只放大暗画面、亮画面保持 1x。
//   关键：只做等比例放大，不做“减最小值+重定标”。白纸这种几乎没有明暗差的场景，
//   若减掉最小值再拉伸，整幅会被压成 0（白纸显示成黑），检测也会一起失效。
//   放大后的数据同时送中值滤波（显示链路）和缺陷检测，检测灵敏度自动跟随画面亮度。
//------------------------------------------------------------------
wire       in_vld = vld_d & de_act;
reg [23:0] fsum;          // 帧内亮度累加：153600 x63 ≈ 9.7M
reg [5:0]  mean6;         // 上一帧平均亮度（6bit）

// 【帧同步标志】用显示域坐标取“第一行的中间位置”触发：
//   dy==0 会持续整条行（1024 拍），dx==512 在其中间，因此 de_act 与 dx/dy 即使有
//   1~2 拍相位差也一定能踩中，且每帧恰好一次。
//   原来的 dx==0 恰好处在相位差边界上，一次都没触发过 -> seg_lat/mean6/th6 全部冻结
wire frm_sof = de_act && (dy == 10'd0) && (dx == 10'd512);
wire       f_start = frm_sof;

// 注意：统计脉冲在显示域，每个源行放大显示 2 行，每帧样本数 = 600x512 = 307200，
// 不是源像素数 153600。若按 153600 除，均值会虚高一倍 -> 自适应支点虚高 + AGC
// 档位偏低，两者叠加把暗画面整体压黑（pa - m6 大面积为负被削到 0）。
wire [8:0]  fq  = fsum[23:18];          // 307200 像素 -> >>18 得 1.17 倍偏大
wire [11:0] fm  = {3'd0, fq} * 12'd7;    // 再 x7/8 抵消
wire [8:0]  mc  = fm[11:3];
wire [5:0]  mean_n = (mc > 9'd63) ? 6'd63 : mc[5:0];

always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        fsum  <= 24'd0;
        mean6 <= 6'd32;
    end
    else
    begin
        if(in_vld)
            fsum <= fsum + {18'd0, pix6};

        if(f_start)
        begin
            mean6 <= mean_n;
            fsum  <= 24'd0;
        end
    end
end

// 1x/2x/3x 全局增益（只放大，不重定标；亮场景保持 1x 不削顶）
// frm_sof 修复后 mean6 每帧真实更新，可以安全恢复 AGC；
// 上限 3 倍（不上 4 倍），避免暗场景把量化噪声也放大成雪花
wire [1:0] gsel = (mean6 < 6'd12) ? 2'd2 :       // 很暗 -> 3 倍
                  ((mean6 < 6'd22) ? 2'd1 : 2'd0); // 偏暗 -> 2 倍，其余 1 倍
wire [8:0] p4 = {1'd0, pix6} * 9'd4;
wire [8:0] p3 = {3'd0, pix6} * 9'd3;
wire [8:0] p2 = {2'd0, pix6} * 9'd2;
wire [8:0] pm = (gsel == 2'd3) ? p4 :
                ((gsel == 2'd2) ? p3 :
                 ((gsel == 2'd1) ? p2 : {1'b0, pix6}));

//------------------------------------------------------------------
// 【对比度增强】以“增益后的平均亮度 m6”为中心做 2 倍展开：
//   out = m6 + 2 x (pixel - m6)，超出 0~63 的部分削顶
//   倍数取 2 而不是 3：近距离拍摄时镜头边缘本来就有明显暗角，
//   3 倍展开会把边缘暗部直接压成纯黑（只剩中间一块能看清），2 倍可兼顾通透和四周可见。
//------------------------------------------------------------------
wire [5:0]  pa  = (pm > 9'd63) ? 6'd63 : pm[5:0];              // 增益后的像素
wire [8:0]  m6x = {3'd0, mean6} << gsel;                        // 增益后的平均亮度
// 自适应支点 = 增益后的帧平均亮度：暗场景支点低（不会把画面压黑），亮场景支点高
wire [5:0]  m6  = (m6x > 9'd63) ? 6'd63 : m6x[5:0];

// 帧内最小/最大（用于缺陷阈值，与 pa 同域，每帧更新）
reg [5:0] mn6, mx6, th6;
wire [5:0] rng6 = mx6 - mn6;
wire      f_end = frm_sof;      // 同一帧同步标志：与 f_start 同拍更新统计并清零

//------------------------------------------------------------------
// 【增强流水线】3x3 中值降噪 → Gamma 校正 → 自适应对比度拉伸 → 水平锐化
//   数据源：帧缓存读出的 512x300 6bit 灰度（显示域 48MHz，每 2 个时钟 1 个源像素）
//   同一个中值模块的 3x3 邻域和还用于缺陷检测的自适应阈值，零额外 RAM
//------------------------------------------------------------------
wire [5:0]  med_pix;
wire [5:0]  ctr_pix;      // 3x3 窗口的中心像素（用于缺陷判据，不参与显示）
wire [12:0] win_sum;      // 3x3 九像素之和（最大 9x63 = 567）
wire        med_vld;

median_filter_3x3 #(.IMG_WIDTH(512), .DATA_WIDTH(6)) u_median_filter
(
    .clk       (clk_lvds_1x),
    .rst_n     (rst_lvds_n),
    // 每行都进中值（不要半速率门控）：A2020 是 Bayer 彩色传感器，相邻源行是
    // 不同颜色通道，亮度系统性不同，直通显示会逐行明暗交替 -> 满屏细密横纹。
    // 3x3 中值跨 3 行取中值，天然抹平 Bayer 行交替；行缓存重复行造成的轻微
    // 差异远小于 Bayer 交替幅度。de_d2 门控保留：挡掉行消隐期的多余脉冲
    .valid_in  (vld_d2 & de_d2),
    .sof_in    (sof_d2),
    .eol_in    (eol_d2),
    .data_in   (pa),
    .data_out  (med_pix),
    .center_out(ctr_pix),
    .sum_out   (win_sum),
    .valid_out (med_vld),
    .sof_out   (),
    .eol_out   ()
);

//------------------------------------------------------------------
// 显示：帧缓存直通 + 垂直 2 行平均（vavg2 模块，抹平 Bayer 行交替横纹）。
// 中值滤波不直接上屏（其列相位会引入竖纹），只服务检测统计
//------------------------------------------------------------------
wire [5:0] va_pix;
vavg2 #(.IMG_WIDTH(512), .DATA_WIDTH(6)) u_vavg
(
    .clk       (clk_lvds_1x),
    .rst_n     (rst_lvds_n),
    .valid_in  (vld_d2 & de_d2),
    .data_in   (pa),
    .data_out  (va_pix)
);

wire signed [10:0] dsub = $signed({2'b0, med_pix}) - $signed({2'b0, m6});
wire signed [10:0] dmul = dsub * 11'sd2;
wire signed [10:0] dadd = $signed({2'b0, m6}) + dmul;
wire [5:0] pix6d = rd_pix;   // 对照实验：显示完全直通帧缓存（11-03 确认清晰的链路），
                             // 径向增益/AGC/vavg2 全部移出显示路径（检测链不变，仍吃 pa/中值）

// 帧内最小/最大值统计（与 pa 同域）→ 帧末生成缺陷阈值 th6 = (mn+mx)/2
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        mn6 <= 6'd63; mx6 <= 6'd0; th6 <= 6'd8;
    end
    else
    begin
        if(de_act)
        begin
            if(pa < mn6) mn6 <= pa;
            if(pa > mx6) mx6 <= pa;
        end
        if(f_end) begin
            // 差值阈值 = 量程的 1/4（下限 10 级，压住暗画面残余噪声）
            th6 <= ({1'b0, rng6[5:2]} > 6'd10) ? {1'b0, rng6[5:2]} : 6'd10;
            mn6 <= 6'd63;
            mx6 <= 6'd0;
        end
    end
end

// Gamma 校正表：6bit(64 级) -> 8bit，γ≈0.7（暗部提亮、亮部压缩）
function [7:0] gamma_f;
    input [5:0] x;
    begin
        case(x)
        6'd0 : gamma_f = 8'd0;    6'd1 : gamma_f = 8'd2;    6'd2 : gamma_f = 8'd7;
        6'd3 : gamma_f = 8'd12;   6'd4 : gamma_f = 8'd18;   6'd5 : gamma_f = 8'd24;
        6'd6 : gamma_f = 8'd30;   6'd7 : gamma_f = 8'd35;   6'd8 : gamma_f = 8'd41;
        6'd9 : gamma_f = 8'd46;   6'd10: gamma_f = 8'd52;   6'd11: gamma_f = 8'd57;
        6'd12: gamma_f = 8'd62;   6'd13: gamma_f = 8'd66;   6'd14: gamma_f = 8'd71;
        6'd15: gamma_f = 8'd76;   6'd16: gamma_f = 8'd81;   6'd17: gamma_f = 8'd85;
        6'd18: gamma_f = 8'd90;   6'd19: gamma_f = 8'd95;   6'd20: gamma_f = 8'd99;
        6'd21: gamma_f = 8'd104;  6'd22: gamma_f = 8'd108;  6'd23: gamma_f = 8'd112;
        6'd24: gamma_f = 8'd117;  6'd25: gamma_f = 8'd121;  6'd26: gamma_f = 8'd125;
        6'd27: gamma_f = 8'd130;  6'd28: gamma_f = 8'd134;  6'd29: gamma_f = 8'd138;
        6'd30: gamma_f = 8'd142;  6'd31: gamma_f = 8'd146;  6'd32: gamma_f = 8'd150;
        6'd33: gamma_f = 8'd154;  6'd34: gamma_f = 8'd159;  6'd35: gamma_f = 8'd162;
        6'd36: gamma_f = 8'd166;  6'd37: gamma_f = 8'd170;  6'd38: gamma_f = 8'd174;
        6'd39: gamma_f = 8'd178;  6'd40: gamma_f = 8'd182;  6'd41: gamma_f = 8'd186;
        6'd42: gamma_f = 8'd190;  6'd43: gamma_f = 8'd194;  6'd44: gamma_f = 8'd197;
        6'd45: gamma_f = 8'd201;  6'd46: gamma_f = 8'd205;  6'd47: gamma_f = 8'd209;
        6'd48: gamma_f = 8'd213;  6'd49: gamma_f = 8'd217;  6'd50: gamma_f = 8'd220;
        6'd51: gamma_f = 8'd224;  6'd52: gamma_f = 8'd228;  6'd53: gamma_f = 8'd232;
        6'd54: gamma_f = 8'd235;  6'd55: gamma_f = 8'd239;  6'd56: gamma_f = 8'd243;
        6'd57: gamma_f = 8'd246;  6'd58: gamma_f = 8'd250;  6'd59: gamma_f = 8'd253;
        6'd60: gamma_f = 8'd255;  6'd61: gamma_f = 8'd255;  6'd62: gamma_f = 8'd255;
        default: gamma_f = 8'd255;
        endcase
    end
endfunction

// ---- 显示侧 AGC：按上一帧平均亮度 mean6 自动选 1x/2x/3x/4x 增益 ----
//   检测链的 gsel 上限 3x（怕放大噪点误报），显示侧放到 4x：暗场景“有台阶但能看”
//   远好过“全黑看不见”。帧首才调档，且估计均值落在 24~48 舒适区内就保持不动
//  （迟滞），避免均值在阈值边界抖动时亮度逐帧闪烁。
reg  [1:0] dgsel;                            // 显示增益档：0=1x 1=2x 2=3x 3=4x
wire [2:0] dgain = (dgsel == 2'd3) ? 3'd4 : (dgsel == 2'd2) ? 3'd3 :
                   (dgsel == 2'd1) ? 3'd2 : 3'd1;
wire [9:0] est_mean = {4'd0, mean6} * {7'd0, dgain};   // 当前档位下的估计均值
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n) dgsel <= 2'd0;
    else if(f_start)
    begin
        if((est_mean < 10'd24) && (dgsel < 2'd3)) dgsel <= dgsel + 2'd1;
        else if((est_mean > 10'd48) && (dgsel > 2'd0)) dgsel <= dgsel - 2'd1;
    end

// ---- 6bit 域先增益、再线性扩 8bit（{x, x高2位}），不用 Gamma LUT ----
wire [8:0] pd1 = {3'd0, pix6d};               // 1x
wire [8:0] pd2 = {2'd0, pix6d} * 9'd2;        // 2x
wire [8:0] pd3 = {3'd0, pix6d} * 9'd3;        // 3x
wire [8:0] pd4 = {1'd0, pix6d} * 9'd4;        // 4x
wire [8:0] pd_m = (dgsel == 2'd3) ? pd4 : (dgsel == 2'd2) ? pd3 :
                  (dgsel == 2'd1) ? pd2 : pd1;
wire [5:0] pix6g = (pd_m > 9'd63) ? 6'd63 : pd_m[5:0];   // 增益后削顶
wire [7:0] gm_pix = {pix6g, pix6g[5:4]};

reg [7:0] gm_r;
reg       gm_v;
reg [7:0] st_r;
reg       st_v;

always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        gm_r <= 8'd0;  gm_v <= 1'b0;
        st_r <= 8'd0;  st_v <= 1'b0;
    end
    else
    begin
        gm_r <= gm_pix;
        // 锐化移位必须按“新像素”节奏（每 2 拍一个），不能每拍移：
        // 每拍移位会让同一像素在窗口里出现两次，输出在 (9P-P0)/8 与 (9P-P2)/8
        // 之间逐列交替 -> 满屏规则竖纹
        gm_v <= vld_d2;
        st_r <= gm_pix;
        st_v <= gm_v;
    end
end

// ---- 水平锐化（一维非锐化掩模）----
//   out = c + (c - (l+r)/2) / 4 = (10c - l - r) / 8
//   （1/4 增益：1/2 会把像素级噪点放大一倍，暗光下会满屏雪花）
reg [7:0] sh1, sh2, sh3;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n) begin sh1 <= 8'd0; sh2 <= 8'd0; sh3 <= 8'd0; end
    else if(st_v)   begin sh1 <= sh2; sh2 <= sh3; sh3 <= st_r; end
end

// 锐化全增益：(16c - 4l - 4r)/8 = 2c - (l+r)/2 = c + (c-(l+r)/2)，平坦区 = c。
// 采集端 2x1 binning 已把颗粒噪点减半，可以承受全增益非锐化掩模，边缘最挺
wire [13:0] sh_c16 = {4'd0, sh2} * 14'd16;                 // 16 x 中心像素
wire [12:0] sh_lr4 = ({5'd0, sh1} + {5'd0, sh3}) * 13'd4;  // 4 x (左 + 右)
wire [14:0] sh_num = {1'b0, sh_c16} - {2'b00, sh_lr4};     // 可为负（bit14=符号位）
wire [11:0] sh_q   = sh_num[14] ? 12'd0 : sh_num[14:3];
wire [7:0]  sh_val = sh_num[14] ? 8'h00 :
                     ((|sh_q[11:8]) ? 8'hFF : sh_q[7:0]);

reg [7:0] o_pix;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n) o_pix <= 8'd0; else o_pix <= sh_val;

// 显示路径延迟 = 6 拍（BRAM 2 + vavg组合 0 + 扩展寄存 1 + 拉伸寄存 1 + 锐化移位 2）
reg [5:0] de_sr;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n) de_sr <= 6'd0; else de_sr <= {de_sr[4:0], de_act};
wire de_out = de_sr[5];

//------------------------------------------------------------------
// 【缺陷检测】自适应灰度阈值分割 + 面积滤波 + 位置统计
//   自适应阈值：中心像素比 3x3 邻域均值暗 ADAPT_OFF 以上就判为候选像素，
//               用“局部相对亮度”而非全局阈值，避免暗角/光照不均误报
//   面积滤波  ：连续 >= 2 个候选像素才确认为缺陷，滤掉孤立噪点
//   位置统计  ：按源行记录缺陷列最小/最大值，用于连通域合并计数和画标记框
//------------------------------------------------------------------
localparam [6:0] ADAPT_OFF = 7'd9;    // 比邻域均值暗多少（6bit 域，约 14% 满量程）
localparam [5:0] AREA_MIN  = 6'd6;    // 连续候选像素达到 7 个才确认（面积滤波）缺陷
localparam [9:0] SEG_ALARM = 10'd1;   // 检测到 1 个真实缺陷块（面积>=12）即报警

//------------------------------------------------------------------
// 自适应灰度阈值分割（全局自适应）：低于“本帧平均亮度的一半”判为缺陷候选
//   为什么不用 3x3 局部均值：6bit 数据里局部均值与中心像素的差值只有几级，
//   而 3x3 窗口本身又会把细划痕抹平，实测多次都触发不了。
//   这里用帧平均亮度做主参考：白纸+黑点场景均值约 45 -> 阈值 22，黑点（~15）稳定触发；
//   环境整体变暗/变亮时阈值自动跟着移动，不需要人工调参。
//------------------------------------------------------------------
// 判据【单极性·暗缺陷】：比“本帧平均亮度”暗超过阈值即候选像素
//   之前用双极性（亮斑也算），但镜头眩光/固定光斑每帧都比均值亮，会被误判成
//   “亮斑缺陷”导致报警常驻；只检暗缺陷（黑点/划痕）可彻底避开眩光干扰
// 判据【单极性·暗缺陷 + 2D 证据】：
//   ① 中心像素比“本帧平均亮度”暗超过阈值（原有）
//   ② 整个 3x3 邻域之和也明显偏暗（新增）：真黑点是一小片、邻域跟着暗；
//      孤立噪点邻居正常 -> 邻域和不低 -> 被排除。AGC 放大噪点导致的
//     “候选像素满屏乱撒”由这一条彻底掐死。
wire [5:0]  thr_lv  = (m6 > th6) ? (m6 - th6) : 6'd0;      // 缺陷亮度上限
wire [9:0]  sum_thr = {4'd0, thr_lv} * 10'd9;              // 3x3 邻域和上限
wire        dark2d  = (win_sum < {3'd0, sum_thr});         // 邻域整体偏暗
wire signed [7:0] dvi   = $signed({1'b0, med_pix}) - $signed({1'b0, m6});
wire [6:0]        dvi_a = dvi[7] ? ((~dvi[6:0]) + 7'd1) : dvi[6:0];
wire       cand_all = dvi[7] && (dvi_a > {1'b0, th6}) && dark2d;   // 真检测
wire       cand     = cand_all && det_roi;

// 中值输出比帧缓存读出地址晚 3 拍，坐标需同步延迟后再做位置统计
// dxd6/dyd6 再延 3 拍：与显示输出 o_pix（地址相位后 6 拍）对齐，用于画红框
reg [9:0] dxd1, dxd2, dxd3, dxd4, dxd5, dxd6;
reg [9:0] dyd1, dyd2, dyd3, dyd4, dyd5, dyd6;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n) begin
        dxd1 <= 10'd0; dxd2 <= 10'd0; dxd3 <= 10'd0;
        dxd4 <= 10'd0; dxd5 <= 10'd0; dxd6 <= 10'd0;
        dyd1 <= 10'd0; dyd2 <= 10'd0; dyd3 <= 10'd0;
        dyd4 <= 10'd0; dyd5 <= 10'd0; dyd6 <= 10'd0;
    end
    else begin
        dxd1 <= dx;  dxd2 <= dxd1; dxd3 <= dxd2;
        dxd4 <= dxd3; dxd5 <= dxd4; dxd6 <= dxd5;
        dyd1 <= dy;  dyd2 <= dyd1; dyd3 <= dyd2;
        dyd4 <= dyd3; dyd5 <= dyd4; dyd6 <= dyd5;
    end

wire [9:0] dcol = {1'b0, dxd3[9:1]};   // 与中值/中心像素同步的源列
wire [9:0] drow = {1'b0, dyd3[9:1]};   // 与中值/中心像素同步的源行

// 检测有效区：去掉镜头边缘暗角（边缘亮度骤降会被误判成缺陷）
wire       det_roi = (dcol >= 10'd20) && (dcol < 10'd492) &&
                     (drow >= 10'd10) && (drow < 10'd290);

reg [5:0] run;
reg       conf;

always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        run  <= 6'd0;
        conf <= 1'b0;
    end
    // 中值全速率后 med_vld 每个源行来两次（放大成两行），用 ~dyd3[0] 只在
    // 偶数屏幕行统计，每个源行恰好检测一次，连通域不会重复计数
    else if(med_vld && de_act && ~dyd3[0])
    begin
        if(dcol == 10'd0)
            run <= cand ? 6'd1 : 6'd0;
        else if(cand)
            run <= (run == 6'd63) ? 6'd63 : (run + 6'd1);
        else
            run <= 6'd0;

        conf <= cand && (run >= AREA_MIN) && (dcol != 10'd0);
    end
    else if(!de_act)
        conf <= 1'b0;
end

// ---- 缺陷位置（按源行 0..299 记录缺陷列最小/最大值，同时用于连通域合并）----
reg [9:0] rmin_cur [0:299];
reg [9:0] rmax_cur [0:299];
reg [9:0] rmin_prv [0:299];
reg [9:0] rmax_prv [0:299];

reg  [8:0] blk_idx;
reg        blk_run;
integer    i;

wire [8:0] row_w  = (drow > 10'd299) ? 9'd0 : drow[8:0];       // 写地址（钳位）
wire [8:0] row_u  = (drow == 10'd0)  ? 9'd0 : (drow[8:0] - 9'd1);
wire [8:0] row_rd = (src_row > 10'd299) ? 9'd0 : src_row[8:0]; // 画框读地址（显示坐标）
// 有效显示区结束后的垂直消隐期：把本帧结果搬到 prv 并清空 cur
wire vstart = (hcnt == 11'd0) && (vcnt == 11'd630);

// 与上一（采样）行的缺陷跨度重叠 -> 属于同一个缺陷，不重复计数
wire [9:0] rmin_u = rmin_cur[row_u];
wire [9:0] rmax_u = rmax_cur[row_u];
wire       up_hit = (rmax_u >= rmin_u) && (drow != 10'd0);
wire       blob_cont = up_hit && (dcol >= (rmin_u - 10'd4)) && (dcol <= (rmax_u + 10'd4));
// 缺陷起点且与上一行不连通 -> 计为一个新缺陷
// 注意：conf 为高时 run 已经包含了“当前像素”，所以连续候选中的第 2 个像素对应
// run == AREA_MIN + 1（原来是 run == AREA_MIN，永远不可能成立 -> 缺陷个数恒为 0）
wire       new_blob = conf && (run == (AREA_MIN + 6'd1)) && !blob_cont;

reg [9:0]  seg_cnt, seg_lat;   // 缺陷个数（连通域，按行合并）
reg [11:0] px_cnt,  px_lat;    // 缺陷像素总数（面积）

// ---- 最大连通块包围盒：检测域逐像素跟踪当前块 cb_*，帧首把最大块锁存到 mx_*_l，
//   屏上只画这一个空心红框。不做全局包围盒（缺陷一分散会框住全屏），
//   也不填充涂红（用户要"框起来"，不是涂满） ----
reg [9:0]  cb_cmin, cb_cmax, cb_rmin, cb_rmax;
reg [11:0] cb_px;
reg [9:0]  mx_cmin, mx_cmax, mx_rmin, mx_rmax;
reg [11:0] mx_px;
reg [9:0]  mx_cmin_l, mx_cmax_l, mx_rmin_l, mx_rmax_l;
reg [11:0] mx_px_l;

always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        seg_cnt <= 10'd0;  seg_lat <= 10'd0;
        px_cnt  <= 12'd0;  px_lat  <= 12'd0;
        blk_idx <= 9'd0;
        blk_run <= 1'b0;
        cb_cmin <= 10'd1023;  cb_cmax <= 10'd0;
        cb_rmin <= 10'd1023;  cb_rmax <= 10'd0;
        cb_px   <= 12'd0;
        mx_cmin <= 10'd1023;  mx_cmax <= 10'd0;
        mx_rmin <= 10'd1023;  mx_rmax <= 10'd0;
        mx_px   <= 12'd0;
        mx_cmin_l <= 10'd1023; mx_cmax_l <= 10'd0;
        mx_rmin_l <= 10'd1023; mx_rmax_l <= 10'd0;
        mx_px_l   <= 12'd0;
        for(i = 0; i < 300; i = i + 1)
        begin
            rmin_cur[i] <= 10'd1023;
            rmax_cur[i] <= 10'd0;
            rmin_prv[i] <= 10'd1023;
            rmax_prv[i] <= 10'd0;
        end
    end
    else
    begin
        if(conf)
        begin
            if(px_cnt != 12'd4095)               px_cnt  <= px_cnt + 1'b1;
            // 连通块“结算时”才计数：上一个块面积 >=12 源像素才算真缺陷，
            // 镜头伪影/噪点小块直接不计入，屏上数字 = 真实黑点个数
            if(new_blob && (cb_px >= 12'd12) && (seg_cnt != 10'd999))
                seg_cnt <= seg_cnt + 1'b1;

            if(dcol < rmin_cur[row_w]) rmin_cur[row_w] <= dcol;
            if(dcol > rmax_cur[row_w]) rmax_cur[row_w] <= dcol;

            // 连通块包围盒：new_blob=新块起点（结算上一块并重开），否则扩展当前块
            if(new_blob)
            begin
                if(cb_px > mx_px)
                begin
                    mx_px   <= cb_px;
                    mx_cmin <= cb_cmin;  mx_cmax <= cb_cmax;
                    mx_rmin <= cb_rmin;  mx_rmax <= cb_rmax;
                end
                cb_cmin <= dcol;  cb_cmax <= dcol;
                cb_rmin <= drow;  cb_rmax <= drow;
                cb_px   <= 12'd1;
            end
            else
            begin
                if(dcol < cb_cmin) cb_cmin <= dcol;
                if(dcol > cb_cmax) cb_cmax <= dcol;
                if(drow > cb_rmax) cb_rmax <= drow;
                if(cb_px != 12'd4095) cb_px <= cb_px + 1'b1;
            end
        end

        if(f_start)
        begin
            // 帧尾结算最后一块：面积达标同样计入后再锁存
            seg_lat <= seg_cnt + ((cb_px >= 12'd12) ? 10'd1 : 10'd0);
            px_lat  <= px_cnt;
            seg_cnt <= 10'd0;
            px_cnt  <= 12'd0;

            // 帧尾结算最后一块，把本帧最大块锁存给显示画框
            if(cb_px > mx_px)
            begin
                mx_cmin_l <= cb_cmin;  mx_cmax_l <= cb_cmax;
                mx_rmin_l <= cb_rmin;  mx_rmax_l <= cb_rmax;
                mx_px_l   <= cb_px;
            end
            else
            begin
                mx_cmin_l <= mx_cmin;  mx_cmax_l <= mx_cmax;
                mx_rmin_l <= mx_rmin;  mx_rmax_l <= mx_rmax;
                mx_px_l   <= mx_px;
            end
            cb_px <= 12'd0;  mx_px <= 12'd0;
            cb_cmin <= 10'd1023;  cb_cmax <= 10'd0;
            cb_rmin <= 10'd1023;  cb_rmax <= 10'd0;
            mx_cmin <= 10'd1023;  mx_cmax <= 10'd0;
            mx_rmin <= 10'd1023;  mx_rmax <= 10'd0;
        end

        if(vstart)
        begin
            blk_idx <= 9'd0;
            blk_run <= 1'b1;
        end
        else if(blk_run)
        begin
            rmin_prv[blk_idx] <= rmin_cur[blk_idx];
            rmax_prv[blk_idx] <= rmax_cur[blk_idx];
            rmin_cur[blk_idx] <= 10'd1023;
            rmax_cur[blk_idx] <= 10'd0;
            if(blk_idx == 9'd299) blk_run <= 1'b0;
            blk_idx <= blk_idx + 9'd1;
        end
    end
end

//------------------------------------------------------------------
// 【屏上叠加】缺陷个数（三位十进制）+ 底部缺陷面积条
//   画面开关：0 = 增强后灰度图（正式演示）；1 = 二值缺陷分布图（调试）
//------------------------------------------------------------------
localparam SHOW_DEFECT_MAP = 1'b0;   // 诊断染色已用完关闭：正式画面只留红框

// 8x8 点阵字模（MSB 在左）
function [7:0] font_f;
    input [3:0] d;
    input [2:0] r;
    begin
        case(d)
        4'd0: case(r) 3'd0: font_f=8'h3C; 3'd1: font_f=8'h66; 3'd2: font_f=8'h66; 3'd3: font_f=8'h66;
                     3'd4: font_f=8'h66; 3'd5: font_f=8'h66; 3'd6: font_f=8'h66; default: font_f=8'h3C; endcase
        4'd1: case(r) 3'd0: font_f=8'h18; 3'd1: font_f=8'h38; 3'd2: font_f=8'h18; 3'd3: font_f=8'h18;
                     3'd4: font_f=8'h18; 3'd5: font_f=8'h18; 3'd6: font_f=8'h18; default: font_f=8'h3C; endcase
        4'd2: case(r) 3'd0: font_f=8'h3C; 3'd1: font_f=8'h66; 3'd2: font_f=8'h06; 3'd3: font_f=8'h0C;
                     3'd4: font_f=8'h18; 3'd5: font_f=8'h30; 3'd6: font_f=8'h60; default: font_f=8'h7E; endcase
        4'd3: case(r) 3'd0: font_f=8'h3C; 3'd1: font_f=8'h66; 3'd2: font_f=8'h06; 3'd3: font_f=8'h1C;
                     3'd4: font_f=8'h06; 3'd5: font_f=8'h06; 3'd6: font_f=8'h66; default: font_f=8'h3C; endcase
        4'd4: case(r) 3'd0: font_f=8'h0C; 3'd1: font_f=8'h1C; 3'd2: font_f=8'h2C; 3'd3: font_f=8'h4C;
                     3'd4: font_f=8'h7E; 3'd5: font_f=8'h0C; 3'd6: font_f=8'h0C; default: font_f=8'h0C; endcase
        4'd5: case(r) 3'd0: font_f=8'h7E; 3'd1: font_f=8'h60; 3'd2: font_f=8'h7C; 3'd3: font_f=8'h06;
                     3'd4: font_f=8'h06; 3'd5: font_f=8'h06; 3'd6: font_f=8'h66; default: font_f=8'h3C; endcase
        4'd6: case(r) 3'd0: font_f=8'h1C; 3'd1: font_f=8'h30; 3'd2: font_f=8'h60; 3'd3: font_f=8'h7C;
                     3'd4: font_f=8'h66; 3'd5: font_f=8'h66; 3'd6: font_f=8'h66; default: font_f=8'h3C; endcase
        4'd7: case(r) 3'd0: font_f=8'h7E; 3'd1: font_f=8'h06; 3'd2: font_f=8'h0C; 3'd3: font_f=8'h18;
                     3'd4: font_f=8'h18; 3'd5: font_f=8'h18; 3'd6: font_f=8'h18; default: font_f=8'h18; endcase
        4'd8: case(r) 3'd0: font_f=8'h3C; 3'd1: font_f=8'h66; 3'd2: font_f=8'h66; 3'd3: font_f=8'h3C;
                     3'd4: font_f=8'h66; 3'd5: font_f=8'h66; 3'd6: font_f=8'h66; default: font_f=8'h3C; endcase
        4'd9: case(r) 3'd0: font_f=8'h3C; 3'd1: font_f=8'h66; 3'd2: font_f=8'h66; 3'd3: font_f=8'h3E;
                     3'd4: font_f=8'h06; 3'd5: font_f=8'h06; 3'd6: font_f=8'h0C; default: font_f=8'h38; endcase
        default: font_f = 8'h00;
        endcase
    end
endfunction

// 缺陷段数 → 三位十进制
reg [3:0] d2, d1, d0;
reg [9:0] dtmp;
integer   k;
always @(*)
begin
    dtmp = seg_pk;   // 峰值保持后的计数（避免逐帧闪动）
    d2 = 4'd0;
    for(k = 0; k < 10; k = k + 1)
        if(dtmp >= 10'd100) begin dtmp = dtmp - 10'd100; d2 = d2 + 4'd1; end
    d1 = 4'd0;
    for(k = 0; k < 10; k = k + 1)
        if(dtmp >= 10'd10) begin dtmp = dtmp - 10'd10; d1 = d1 + 4'd1; end
    d0 = dtmp[3:0];
end

// 计数面板：左上角 128x48 黑底，三位数字 4 倍放大（每个 32x32，间距 8）
wire       panel_act = (dx >= 10'd8) && (dx < 10'd136) && (dy >= 10'd8) && (dy < 10'd56);
wire [9:0] pdx = dx - 10'd16;
wire [9:0] pdy = dy - 10'd16;
wire [1:0] dsel = (pdx >= 10'd80) ? 2'd2 : ((pdx >= 10'd40) ? 2'd1 : 2'd0);
wire [9:0] gx = pdx - ((dsel == 2'd2) ? 10'd80 : ((dsel == 2'd1) ? 10'd40 : 10'd0));
wire [3:0] dval = (dsel == 2'd2) ? d2 : ((dsel == 2'd1) ? d1 : d0);
wire [7:0] frow = font_f(dval, pdy[4:2]);
wire [7:0] panel_pix = (((gx < 10'd32) && (pdy < 10'd32)) ? frow[3'd7 - gx[4:2]] : 1'b0)
                       ? 8'hFF : 8'h00;

// 底部统计条：长度与缺陷像素数成正比（÷2，最多 1023）
wire [9:0]  bar_w  = (px_lat > 12'd2047) ? 10'd1023 : {1'b0, px_lat[10:1]};

// 二值缺陷分布图（调试模式）：白 = 阈值命中的候选像素，黑 = 正常
reg [4:0] cand_sr;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n) cand_sr <= 5'd0;
    else            cand_sr <= {cand_sr[3:0], cand_all};
wire [7:0]  dmap_pix = cand_sr[4] ? 8'hFF : 8'h00;

// ---- 最大缺陷块的空心红框（与 o_pix 同相位：用延迟 6 拍后的坐标比对）----
// 框外扩 4 源像素、边框厚 2 源像素（屏上约 4 px）；det_roi 已限制范围不会越界
wire [9:0] bc      = {1'b0, dxd6[9:1]};
wire [9:0] br      = {1'b0, dyd6[9:1]};
wire       box_on  = (mx_px_l >= 12'd12) && (mx_px_l <= 12'd3000);
// 只框“像缺陷”的块（12~3000 源像素）；整片暗区/大面积污渍不是缺陷，
// 不画框（否则会出现占半个屏的大红框）
wire       box_out = (bc >= (mx_cmin_l - 10'd4)) && (bc <= (mx_cmax_l + 10'd4)) &&
                     (br >= (mx_rmin_l - 10'd4)) && (br <= (mx_rmax_l + 10'd4));
wire       box_inn = (bc >= (mx_cmin_l - 10'd2)) && (bc <= (mx_cmax_l + 10'd2)) &&
                     (br >= (mx_rmin_l - 10'd2)) && (br <= (mx_rmax_l + 10'd2));
wire       box_hit = box_on && box_out && !box_inn;

// 叠加输出：R/G/B 分开。图像通道保持灰阶，缺陷框/计数面板/面积条用红色，
// 这样在白色或深色背景上都能一眼看到报警信息。
reg [7:0] lr_pix, lg_pix, lb_pix;
always @(*)
begin
    // 诊断模式：被判定为缺陷候选的像素染成品红叠在原图上（cand_sr[2] 与 o_pix
    // 同为地址相位后 6 拍，染色位置与屏幕像素严格对齐），其余像素照常显示
    if(SHOW_DEFECT_MAP && cand_sr[2])
    begin
        lr_pix = 8'hFF;  lg_pix = {1'b0, o_pix[7:1]};  lb_pix = 8'hFF;
    end
    else if(panel_act)                      // 左上角计数面板：黑底白字（保持原样）
    begin
        lr_pix = panel_pix;  lg_pix = panel_pix;  lb_pix = panel_pix;
    end
    else if(box_hit)                        // 最大缺陷块的空心红框（不填充，框内图像原样）
    begin
        lr_pix = 8'hFF;  lg_pix = 8'h00;  lb_pix = 8'h00;
    end
    else if((dx >= 10'd150) && (dx < 10'd246) && (dy >= 10'd8) && (dy < 10'd56))
    begin
        // 分拣状态指示：与舵机 PWM 占空比一一对应的屏上可视化
        //   无缺陷 -> 1.0ms(5%) -> 绿色短条(36 px)
        //   有缺陷 -> 2.0ms(10%) -> 红色长条(72 px)
        if((dy >= 10'd14) && (dy < 10'd50) &&
           (dx < (10'd150 + ((seg_pk >= SEG_ALARM) ? 10'd72 : 10'd36))))
        begin
            lr_pix = (seg_pk >= SEG_ALARM) ? 8'hFF : 8'h00;
            lg_pix = (seg_pk >= SEG_ALARM) ? 8'h00 : 8'hFF;
            lb_pix = 8'h00;
        end
        else
        begin
            lr_pix = 8'h00;  lg_pix = 8'h00;  lb_pix = 8'h00;
        end
    end
    else if((dy >= 10'd596) && (seg_pk >= SEG_ALARM))   // 底部缺陷面积条：仅在报警时显示
    begin
        lr_pix = (dx < bar_w) ? 8'hFF : 8'h00;
        lg_pix = 8'h00;  lb_pix = 8'h00;
    end
    else begin                              // 正常区域：灰阶图像
        lr_pix = o_pix;  lg_pix = o_pix;  lb_pix = o_pix;
    end
end

always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        hcnt <= 11'd0;
        vcnt <= 11'd0;
    end
    else
    begin
        if(hcnt == 11'd1343)
        begin
            hcnt <= 11'd0;
            vcnt <= (vcnt == 11'd634) ? 11'd0 : (vcnt + 11'd1);
        end
        else
            hcnt <= hcnt + 11'd1;
    end
end

wire       lde_r = de_out;     // DE 与增强流水线输出的像素同延迟
wire [7:0] lr    = lr_pix;
wire [7:0] lg    = lg_pix;
wire [7:0] lb    = lb_pix;

wire [6:0] lv_c0 = 7'b1100011;  // 时钟通道永远发厂商同步码，不能改！
wire [6:0] lv_d0 = {lg[0], lr[5:0]};
wire [6:0] lv_d1 = {lb[1:0], lg[5:1]};
wire [6:0] lv_d2 = {lde_r, 2'b00, lb[5:2]};
wire [6:0] lv_d3 = {1'b0, lb[7:6], lg[7:6], lr[7:6]};

// 与厂商 05_LVDS_LCD_Test_1024600 一致：输出前把每路 7bit 位序整体反转
//（LVDS 原语是 LSB 先移出，这里反转后才是 MSB 先行的标准 LVDS 顺序）
assign lvds_txc_o  = {lv_c0[0], lv_c0[1], lv_c0[2], lv_c0[3], lv_c0[4], lv_c0[5], lv_c0[6]};
assign lvds_txd0_o = {lv_d0[0], lv_d0[1], lv_d0[2], lv_d0[3], lv_d0[4], lv_d0[5], lv_d0[6]};
assign lvds_txd1_o = {lv_d1[0], lv_d1[1], lv_d1[2], lv_d1[3], lv_d1[4], lv_d1[5], lv_d1[6]};
assign lvds_txd2_o = {lv_d2[0], lv_d2[1], lv_d2[2], lv_d2[3], lv_d2[4], lv_d2[5], lv_d2[6]};
assign lvds_txd3_o = {lv_d3[0], lv_d3[1], lv_d3[2], lv_d3[3], lv_d3[4], lv_d3[5], lv_d3[6]};

//------------------------------------------------------------------
// LED 状态输出（低电平点亮）
//   led7     = 1Hz 心跳（证明 24MHz 时钟在跑）
//   led6     = 缺陷报警：本帧缺陷段数 >= SEG_ALARM 时 PWM 闪烁（约 1.4Hz）
//   led5..0  = 本帧缺陷段数（二进制，饱和 63）
//------------------------------------------------------------------
reg [27:0] alarm_cnt;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n) alarm_cnt <= 28'd0;
    else            alarm_cnt <= alarm_cnt + 1'b1;

wire       alarm_blink = alarm_cnt[22];
wire       alarm_on    = (seg_pk >= SEG_ALARM);
wire [5:0] led_cnt     = (seg_pk > 10'd63) ? 6'd63 : seg_pk[5:0];

//------------------------------------------------------------------
// 【计数峰值保持】逐帧统计值会小幅抖动，直接上屏会一直闪；这里改为
// 每约 0.7 秒取一次窗口内的最大值，数字稳定、不闪，且不会漏掉缺陷。
//------------------------------------------------------------------
reg [9:0] seg_pk;
reg       pk_clr;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
begin
    if(!rst_lvds_n)
    begin
        seg_pk <= 10'd0;
        pk_clr <= 1'b0;
    end
    else
    begin
        pk_clr <= alarm_cnt[26];
        if(alarm_cnt[26] && !pk_clr) seg_pk <= 10'd0;   // 窗口约 2.8 秒，重新取峰值
        else if(seg_lat > seg_pk)    seg_pk <= seg_lat; // 窗口内保持最大值
    end
end

always @(*)
    led_o = ~{heartbeat, (alarm_on & alarm_blink), led_cnt};

//------------------------------------------------------------------
// 舵机 PWM（复用未使用的 LCD 背光使能引脚 lcd_blen_o，底板 LCD 座可引出）
//   50Hz（20ms），无缺陷 1.0ms / 检出缺陷 2.0ms，可直接驱动 SG90 类舵机做分拣演示
//------------------------------------------------------------------
reg [19:0] srv_cnt;
always @(posedge clk_lvds_1x or negedge rst_lvds_n)
    if(!rst_lvds_n)   srv_cnt <= 20'd0;
    else              srv_cnt <= (srv_cnt >= 20'd1_023_999) ? 20'd0 : (srv_cnt + 1'b1);

wire [19:0] srv_pw = alarm_on ? 20'd102_400 : 20'd51_200;
assign lcd_blen_o  = (srv_cnt < srv_pw);

endmodule

//============================================================================
// line_buffer.v - 行缓存（延迟 1 行），来自 demo1
//   写入位置 ptr 循环递增，组合读 ram[ptr] 得到上一行同位置像素
//============================================================================
module line_buffer #(
    parameter IMG_WIDTH  = 64,
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_in,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output wire [DATA_WIDTH-1:0]  data_out,
    output wire                   valid_out
);
    reg [DATA_WIDTH-1:0] ram [0:IMG_WIDTH-1];
    reg [$clog2(IMG_WIDTH)-1:0] ptr;

    assign data_out  = ram[ptr];
    assign valid_out = valid_in;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            ptr <= 0;
        else if (valid_in)
        begin
            ram[ptr] <= data_in;
            ptr <= (ptr == IMG_WIDTH-1) ? 0 : ptr + 1;
        end
    end

    integer i;
    initial begin
        for (i = 0; i < IMG_WIDTH; i = i + 1)
            ram[i] = {DATA_WIDTH{1'b0}};
    end

endmodule

//============================================================================
// median_filter_3x3.v - 3x3 中值滤波（来自 demo1，适配 640 宽 / 6bit）
//   2 个 line_buffer 延迟 2 行 + 3 组 3 级移位寄存器形成 3x3 窗口
//   排序网络：行内排序 → 列操作 → 取中值
//   修改点：row/col 计数器加宽到 10bit（640 列 > 255）
//           valid_out 与 valid_in 相与（支持 valid 门控的停顿流）
//============================================================================
module median_filter_3x3 #(
    parameter IMG_WIDTH  = 64,
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_in,
    input  wire                   sof_in,
    input  wire                   eol_in,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output reg  [DATA_WIDTH-1:0]  data_out,
    output reg  [DATA_WIDTH-1:0]  center_out,    // 3x3 窗口中心像素（缺陷判据用）
    output reg  [12:0]            sum_out,      // 3x3 九像素之和（自适应阈值用）
    output reg                    valid_out,
    output reg                    sof_out,
    output reg                    eol_out
);
    wire [DATA_WIDTH-1:0] lb0_data, lb1_data;
    wire                  lb0_valid, lb1_valid;

    line_buffer #(.IMG_WIDTH(IMG_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_lb0 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in), .data_in(data_in),
        .data_out(lb0_data), .valid_out(lb0_valid)
    );

    line_buffer #(.IMG_WIDTH(IMG_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_lb1 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(lb0_valid), .data_in(lb0_data),
        .data_out(lb1_data), .valid_out(lb1_valid)
    );

    reg [DATA_WIDTH-1:0] sr0_0, sr0_1, sr0_2;
    reg [DATA_WIDTH-1:0] sr1_0, sr1_1, sr1_2;
    reg [DATA_WIDTH-1:0] sr2_0, sr2_1, sr2_2;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            {sr0_0, sr0_1, sr0_2} <= 0;
            {sr1_0, sr1_1, sr1_2} <= 0;
            {sr2_0, sr2_1, sr2_2} <= 0;
        end
        else if (valid_in)
        begin
            sr0_0 <= data_in;
            sr0_1 <= sr0_0;
            sr0_2 <= sr0_1;
            sr1_0 <= lb0_data;
            sr1_1 <= sr1_0;
            sr1_2 <= sr1_1;
            sr2_0 <= lb1_data;
            sr2_1 <= sr2_0;
            sr2_2 <= sr2_1;
        end
    end

    wire [DATA_WIDTH-1:0] p00 = sr2_2, p01 = sr2_1, p02 = sr2_0;
    wire [DATA_WIDTH-1:0] p10 = sr1_2, p11 = sr1_1, p12 = sr1_0;
    wire [DATA_WIDTH-1:0] p20 = sr0_2, p21 = sr0_1, p22 = sr0_0;

    function [DATA_WIDTH-1:0] min3;
        input [DATA_WIDTH-1:0] a, b, c;
        begin
            min3 = (a <= b) ? ((a <= c) ? a : c)
                            : ((b <= c) ? b : c);
        end
    endfunction

    function [DATA_WIDTH-1:0] max3;
        input [DATA_WIDTH-1:0] a, b, c;
        begin
            max3 = (a >= b) ? ((a >= c) ? a : c)
                            : ((b >= c) ? b : c);
        end
    endfunction

    function [DATA_WIDTH-1:0] mid3;
        input [DATA_WIDTH-1:0] a, b, c;
        begin
            if ((a >= b && a <= c) || (a >= c && a <= b))
                mid3 = a;
            else if ((b >= a && b <= c) || (b >= c && b <= a))
                mid3 = b;
            else
                mid3 = c;
        end
    endfunction

    wire [DATA_WIDTH-1:0] min_r0 = min3(p00, p01, p02);
    wire [DATA_WIDTH-1:0] mid_r0 = mid3(p00, p01, p02);
    wire [DATA_WIDTH-1:0] max_r0 = max3(p00, p01, p02);

    wire [DATA_WIDTH-1:0] min_r1 = min3(p10, p11, p12);
    wire [DATA_WIDTH-1:0] mid_r1 = mid3(p10, p11, p12);
    wire [DATA_WIDTH-1:0] max_r1 = max3(p10, p11, p12);

    wire [DATA_WIDTH-1:0] min_r2 = min3(p20, p21, p22);
    wire [DATA_WIDTH-1:0] mid_r2 = mid3(p20, p21, p22);
    wire [DATA_WIDTH-1:0] max_r2 = max3(p20, p21, p22);

    wire [DATA_WIDTH-1:0] max_of_min = max3(min_r0, min_r1, min_r2);
    wire [DATA_WIDTH-1:0] mid_of_mid = mid3(mid_r0, mid_r1, mid_r2);
    wire [DATA_WIDTH-1:0] min_of_max = min3(max_r0, max_r1, max_r2);

    wire [DATA_WIDTH-1:0] median = mid3(max_of_min, mid_of_mid, min_of_max);

    reg [9:0] row_cnt, col_cnt;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            row_cnt <= 10'd0;
            col_cnt <= 10'd0;
        end
        else if (valid_in)
        begin
            if (sof_in)
            begin
                row_cnt <= 10'd0;
                col_cnt <= 10'd0;
            end
            else if (eol_in)
            begin
                row_cnt <= row_cnt + 10'd1;
                col_cnt <= 10'd0;
            end
            else
                col_cnt <= col_cnt + 10'd1;
        end
    end

    reg        valid_in_d1;
    reg        sof_in_d1, eol_in_d1;
    reg [9:0]  row_cnt_d1, col_cnt_d1;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            valid_in_d1 <= 1'b0;
            sof_in_d1   <= 1'b0;
            eol_in_d1   <= 1'b0;
            row_cnt_d1  <= 10'd0;
            col_cnt_d1  <= 10'd0;
        end
        else
        begin
            valid_in_d1 <= valid_in;
            sof_in_d1   <= sof_in;
            eol_in_d1   <= eol_in;
            row_cnt_d1  <= row_cnt;
            col_cnt_d1  <= col_cnt;
        end
    end

    wire window_valid = (row_cnt_d1 >= 10'd2) && (col_cnt_d1 >= 10'd2);

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            data_out  <= 0;
            center_out <= 0;
            sum_out   <= 0;
            valid_out <= 1'b0;
            sof_out   <= 1'b0;
            eol_out   <= 1'b0;
        end
        else
        begin
            data_out  <= median;
            center_out <= p11;
            sum_out   <= {7'd0, p00} + {7'd0, p01} + {7'd0, p02}
                       + {7'd0, p10} + {7'd0, p11} + {7'd0, p12}
                       + {7'd0, p20} + {7'd0, p21} + {7'd0, p22};
            valid_out <= window_valid & valid_in_d1;   // 停顿流不会产生伪 valid
            sof_out   <= (row_cnt_d1 == 10'd2) && (col_cnt_d1 == 10'd2);
            eol_out   <= eol_in_d1 && (row_cnt_d1 >= 10'd2);
        end
    end

endmodule

//------------------------------------------------------------------
// 垂直 2 行平均：抹平 Bayer 行交替（A2020 相邻行是不同颜色通道，亮度系统性
// 不同，直通显示会逐行明暗交替）。一行行缓存存上一显示行同列像素，
// 输出 = (当前 + 上一行同列)/2。组合输出不占拍。
// 每行恰好 IMG_WIDTH 个 valid 脉冲（de 门控保证），ptr 自动回绕。
//------------------------------------------------------------------
module vavg2 #(
    parameter IMG_WIDTH  = 512,
    parameter DATA_WIDTH = 6
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  valid_in,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] ram [0:IMG_WIDTH-1];
    reg [9:0]            ptr;

    always @(posedge clk or negedge rst_n)
        if(!rst_n) ptr <= 10'd0;
        else if(valid_in)
        begin
            ram[ptr] <= data_in;
            ptr <= (ptr == IMG_WIDTH-1) ? 10'd0 : (ptr + 10'd1);
        end

    assign data_out = ({1'b0, data_in} + {1'b0, ram[ptr]}) >> 1;
endmodule
