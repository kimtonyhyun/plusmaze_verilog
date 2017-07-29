`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:22:18 07/31/2014 
// Design Name: 
// Module Name:    stepper_controller 
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
module stepper_controller(
    input clk, // Assume 1 MHz
    input start,
    input dir,
    output reg motor_step = 1'b0,
    output reg motor_dir = 1'b0
    );

localparam S_IDLE = 2'd0;
localparam S_STEP = 2'd1;
localparam S_DONE = 2'd2;
reg [1:0] state = S_IDLE;

parameter CLK_DIVIDE = 16'd2000;
reg [15:0] clk_counter = 16'd0;

parameter NUM_STEPS = 12'd400; // 8 * 50 (i.e. 90 deg in 1.8 deg steps with factor 8 microstepping)
reg [11:0] step_counter = 12'b0;

always @ (posedge clk)
begin
	case (state)
		S_IDLE:
		begin
			if (start)
			begin
				motor_dir <= dir;
				
				step_counter <= 12'd0;
				clk_counter <= 16'd0;
				
				state <= S_STEP;
			end
		end
		
		S_STEP:
		begin
			if (clk_counter == CLK_DIVIDE)
			begin
				clk_counter <= 16'd0;
				motor_step <= 1'b1;
				if (step_counter == NUM_STEPS-1)
					state <= S_DONE;
				else
					step_counter <= step_counter + 12'd1;
			end
			else
			begin
				motor_step <= 1'b0;
				clk_counter <= clk_counter + 16'd1;
			end
			
		end
		
		S_DONE:
		begin
			motor_step <= 1'b0;
			if (~start)
				state <= S_IDLE;
		end
	endcase
end

endmodule
