module Minimig1
(
	input i_clock,
	//input i_enable,
	input i_switch_1,
	input i_switch_2,
	output o_led_drive
);

	parameter c_CNT_100HZ = 554211;
	parameter c_CNT_50HZ = 738948;
	parameter c_CNT_10HZ = 1108422;
	parameter c_CNT_1HZ = 2216844;

	reg[31:0] r_CNT_100HZ = 0;
	reg[31:0] r_CNT_50HZ = 0;
	reg[31:0] r_CNT_10HZ = 0;
	reg[31:0] r_CNT_1HZ = 0;

	reg r_TOGGLE_100HZ = 1'b0;
	reg r_TOGGLE_50HZ = 1'b0;
	reg r_TOGGLE_10HZ = 1'b0;
	reg r_TOGGLE_1HZ = 1'b0;

	reg r_LED_SELECT;

	always @ (posedge i_clock)
		begin
			if (r_CNT_100HZ == c_CNT_100HZ-1)
				begin
					r_TOGGLE_100HZ <= !r_TOGGLE_100HZ;
					r_CNT_100HZ <= 0;
				end
			else
				r_CNT_100HZ <= r_CNT_100HZ + 1;
		end

	always @ (posedge i_clock)
		begin
			if (r_CNT_50HZ == c_CNT_50HZ-1)
				begin
					r_TOGGLE_50HZ <= !r_TOGGLE_50HZ;
					r_CNT_50HZ <= 0;
				end
			else
				r_CNT_50HZ <= r_CNT_50HZ + 1;
		end
		
	always @ (posedge i_clock)
		begin
			if (r_CNT_10HZ == c_CNT_10HZ-1)
				begin
					r_TOGGLE_10HZ <= !r_TOGGLE_10HZ;
					r_CNT_10HZ <= 0;
				end
			else
				r_CNT_10HZ <= r_CNT_10HZ + 1;
		end
		
	always @ (posedge i_clock)
		begin
			if (r_CNT_1HZ == c_CNT_1HZ-1)
				begin
					r_TOGGLE_1HZ <= !r_TOGGLE_1HZ;
					r_CNT_1HZ <= 0;
				end
			else
				r_CNT_1HZ <= r_CNT_1HZ + 1;
		end
		
	always @ (*)
	begin
		case ({i_switch_1, i_switch_2})
			2'b11 : r_LED_SELECT <= r_TOGGLE_1HZ;
			2'b10 : r_LED_SELECT <= r_TOGGLE_10HZ;
			2'b01 : r_LED_SELECT <= r_TOGGLE_50HZ;
			2'b00 : r_LED_SELECT <= r_TOGGLE_100HZ;			
		endcase
	end
	
	assign o_led_drive = r_LED_SELECT /*& i_enable*/;
endmodule

	
