`timescale 1 ns/1 ps

module cordic_test;

localparam SZ = 16;

reg 	[SZ-1:0] Xin, Yin;
reg 	[31:0] angle;
wire 	[SZ:0] Xout, Yout;
reg		CLK_100MHz;

// Waveform generator

localparam FALSE = 1'b0;
localparam TRUE = 1'b1;

localparam VALUE = 32000/1.647;  // reduce by a factor of 1.647


reg signed [63:0] i;
reg  start;

initial
begin
	start = FALSE;
	$write("Starting simulation");
	CLK_100MHz = 1'b0;
	angle = 0;
	Xin = VALUE;
	Yin = 1'd0;
	
	#1000;
	@(posedge CLK_100MHz);
	start = TRUE;
	
	
	// sin/cos output
	for (i = 0; i < 360; i = i + 1)
	begin
	  @(posedge CLK_100MHz);
	  start = FALSE;
	  angle = ((1 << 32) * i/360);
	  $display ("angle = %d, %h", i, angle);
	  
	end
	
	#500
	$write("Simulation has finished");
	$stop;
end


// Instantiation of the cordic 
CORDIC sin_cos (CLK_100MHz, angle, Xin, Yin, Xout, Yout);

parameter CLK_SPEED = 10; 

initial
begin
  CLK_100MHz = 1'b0;
  $display ("CLK_100MHz started");
  #5;
  forever
  begin
	#(CLK_SPEED/2) CLK_100MHz = 1'b1;
	#(CLK_SPEED/2) CLK_100MHz = 1'b0;
  end
end

endmodule

