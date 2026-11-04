# Efinity 时序约束 - P1 摄像头 I2C 配置
create_clock -name clk -period 41.667 [get_ports {clk}]

set_clock_uncertainty -rise_from clk -rise_to clk 0.200
set_clock_uncertainty -fall_from clk -fall_to clk 0.200

set_false_path -from [get_ports {rst_n}]

set_output_delay 2.000 -clock [get_clocks {clk}] [get_ports {led[*]}]
