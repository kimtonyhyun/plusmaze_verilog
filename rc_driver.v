`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tony Hyun Kim 
// 
// Create Date:    08:45:37 05/13/2014 
// Design Name: 
// Module Name:    rc_driver 
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
module rc_driver(
    input clk, // Assumed to be 1 MHz clock
    input [11:0] pulse_duration,
    output wire rc_out
    );

parameter PULSE_STEP_SIZE = 12'd90;
reg [11:0] pulse_curr;
reg [11:0] pulse_prev;

parameter NUM_IDLE_PULSES = 4'd4;
reg [3:0] idle_pulse_counter = 4'd0;
reg rc_pwr = 1'b0;

localparam S_IDLE = 2'd0;
localparam S_HIGH = 2'd1;
localparam S_LOW  = 2'd2;
reg [1:0] state = S_IDLE;
reg out = 1'b0;

parameter RC_PERIOD = 16'd20_000;
reg [15:0] counter = 16'b0;
reg [15:0] hi_duration;
reg [15:0] lo_duration;

assign rc_out = rc_pwr & out;

always @ (posedge clk)
begin
	case (state)
		S_IDLE:
		begin
			pulse_prev <= pulse_curr;
			if (pulse_duration > pulse_curr)
				if (pulse_duration - pulse_curr > PULSE_STEP_SIZE)
					pulse_curr <= pulse_curr + PULSE_STEP_SIZE;
				else
					pulse_curr <= pulse_duration;
			else
				if (pulse_curr - pulse_duration > PULSE_STEP_SIZE)
					pulse_curr <= pulse_curr - PULSE_STEP_SIZE;
				else
					pulse_curr <= pulse_duration;
		
			if (pulse_prev == pulse_curr)
				if (idle_pulse_counter == 4'd0)
					rc_pwr <= 1'b0;
				else
				begin
					idle_pulse_counter <= idle_pulse_counter - 4'd1;
					rc_pwr <= 1'b1;
				end
			else
			begin
				rc_pwr <= 1'b1;
				idle_pulse_counter <= NUM_IDLE_PULSES;
			end
			
			counter <= 16'd0;
			hi_duration <= pulse_curr;
			lo_duration <= RC_PERIOD - pulse_curr;
			
			out <= 1'b1;
			state <= S_HIGH;
		end
		
		S_HIGH:
		begin
			if (counter < hi_duration)
				counter <= counter + 16'd1;
			else
			begin
				counter <= 16'd0;
				out <= 1'b0;
				state <= S_LOW;
			end
		end
		
		S_LOW:
		begin
			if (counter < lo_duration)
				counter <= counter + 16'd1;
			else
			begin
				counter <= 16'd0;
				state <= S_IDLE;
			end
		end
	endcase
end

endmodule
