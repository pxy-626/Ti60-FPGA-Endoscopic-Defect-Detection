// I2C 主机：支持「写寄存器」和「读寄存器」两种事务
// 写：START -> addr+W -> regH -> regL -> data -> STOP        （4 字节）
// 读：START -> addr+W -> regH -> regL -> RESTART -> addr+R -> rdata -> NACK -> STOP  （3 写 + 1 读）
// 1 个 SCL 周期 = 4 个 1/4 周期 tick
`timescale 1ns/1ns

module i2c_write_master #(
    parameter CLK_FREQ = 24_000_000,   // 系统时钟
    parameter I2C_FREQ = 10_000        // SCL 频率
)
(
    input           clk,
    input           rst_n,

    // I2C 三态接口（对应 peri 中的 inout）
    output          scl_o,
    output          scl_oe,
    input           scl_i,

    output          sda_o,
    output          sda_oe,
    input           sda_i,

    // 写通道
    input           start,          // 单周期脉冲，启动一次写操作
    input   [6:0]   dev_addr,       // 7bit 从机地址（A2020 = 7'h35）
    input   [15:0]  reg_addr,       // 16bit 寄存器地址
    input   [7:0]   wdata,          // 8bit 写数据
    output reg      busy,           // 正在传输
    output reg      done,           // 传输完成（脉冲，1 tick 宽）
    output reg      nack,           // 地址字节收到 NACK

    // 读通道：完整 I2C 读（含 RESTART + 寄存器地址写入）
    input           rd_start,       // 单周期脉冲，启动一次读操作
    output reg [7:0] rdata,         // 读回的数据
    output reg      rd_done,        // 读完成（脉冲，1 tick 宽）
    output reg      rd_nack,        // 读事务里收到 NACK
    output [2:0]    debug_state     // 诊断用：当前 master 状态
);

localparam integer QCNT = CLK_FREQ / (4 * I2C_FREQ);   // 1/4 SCL 周期的时钟个数

localparam [2:0] S_IDLE   = 3'd0,
                 S_START  = 3'd1,
                 S_WDATA  = 3'd2,
                 S_RDATA  = 3'd3,
                 S_STOP   = 3'd4,
                 S_RSTART = 3'd5;   // 读事务中的 RESTART（电气行为同 START）

//------------------ 1/4 SCL 周期 tick ------------------
reg [15:0] qcnt;
wire tick = (qcnt == QCNT - 1);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)              qcnt <= 16'd0;
    else if(tick)           qcnt <= 16'd0;
    else                    qcnt <= qcnt + 1'b1;
end

//------------------ 状态 / 相位 ------------------
reg [2:0] state;
reg [1:0] ph;          // 每个 bit 内的 4 个相位
reg [2:0] byte_i;      // 字节序号（最大需要 3）
reg [3:0] bit_i;       // 0..8 (8 = ACK)
reg       rd_mode;     // 0 = 写事务, 1 = 读事务
reg       scl_r;
reg       sda_r;
reg       sda_oe_r;
reg       start_lat;
reg       rd_lat;

assign scl_o  = scl_r;
assign scl_oe = 1'b1;      // SCL 推挽输出
assign sda_o  = sda_r;
assign sda_oe = sda_oe_r;  // SDA 开漏：oe=1 时驱动，oe=0 释放
assign debug_state = state;

//------------------ 当前要写的字节 ------------------
// 写事务(!rd_mode)：byte_i=0 addr+W, 1 regH, 2 regL, 3 wdata
// 读事务(rd_mode)：  byte_i=0 addr+R  → 直接去读数据（因为前一个写事务已经指了 reg 指针）
wire [7:0] cur_byte = (rd_mode) ? {dev_addr, 1'b1} :
                      (byte_i == 3'd0) ? {dev_addr, 1'b0} :
                      (byte_i == 3'd1) ? reg_addr[15:8]    :
                      (byte_i == 3'd2) ? reg_addr[7:0]     :
                                         wdata;
wire       cur_bit  = cur_byte[3'd7 - bit_i[2:0]];

//------------------ 请求脉冲锁存 ------------------
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                                                    start_lat <= 1'b0;
    else if(start)                                                start_lat <= 1'b1;
    else if(tick && (state == S_IDLE) && start_lat)               start_lat <= 1'b0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)                                                    rd_lat <= 1'b0;
    else if(rd_start)                                             rd_lat <= 1'b1;
    else if(tick && (state == S_IDLE) && rd_lat)                  rd_lat <= 1'b0;
end

//------------------ 主状态机 ------------------
reg rd_mode_latched;  // 读事务中 S_RSTART 后用于区分 addr+W/addr+R 阶段

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state    <= S_IDLE;
        ph       <= 2'd0;
        byte_i   <= 3'd0;
        bit_i    <= 4'd0;
        rd_mode  <= 1'b0;
        rd_mode_latched <= 1'b0;
        scl_r    <= 1'b1;
        sda_r    <= 1'b1;
        sda_oe_r <= 1'b0;
        busy     <= 1'b0;
        done     <= 1'b0;
        nack     <= 1'b0;
        rd_done  <= 1'b0;
        rd_nack  <= 1'b0;
        rdata    <= 8'h00;
    end
    else if(tick)
    begin
        done    <= 1'b0;
        rd_done <= 1'b0;
        case(state)
        //--------------------------------------------- IDLE
        S_IDLE:
            begin
                scl_r    <= 1'b1;
                sda_r    <= 1'b1;
                sda_oe_r <= 1'b0;
                busy     <= 1'b0;
                if(start_lat || rd_lat)
                begin
                    busy          <= 1'b1;
                    nack          <= 1'b0;
                    rd_nack       <= 1'b0;
                    rdata         <= 8'h00;
                    rd_mode       <= rd_lat;
                    rd_mode_latched <= rd_lat;
                    byte_i        <= 3'd0;
                    bit_i         <= 4'd0;
                    ph            <= 2'd0;
                    state         <= S_START;
                end
            end

        //--------------------------------------------- START / RESTART
        // RESTART 电气行为同 START：SCL 高时 SDA 下降沿
        S_START:
            begin
                case(ph)
                2'd0: begin scl_r <= 1'b1; sda_oe_r <= 1'b1; sda_r <= 1'b0; ph <= 2'd1; end
                2'd1: begin scl_r <= 1'b0; ph <= 2'd2; end
                2'd2: begin state <= S_WDATA; byte_i <= 3'd0; bit_i <= 4'd0; ph <= 2'd0; end
                default: ph <= 2'd0;
                endcase
            end

        S_RSTART:
            begin
                case(ph)
                2'd0: begin scl_r <= 1'b1; sda_oe_r <= 1'b1; sda_r <= 1'b0; ph <= 2'd1; end
                2'd1: begin scl_r <= 1'b0; ph <= 2'd2; end
                // RESTART 后 byte_i 跳到 3（addr+R），继续写
                2'd2: begin state <= S_WDATA; byte_i <= 3'd3; bit_i <= 4'd0; ph <= 2'd0; end
                default: ph <= 2'd0;
                endcase
            end

        //--------------------------------------------- 写字节 + ACK
        S_WDATA:
            begin
                if(bit_i < 4'd8)
                begin
                    case(ph)
                    2'd0: begin scl_r <= 1'b0; sda_oe_r <= 1'b1; sda_r <= cur_bit; ph <= 2'd1; end
                    2'd1: begin scl_r <= 1'b1; ph <= 2'd2; end
                    2'd2: begin ph <= 2'd3; end
                    2'd3: begin scl_r <= 1'b0; bit_i <= bit_i + 1'b1; ph <= 2'd0; end
                    endcase
                end
                else
                begin
                    case(ph)
                    2'd0: begin sda_oe_r <= 1'b0; sda_r <= 1'b1; ph <= 2'd1; end   // 释放 SDA
                    2'd1: begin scl_r <= 1'b1; ph <= 2'd2; end
                    2'd2: begin ph <= 2'd3; end
                    2'd3: begin
                              // SCL 高电平末尾采样 ACK
                              if(rd_mode)
                              begin
                                  // 读事务只有 1 个字节（addr+R）
                                  rd_nack <= sda_i;
                                  scl_r <= 1'b0;
                                  state <= S_RDATA; bit_i <= 4'd0; ph <= 2'd0;
                              end
                              else
                              begin
                                  // 写事务：addr+W, regH, regL, wdata
                                  if(byte_i == 3'd0) nack <= sda_i;
                                  scl_r <= 1'b0;
                                  if(byte_i == 3'd3)
                                      begin state <= S_STOP; bit_i <= 4'd0; ph <= 2'd0; end
                                  else
                                      begin byte_i <= byte_i + 3'd1; bit_i <= 4'd0; ph <= 2'd0; end
                              end
                          end
                    endcase
                end
            end

        //--------------------------------------------- 读数据 + 主机 NACK
        S_RDATA:
            begin
                if(bit_i < 4'd8)
                begin
                    case(ph)
                    2'd0: begin scl_r <= 1'b0; sda_oe_r <= 1'b0; sda_r <= 1'b1; ph <= 2'd1; end // 释放 SDA
                    2'd1: begin scl_r <= 1'b1; ph <= 2'd2; end
                    2'd2: begin rdata[3'd7 - bit_i[2:0]] <= sda_i; ph <= 2'd3; end
                    2'd3: begin scl_r <= 1'b0; bit_i <= bit_i + 1'b1; ph <= 2'd0; end
                    endcase
                end
                else
                begin
                    // 主机 NACK：告诉从机不再读了
                    case(ph)
                    2'd0: begin sda_oe_r <= 1'b0; sda_r <= 1'b1; ph <= 2'd1; end
                    2'd1: begin scl_r <= 1'b1; ph <= 2'd2; end
                    2'd2: begin ph <= 2'd3; end
                    2'd3: begin scl_r <= 1'b0; state <= S_STOP; ph <= 2'd0; end
                    endcase
                end
            end

        //--------------------------------------------- STOP
        S_STOP:
            begin
                case(ph)
                2'd0: begin scl_r <= 1'b0; sda_oe_r <= 1'b1; sda_r <= 1'b0; ph <= 2'd1; end
                2'd1: begin scl_r <= 1'b1; ph <= 2'd2; end
                2'd2: begin sda_oe_r <= 1'b0; sda_r <= 1'b1; ph <= 2'd3; end  // SCL 高时 SDA 上升 = STOP
                2'd3: begin
                          state    <= S_IDLE;
                          ph       <= 2'd0;
                          busy     <= 1'b0;
                          if(rd_mode_latched) begin rd_done <= 1'b1; rd_mode_latched <= 1'b0; rd_mode <= 1'b0; end
                          else                begin done    <= 1'b1; end
                      end
                default: ph <= 2'd0;
                endcase
            end

        default: state <= S_IDLE;
        endcase
    end
end

endmodule
