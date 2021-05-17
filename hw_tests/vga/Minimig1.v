module Minimig1
(
	input i_clock,	
	output [3:0] vga_r,
	output [3:0] vga_g,
	output [3:0] vga_b,
	output vga_hs,
	output vga_vs
);

wire vga_clk;
wire		clk;			//bus clock
wire		qclk;			//qudrature bus clock
wire		e;				//e clock enable

//instantiate clock generator
clock_generator C1
(	
	.mclk(i_clock),
	.clk28m(vga_clk),	//28.37516 MHz clock output
	.clk(clk),			//7.09379  MHz clock output
	.clk90(qclk),
	.e(e)
);

parameter h_pulse = 96;
parameter h_bp = 48;
parameter h_pixels = 640;
parameter h_fp = 16;
parameter h_pol = 1'b0;
parameter h_frame = 800;
parameter v_pulse = 2;
parameter v_bp = 33;
parameter v_pixels = 480;
parameter v_fp = 10;
parameter v_pol = 1'b1;
parameter v_frame = 525;

parameter square_size = 10;
parameter init_x = 320;
parameter init_y = 240;

reg [3:0] vga_r_r;
reg [3:0] vga_g_r;
reg [3:0] vga_b_r;
reg vga_hs_r;
reg vga_vs_r;

assign vga_r = vga_r_r;
assign vga_g = vga_g_r;
assign vga_b = vga_b_r;
assign vga_hs = vga_hs_r;
assign vga_vs = vga_vs_r;

reg [7:0] timer_t = 8'b0;
reg reset = 1;

reg [9:0] c_row;
reg [9:0] c_col;
reg [9:0] c_hor;
reg [9:0] c_ver;

reg disp_en;

reg [9:0] sq_pos_x;
reg [9:0] sq_pos_y;

wire [9:0] l_sq_pos_x;
wire [9:0] r_sq_pos_x;
wire [9:0] u_sq_pos_y;
wire [9:0] d_sq_pos_y;

assign l_sq_pos_x = sq_pos_x - square_size;
assign r_sq_pos_x = sq_pos_x + square_size;
assign u_sq_pos_y = sq_pos_y - square_size;
assign d_sq_pos_y = sq_pos_y + square_size;

reg [3:0] ps2_cntr;
reg [7:0] ps2_data_reg;
reg [7:0] ps2_data_reg_prev;
reg [7:0] ps2_data_reg_prev1;
reg [10:0] ps2_dat_r;

reg [1:0] ps2_clk_buf;
wire ps2_clk_pos;

reg u_arr = 0;
reg l_arr = 0;
reg d_arr = 0;
reg r_arr = 0;

assign ps2_clk_pos = (ps2_clk_buf == 2'b01);

always @ (posedge vga_clk) begin
	
end









endmodule

	
