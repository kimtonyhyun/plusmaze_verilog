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
module stepper_controller2(
    input clk, // Assume 1 MHz
    input start,
    input dir,
    output reg motor_step = 1'b0,
    output reg motor_dir = 1'b0
    );

localparam S_IDLE = 4'd0;
localparam S_SLOW1 = 4'd1;
localparam S_FAST1 = 4'd2;

localparam S_DECEL = 4'd13;
localparam S_STEP = 4'd14;
localparam S_DONE = 4'd15;

reg [3:0] state = S_IDLE;
reg [3:0] state_return = S_IDLE;


parameter N_DECEL = 8'd16;
parameter DECEL_DELAY = 16'd500;
parameter DECEL_STEPS = 16'd12;
reg [7:0] decel_counter = 8'd0;

reg [15:0] clk_delay = 16'd0;
reg [15:0] clk_counter = 16'd0; // Max: 65535

reg [15:0] num_steps = 16'd0;
reg [15:0] step_counter = 16'b0; // Max: 65535

always @ (posedge clk)
begin
	case (state)
		S_IDLE:
		begin
			if (start)
			begin
				motor_dir <= dir;
				state <= S_SLOW1;
			end
		end
		
		S_SLOW1:
		begin
			clk_delay <= 16'd10000;
			num_steps <= 16'd50;
			state_return <= S_FAST1;
			
			state <= S_STEP;
		end
		
		S_FAST1:
		begin
			/*
			clk_delay <= 16'd4500;
			num_steps <= 16'd775;
			
			decel_counter <= 8'd0;
			state_return <= S_DECEL;
			*/
			
			clk_delay <= 16'd4500;
			num_steps <= 16'd900;
			state_return <= S_DONE;
			
			state <= S_STEP;
		end
		
		S_DECEL:
		begin
			if (decel_counter == N_DECEL)
				state <= S_DONE;
			else
			begin
				clk_delay <= clk_delay + DECEL_DELAY;
				num_steps <= DECEL_STEPS;
				
				decel_counter <= decel_counter + 8'd1;
				state_return <= S_DECEL;
				
				state <= S_STEP;
			end
		end
		
		S_STEP:
		begin
			if (clk_counter == clk_delay)
			begin
				clk_counter <= 16'd0;
				motor_step <= 1'b1;
				if (step_counter == num_steps-1)
				begin
					step_counter <= 16'd0;
					state <= state_return;
				end
				else
					step_counter <= step_counter + 16'd1;
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
