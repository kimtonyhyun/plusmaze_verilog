`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:05:51 06/04/2014 
// Design Name: 
// Module Name:    valve_driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module valve_driver(
    input clk,
	 input trigger,
    input [23:0] duration,
	 input [3:0] repeats, // Number of pulses per trigger. Needs to be >= 1
    output reg valve_out = 1'b0
    );

localparam S_IDLE   = 2'd0;
localparam S_PULSE  = 2'd1;
localparam S_REPEAT = 2'd2;
localparam S_DONE   = 2'd3;
reg [1:0] state = S_IDLE;

reg [23:0] duration_s;
reg [23:0] counter;

localparam REPEAT_DELAY = 24'd50_000;
reg [3:0] repeats_s;
reg [3:0] repeat_counter;

always @ (posedge clk)
begin
	case (state)
		S_IDLE:
		if (trigger)
		begin
			duration_s <= duration;
			counter <= 24'd0;
			
			repeats_s <= repeats - 4'd1;
			repeat_counter <= 4'd0;
			
			valve_out <= 1'b1;
			
			state <= S_PULSE;
		end
		
		S_PULSE:
		begin
			if (counter == duration_s)
			begin
				valve_out <= 1'b0;
				
				counter <= 24'd0;
				state <= S_REPEAT;
			end
			else
				counter <= counter + 24'd1;
		end
		
		S_REPEAT:
		begin
			if (counter == REPEAT_DELAY)
			begin
				if (repeat_counter == repeats_s)
					state <= S_DONE;
				else
				begin
					repeat_counter <= repeat_counter + 4'd1;
					
					counter <= 24'd0;
					valve_out <= 1'b1;
					state <= S_PULSE;
				end
			end
			else
				counter <= counter + 24'd1;
		end
		
		S_DONE:
		if (~trigger)
			state <= S_IDLE;
			
	endcase
end

endmodule
