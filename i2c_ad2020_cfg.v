// A2020 1280x960 / 1 Lane 寄存器配置表
// 数据来源：A2020_HDK I2C_AD2020_1280960_FPS60_1Lane_Config.v（厂商 demo 实际使用的表）
// LUT_DATA 格式：{16bit 寄存器地址, 8bit 数据}
// 注意：0x3000=0x00（开流）必须是最后一条，开流后不能再写模式寄存器
`timescale 1ns/1ns

module i2c_ad2020_cfg
(
    input       [5:0]   LUT_INDEX,
    output reg  [23:0]  LUT_DATA,
    output      [5:0]   LUT_SIZE
);

//------------------------------------------------------------------
// 曝光 / 增益（按 A2020 datasheet 8.2 / 8.6 节）
//   SHUTTER0 (0x3048~0x304A, 20bit): 曝光行数，必须偶数，范围 8 ~ FRAME_LENGTH-4
//     当前 FRAME_LENGTH = 2200，即最大 2196 行
//   GAIN_0 (0x3110): dB = 设定值 * 0.3
//     0x00~0x50(24dB) 为纯模拟增益；0x50~0xB4(54dB) 为模拟+数字
localparam [19:0] EXP_LINES  = 20'd500;   // 500 行 ≈ 7.6ms：此档画面最清晰（用户实测确认）
localparam [7:0]  GAIN_CODE  = 8'h00;     // 0dB（增益会放大噪点让画面发雾，保持 0）

assign LUT_SIZE = 6'd18;

always @(*)
begin
    case(LUT_INDEX)
    6'd0  : LUT_DATA = {16'h358B, 8'h0A};
    6'd1  : LUT_DATA = {16'h356F, 8'h03};
    6'd2  : LUT_DATA = {16'h36DA, 8'h02};
    6'd3  : LUT_DATA = {16'h3808, 8'h25};
    6'd4  : LUT_DATA = {16'h380A, 8'h02};
    6'd5  : LUT_DATA = {16'h38DC, 8'h00};
    6'd6  : LUT_DATA = {16'h38CA, 8'h01};
    6'd7  : LUT_DATA = {16'h36D8, 8'h06};
    6'd8  : LUT_DATA = {16'h36D9, 8'h06};
    6'd9  : LUT_DATA = {16'h3169, 8'h00};
    6'd10 : LUT_DATA = {16'h38A8, 8'h03};
    6'd11 : LUT_DATA = {16'h38A9, 8'h1B};
    6'd12 : LUT_DATA = {16'h38EA, 8'h01};
    6'd13 : LUT_DATA = {16'h3048, EXP_LINES[7:0]};        // SHUTTER0[7:0]
    6'd14 : LUT_DATA = {16'h3049, EXP_LINES[15:8]};       // SHUTTER0[15:8]
    6'd15 : LUT_DATA = {16'h304A, EXP_LINES[19:16]};      // SHUTTER0[19:16]
    6'd16 : LUT_DATA = {16'h3110, GAIN_CODE};             // GAIN_0
    6'd17 : LUT_DATA = {16'h3000, 8'h00};   // Streaming ON（最后一条）
    default: LUT_DATA = {16'h0000, 8'h00};
    endcase
end

endmodule
