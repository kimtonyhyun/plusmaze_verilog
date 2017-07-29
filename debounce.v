`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tony Hyun Kim
// 
// Create Date:    16:52:13 08/07/2013 
// Design Name: 
// Module Name:    debounce 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 1-bit debounce circuit
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debounce(
    input clk,
    input noisy,
    output reg clean = 1'b0
    );

parameter DELAY = 100_000; // 0.1 sec with 1 MHz clock

reg [22:0] q = 23'b0;
reg s = 1'b0;

always @ (posedge clk)
begin
	if (noisy != s)
	begin
		q <= 23'b0;
		s <= noisy;
	end
	else
	begin
		if (q == DELAY)
			clean <= s;
		else
			q <= q + 23'b1;
	end
end

endmodule
