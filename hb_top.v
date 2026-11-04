// Super minimal heartbeat test - no I2C, no config, just prove clock + LED work
// 8 LEDs should all blink together at ~1Hz, low = lit
`timescale 1ns/1ns

module hb_top
(
    input           clk,
    input           rst_n,
    output  [7:0]   led
);

reg [23:0] cnt;
reg        blink;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        cnt    <= 24'd0;
        blink  <= 1'b0;
    end else if(cnt == 24'd11_999_999) begin
        cnt    <= 24'd0;
        blink  <= ~blink;
    end else
        cnt <= cnt + 1'b1;
end

// LED 低电平点亮: blink=0 -> lit, blink=1 -> off
assign led = {8{~blink}};

endmodule
