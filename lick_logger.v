`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tony Hyun Kim
// 
// Create Date:    09:20:31 12/09/2014 
// Design Name: 
// Module Name:    lick_logger 
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
module lick_logger(
    input clk,
    input trig,
    input sync,
    input lick,
	 input pipe_clk,
	 input pipe_reset,
    input pipe_read,
    output [15:0] pipe_data
    );

reg wea = 1'b0;
reg [18:0] write_addr = 19'd0;
reg [14:0] read_addr = 15'd0;

// Buffer stores up to 500_000, 1-bit samples!
//	Almost 7 hours at 20 Hz sampling rate
lick_bram buffer(
	.clka(clk),
	.wea(wea),
	.addra(write_addr),
	.dina(lick),
	.clkb(pipe_clk),
	.addrb(read_addr),
	.doutb(pipe_data));

// Write interface (record lick data to buffer)
parameter S_IDLE 			  = 2'd0;
parameter S_WAIT_FOR_SYNC = 2'd1;
parameter S_RECORD 		  = 2'd2;
reg [1:0] state = S_IDLE;

reg [1:0] sync_s = 2'b0;

always @ (posedge clk)
begin
	sync_s <= {sync, sync_s[1]};
	
	case (state)
		S_IDLE:
		begin
			wea <= 1'b0;
			if (trig)
			begin
				write_addr <= 19'd0;
				state <= S_WAIT_FOR_SYNC;
			end
		end
		
		S_WAIT_FOR_SYNC:
		begin
			wea <= 1'b0;
			if (~trig) // Miniscope disabled
				state <= S_IDLE;
			else
				if (sync_s[1] & (~sync_s[0])) // Positive edge on sync
				begin
					wea <= 1'b1;
					state <= S_RECORD;
				end
		end
		
		S_RECORD:
		begin
			wea <= 1'b0;
			write_addr <= write_addr + 1;
			state <= S_WAIT_FOR_SYNC;
		end
	endcase
end

// Read interface (pipe lick data out to PC)
always @ (posedge pipe_clk)
if (pipe_reset)
	read_addr <= 15'd0;
else
begin
	if (pipe_read)
		read_addr <= read_addr + 1;
end

endmodule
