module Minimig1
(
	input i_clock,
	input ps2_clk,
	input ps2_data,
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
	ps2_clk_buf[1:0] <= {ps2_clk_buf[0], ps2_clk};
	if (ps2_clk_pos == 1) begin
		ps2_cntr <= ps2_cntr + 1;
		if (ps2_cntr == 10) begin
			ps2_cntr <= 0;
			ps2_data_reg[7] <= ps2_dat_r[0];
			ps2_data_reg[6] <= ps2_dat_r[1];
			ps2_data_reg[5] <= ps2_dat_r[2];
			ps2_data_reg[4] <= ps2_dat_r[3];
			ps2_data_reg[3] <= ps2_dat_r[4];
			ps2_data_reg[2] <= ps2_dat_r[5];
			ps2_data_reg[1] <= ps2_dat_r[6];
			ps2_data_reg[0] <= ps2_dat_r[7];
			ps2_data_reg_prev <= ps2_data_reg;
			ps2_data_reg_prev1 <= ps2_data_reg_prev;
		end
		ps2_dat_r <= {ps2_dat_r[9:0], ps2_data};
	end
	
	if (ps2_data_reg_prev1 == 8'he0 && ps2_data_reg_prev == 8'hf0) begin
		if (ps2_data_reg == 8'h75) begin
			u_arr <= 0;
		end
		
		else if (ps2_data_reg == 8'h6b) begin
			l_arr <= 0;
		end
		
		else if (ps2_data_reg == 8'h72) begin
			d_arr <= 0;
		end
		
		else if (ps2_data_reg == 8'h74) begin
			r_arr <= 0;
		end
	end
	if (ps2_data_reg_prev == 8'he0) begin
		if (ps2_data_reg == 8'h75) begin
			u_arr <= 1;
		end
		
		else if (ps2_data_reg == 8'h6b) begin
			l_arr <= 1;
		end
		
		else if (ps2_data_reg == 8'h72) begin
			d_arr <= 1;
		end
		
		else if (ps2_data_reg == 8'h74) begin
			r_arr <= 1;
		end
	end	
end

always @ (posedge vga_clk) begin
	if (timer_t > 250) begin
		reset <= 0;
	end
	else begin
		reset <= 1;
		timer_t <= timer_t + 1;
		disp_en <= 0;
		sq_pos_x <= init_x;
		sq_pos_y <= init_y;
	end
	
	if (reset == 1) begin
		c_hor <= 0;
		c_ver <= 0;
		vga_hs_r <= 1;
		vga_vs_r <= 0;
		c_row <= 0;
		c_col <= 0;		
	end
	else begin
		if (c_hor < h_frame - 1) begin
			c_hor <= c_hor + 1;
		end
		else begin
			c_hor <= 0;
			if (c_ver < v_frame - 1) begin
				c_ver <= c_ver + 1;
			end
			else begin
				c_ver <= 0;
			end
		end
	end
	
	if (c_hor < h_pixels + h_fp + 1 || c_hor > h_pixels + h_fp + h_pulse) begin
		vga_hs_r <= ~h_pol;
	end
	else begin
		vga_hs_r <= h_pol;
	end
	
	if (c_ver < v_pixels + v_fp + 1 || c_ver > v_pixels + v_fp + v_pulse) begin
		vga_vs_r <= ~v_pol;
	end
	else begin
		vga_vs_r <= v_pol;
	end
	
	if (c_hor < h_pixels) begin
		c_col <= c_hor;
	end
	
	if (c_ver < v_pixels) begin
		c_row <= c_ver;
	end
	
	if (c_hor < h_pixels && c_ver < v_pixels) begin
		disp_en <= 1;
	end
	else begin
		disp_en <= 0;
	end	
	
	if (disp_en == 1 || reset == 0) begin
		if (c_row == 10|| c_col == 10 || c_row == v_pixels-11 || c_col == h_pixels-11) begin
			vga_r_r <= 7;
			vga_g_r <= 0;
			vga_b_r <= 0;
		end
		else if (c_col > l_sq_pos_x && c_col < r_sq_pos_x && c_row > u_sq_pos_y && c_row < d_sq_pos_y) begin
			vga_r_r <= 0;
			vga_g_r <= 0;
			vga_b_r <= 7;
		end
		else begin
			vga_r_r <= 0;
			vga_g_r <= 0;
			vga_b_r <= 0;
		end
	end
	else begin
		vga_r_r <= 0;
		vga_g_r <= 0;
		vga_b_r <= 0;
	end
	
	if (c_row == 1 && c_col == 1) begin
		if (u_arr) begin
			sq_pos_y <= sq_pos_y - 1;
		end
		
		if (d_arr) begin
			sq_pos_y <= sq_pos_y + 1;
		end
		
		if (l_arr) begin
			sq_pos_x <= sq_pos_x - 1;
		end
		
		if (r_arr) begin
			sq_pos_x <= sq_pos_x - 1;
		end
	end
end
	
	
	
	
	

endmodule

	
