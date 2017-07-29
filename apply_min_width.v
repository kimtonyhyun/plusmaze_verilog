`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tony Hyun Kim
// 
// Create Date:    11:14:06 12/08/2014 
// Design Name: 
// Module Name:    apply_min_width 
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
module apply_min_width(
    input clk,
    input in,
    output reg out = 1'b0
    );

parameter DELAY = 60_000; // 50 ms with 1 MHz clock

reg [22:0] q = 23'd0;

localparam S_LOW  = 2'd0;
localparam S_HOLD = 2'd1;
localparam S_HIGH = 2'd2;

reg [1:0] state = S_LOW;

always @ (posedge clk)
begin
	case (state)
		S_LOW:
		begin
			out <= 1'b0;			
			if (in)
			begin
				q <= 23'd0;
				state <= S_HOLD;
			end
		end
		
		S_HOLD:
		begin
			out <= 1'b1;
			if (q == DELAY)
				state <= S_HIGH;
			else
				q <= q + 1;
		end
		
		S_HIGH:
		begin
			out <= 1'b1;
			if (~in)
				state <= S_LOW;
		end
	endcase
end

endmodule
