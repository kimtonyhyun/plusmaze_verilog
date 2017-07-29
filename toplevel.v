`default_nettype none
`timescale 1ns / 1ps

module toplevel(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	
	output wire        hi_muxsel,
   
	input wire clk1, // 100 MHz, check with FrontPanel PLL settings
	input wire clk2, //   4 MHz, check with FrontPanel PLL settings
	
	output wire miniscope_trig,
	input wire miniscope_sync,
	
	output wire clk_1mhz,
	output wire rc_out0,
	output wire rc_out1,
	output wire rc_out2,
	output wire rc_out3,
	
	output wire valve0,
	output wire valve1,
	output wire valve2,
	output wire valve3,
	
	input wire prox0,
	input wire prox1,
	input wire prox2,
	input wire prox3,
	
	input wire [3:0] lick,
	output wire lick_out,
	output wire lick_out2,
	
	output wire step,
	output wire dir,
	output wire step2,
	output wire dir2,
	
	output wire [7:0] led,
	input  wire [3:0] button
	);

// Opal Kelly Module Interface Connections
wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;

// Endpoint connections:
wire [15:0] ep00wire; // Gate PWM command
wire [15:0] ep01wire;
wire [15:0] ep02wire;
wire [15:0] ep03wire;

wire [15:0] ep04wire; // Valve pulse length
wire [15:0] ep05wire;
wire [15:0] ep06wire;
wire [15:0] ep07wire;
wire [15:0] ep08wire; // Valve pulse repeat count

wire [15:0] ep20wire; // General status (e.g. last activated prox, lick state)
wire [15:0] ep21wire; // Frame counter - Low
wire [15:0] ep22wire; // Frame counter - Hight

wire [15:0] ep40trigger; // Synchronized to system clock (i.e. "clk_1mhz")
wire [15:0] ep41trigger; // Synchronized to pipe clock ("ti_clk")

assign hi_muxsel    = 1'b0;

// General inputs
wire [3:0] btn_d;
debounce db0(clk_1mhz, ~button[0], btn_d[0]);
debounce db1(clk_1mhz, ~button[1], btn_d[1]);
debounce db2(clk_1mhz, ~button[2], btn_d[2]);
debounce db3(clk_1mhz, ~button[3], btn_d[3]);

// Generate a 1 MHz clock based on PLL clock
reg [23:0] clk_counter = 24'b0;
always @ (posedge clk2) // clk2: Assumed to be 4 MHz
	clk_counter <= clk_counter + 24'b1;	
assign clk_1mhz = clk_counter[1];

// Interface to miniscope
wire miniscope_recording_start = ep40trigger[7];
wire miniscope_recording_stop  = ep40trigger[8];
wire miniscope_counter_reset = ep40trigger[9];
wire trig;
wire [31:0] frame_count;
miniscope_interface mi0(.clk(clk_1mhz),
								.start(miniscope_recording_start),
								.stop(miniscope_recording_stop),
								.reset(miniscope_counter_reset),
							   .miniscope_trig(trig),
								.miniscope_sync(miniscope_sync),
								.frame_count(frame_count));
assign miniscope_trig = ~trig; // Active low

assign ep21wire = frame_count[15:0];
assign ep22wire = frame_count[31:16];

// Generate RC waveforms for gates
reg [11:0] prox0_cmd = 12'd0;
rc_driver d0(clk_1mhz, ep00wire[11:0], rc_out0);
rc_driver d1(clk_1mhz, ep01wire[11:0], rc_out1);
rc_driver d2(clk_1mhz, ep02wire[11:0], rc_out2);
rc_driver d3(clk_1mhz, ep03wire[11:0], rc_out3);

// Valve controls
wire valve_all = ep40trigger[0];
wire valve0_trig = ep40trigger[1];
wire valve1_trig = ep40trigger[2];
wire valve2_trig = ep40trigger[3];
wire valve3_trig = ep40trigger[4];

valve_driver vd0(clk_1mhz, valve_all | valve0_trig, {8'b0, ep04wire}, ep08wire[3:0], valve0);
valve_driver vd1(clk_1mhz, valve_all | valve1_trig, {8'b0, ep05wire}, ep08wire[7:4], valve1);
valve_driver vd2(clk_1mhz, valve_all | valve2_trig, {8'b0, ep06wire}, ep08wire[11:8], valve2);
valve_driver vd3(clk_1mhz, valve_all | valve3_trig, {8'b0, ep07wire}, ep08wire[15:12], valve3);

// Stepper motors for platform rotation
wire center_ccw = ep40trigger[5];
wire center_cw  = ep40trigger[6];

// Central platform rotation
stepper_controller sc1(.clk(clk_1mhz), .start(center_ccw | center_cw), .dir(center_ccw),
							  .motor_step(step), .motor_dir(dir));
// Overall maze rotation (unsupported)
stepper_controller2 sc2(.clk(clk_1mhz), .start(valve_all | valve0_trig), .dir(valve0_trig),
							  .motor_step(), .motor_dir());
assign dir2 = 1'b0;
assign step2 = 1'b0;

// Proximity sensor
wire [3:0] prox_d;
debounce # (.DELAY(50_000)) db4(clk_1mhz, prox0, prox_d[0]);
debounce # (.DELAY(50_000)) db5(clk_1mhz, prox1, prox_d[1]);
debounce # (.DELAY(50_000)) db6(clk_1mhz, prox2, prox_d[2]);
debounce # (.DELAY(50_000)) db7(clk_1mhz, prox3, prox_d[3]);

// Indicate the most recently activated proximity sensor (should wrap into module)
reg [1:0] last_prox = 2'd0;
always @ (posedge clk_1mhz)
if (prox_d[0])
	last_prox <= 2'd0;
else
begin 
	if (prox_d[1])
		last_prox <= 2'd1;
	else
	begin
		if (prox_d[2])
			last_prox <= 2'd2;
		else
		begin
			if (prox_d[3])
				last_prox <= 2'd3;
		end
	end
end

// Lickometer processing
wire [3:0] lick_d;
debounce # (.DELAY(10_000)) db8(clk_1mhz, ~lick[0], lick_d[0]);
debounce # (.DELAY(10_000)) db9(clk_1mhz, ~lick[1], lick_d[1]);
debounce # (.DELAY(10_000)) db10(clk_1mhz, ~lick[2], lick_d[2]);
debounce # (.DELAY(10_000)) db11(clk_1mhz, ~lick[3], lick_d[3]);

// We can superimpose into a single-bit signal, by noting the fact that
//	the mouse can only lick one port at a time. The overhead behavior cam
//	then becomes necessary for disambiguation.
wire lick_combined = lick_d[0] | lick_d[1] | lick_d[2] | lick_d[3];

// By applying a minimum pulse width, we make sure that we don't "lose"
// any lick events (i.e. the licks whose pulses lie completely between the
//	frame clock edges of the Miniscope
wire lick_minwidth;
apply_min_width # (.DELAY(60_000)) lick_width(.clk(clk_1mhz), .in(lick_combined), .out(lick_minwidth));

wire lick_slow; // For PC sampling of lickometer
apply_min_width # (.DELAY(150_000)) lick_width2(.clk(clk_1mhz), .in(lick_combined), .out(lick_slow));

// Interface for piping out lickometer data to PC
wire pipe_reset = ep41trigger[0]; // Synchronized to ti_clk
wire pipe_read;
wire [15:0] pipe_data;

lick_logger logger(.clk(clk_1mhz),
						 .trig(trig), // From "miniscope_interface"
						 .sync(miniscope_sync),
						 .lick(lick_minwidth),
						 .pipe_clk(ti_clk), .pipe_reset(pipe_reset),
						 .pipe_read(pipe_read), .pipe_data(pipe_data));

assign lick_out  = lick_combined;
assign lick_out2 = lick_minwidth; 

assign ep20wire = {13'd0, lick_slow, last_prox};

// Indicators
//assign led = {lick, ~prox_d};
assign led = 8'hFF; // Disable LEDs

// Instantiate the okHost and connect endpoints.
wire [17*4-1:0]  ok2x;
okHost okHI(
	.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .ti_clk(ti_clk),
	.ok1(ok1), .ok2(ok2));

okWireOR # (.N(4)) wireOR (.ok2(ok2), .ok2s(ok2x));

okWireIn     ep00 (.ok1(ok1),                          .ep_addr(8'h00), .ep_dataout(ep00wire));
okWireIn     ep01 (.ok1(ok1),                          .ep_addr(8'h01), .ep_dataout(ep01wire));
okWireIn     ep02 (.ok1(ok1),                          .ep_addr(8'h02), .ep_dataout(ep02wire));
okWireIn     ep03 (.ok1(ok1),                          .ep_addr(8'h03), .ep_dataout(ep03wire));

okWireIn     ep04 (.ok1(ok1),                          .ep_addr(8'h04), .ep_dataout(ep04wire));
okWireIn     ep05 (.ok1(ok1),                          .ep_addr(8'h05), .ep_dataout(ep05wire));
okWireIn     ep06 (.ok1(ok1),                          .ep_addr(8'h06), .ep_dataout(ep06wire));
okWireIn     ep07 (.ok1(ok1),                          .ep_addr(8'h07), .ep_dataout(ep07wire));
okWireIn     ep08 (.ok1(ok1),                          .ep_addr(8'h08), .ep_dataout(ep08wire));

okWireOut    ep20 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h20), .ep_datain(ep20wire));
okWireOut    ep21 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]), .ep_addr(8'h21), .ep_datain(ep21wire));
okWireOut    ep22 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'h22), .ep_datain(ep22wire));

okTriggerIn  ep40 (.ok1(ok1), .ep_addr(8'h40), .ep_clk(clk_1mhz), .ep_trigger(ep40trigger));
okTriggerIn	 ep41 (.ok1(ok1), .ep_addr(8'h41), .ep_clk(ti_clk),   .ep_trigger(ep41trigger));

okPipeOut 	 epA0 (.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'hA0), .ep_datain(pipe_data), .ep_read(pipe_read));

endmodule