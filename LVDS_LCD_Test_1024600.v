//-------------------------------
//modukle   :   LVDS_LCD_1024600_Test
//data      :   2022-04-19
//author    :   CrazyBingo

`timescale 1ns / 1ps
module LVDS_LCD_1024600_Test
(

//        input clk,
        input           txpll_locked,
//        input           tx_fastclk,     //168MHz = 50*7/2   
        input           tx_slowclk,     //48MHz
//        output          lcd_pwm,       
        
        output  [6:0]   lvds_tx_clk_TX_DATA,
        output  [6:0]   lvds_tx0_TX_DATA,
        output  [6:0]   lvds_tx1_TX_DATA,
        output  [6:0]   lvds_tx2_TX_DATA,
        output  [6:0]   lvds_tx3_TX_DATA
);

//assign  lcd_pwm = 1'b1;
wire    clk_pixel = tx_slowclk;    //48MHz
wire    sys_rst_n = txpll_locked;

localparam  PIXEL_CLOCK = 48_000000;
	

//-------------------------------------
//LCD driver timing
wire  			lcd_de;
wire  			lcd_hs;      
wire  			lcd_vs;
wire  	[7:0]   lcd_red;
wire  	[7:0]   lcd_green;
wire  	[7:0]   lcd_blue;
wire	[11:0]	lcd_xpos;		//lcd horizontal coordinate
wire	[11:0]	lcd_ypos;		//lcd vertical coordinate
wire	[23:0]	lcd_data;		//lcd data
lcd_driver u_lcd_driver
(
	//global clock
	.clk			(clk_pixel),		
	.rst_n			(sys_rst_n), 
	 
	 //lcd interface
	.lcd_dclk		(),//(lcd_dclk),
	.lcd_blank		(),//lcd_blank
	.lcd_sync		(),		    	
	.lcd_hs			(lcd_hs),		
	.lcd_vs			(lcd_vs),
	.lcd_en			(lcd_de),		
	.lcd_rgb		({lcd_red, lcd_green, lcd_blue}),

	
	//user interface
	.lcd_request	(),
	.lcd_data		(lcd_data),	
	.lcd_xpos		(lcd_xpos),	
	.lcd_ypos		(lcd_ypos)
);

//-------------------------------------
//lcd data simulation
lcd_display	
#(
	.DELAY_TOP		(PIXEL_CLOCK)
)
u_lcd_display
(
	//global clock
	.clk			(clk_pixel),		
	.rst_n			(sys_rst_n), 
	
	.lcd_xpos		(lcd_xpos),	
	.lcd_ypos		(lcd_ypos),
	.lcd_data		(lcd_data)
);


wire    [7:0]   c0 = 7'b1100011;
wire    [7:0]   d0 = {lcd_green[0],  lcd_red[5:0]};
wire    [7:0]   d1 = {lcd_blue[1:0], lcd_green[5:1]};
wire    [7:0]   d2 = {lcd_de, 2'b0,  lcd_blue[5:2]};   //vs hs is reserved
wire    [7:0]   d3 = {1'b0, lcd_blue[7:6], lcd_green[7:6], lcd_red[7:6]};

assign  lvds_tx_clk_TX_DATA = {c0[0], c0[1], c0[2], c0[3], c0[4], c0[5], c0[6]};
assign  lvds_tx0_TX_DATA    = {d0[0], d0[1], d0[2], d0[3], d0[4], d0[5], d0[6]};
assign  lvds_tx1_TX_DATA    = {d1[0], d1[1], d1[2], d1[3], d1[4], d1[5], d1[6]};
assign  lvds_tx2_TX_DATA    = {d2[0], d2[1], d2[2], d2[3], d2[4], d2[5], d2[6]};
assign  lvds_tx3_TX_DATA    = {d3[0], d3[1], d3[2], d3[3], d3[4], d3[5], d3[6]};

endmodule
