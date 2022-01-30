`timescale 1 ns/1 ps

// Modified from Alex Shovkoplyas, VE3NEA Cordic Algorithm
// Verilog Code optimized for SDR implementation

module cordic (clk, angle, Xin, Yin, Xout, Yout);

  parameter XY_SZ  = 16; // ADC bitwidth
   // Noise reduction bits removed for SDR  - pipeline depth is 16-stage 

  localparam STG = XY_SZ;
  input                   clk;
  input  signed  [31:0] angle; //  0 to 2*PI will be represented as a 32 bit number from 0 to {32{1'b1}}
  input  signed  [XY_SZ-1:0] Xin;
  input  signed  [XY_SZ-1:0] Yin;
  output signed  [XY_SZ:0] Xout;
  output signed  [XY_SZ:0] Yout;


  //------------------------------------------------------------------------------
  // arctan table lookup
  // 45.000 degrees -> atan(2^0)
  // 26.565 degrees -> atan(2^-1)
  // 14.036 degrees -> atan(2^-2)
  // 
  //------------------------------------------------------------------------------
  wire signed [31:0] atan_table [0:30];
  
  assign atan_table[00] = 32'b00100000000000000000000000000000; 
  assign atan_table[01] = 32'b00010010111001000000010100011101; 
  assign atan_table[02] = 32'b00001001111110110011100001011011; 
  assign atan_table[03] = 32'b00000101000100010001000111010100; 
  assign atan_table[04] = 32'b00000010100010110000110101000011;
  assign atan_table[05] = 32'b00000001010001011101011111100001;
  assign atan_table[06] = 32'b00000000101000101111011000011110;
  assign atan_table[07] = 32'b00000000010100010111110001010101;
  assign atan_table[08] = 32'b00000000001010001011111001010011;
  assign atan_table[09] = 32'b00000000000101000101111100101110;
  assign atan_table[10] = 32'b00000000000010100010111110011000;
  assign atan_table[11] = 32'b00000000000001010001011111001100;
  assign atan_table[12] = 32'b00000000000000101000101111100110;
  assign atan_table[13] = 32'b00000000000000010100010111110011;
  assign atan_table[14] = 32'b00000000000000001010001011111001;
  assign atan_table[15] = 32'b00000000000000000101000101111101;
  assign atan_table[16] = 32'b00000000000000000010100010111110;
  assign atan_table[17] = 32'b00000000000000000001010001011111;
  assign atan_table[18] = 32'b00000000000000000000101000101111;
  assign atan_table[19] = 32'b00000000000000000000010100011000;
  assign atan_table[20] = 32'b00000000000000000000001010001100;
  assign atan_table[21] = 32'b00000000000000000000000101000110;
  assign atan_table[22] = 32'b00000000000000000000000010100011;
  assign atan_table[23] = 32'b00000000000000000000000001010001;
  assign atan_table[24] = 32'b00000000000000000000000000101000;
  assign atan_table[25] = 32'b00000000000000000000000000010100;
  assign atan_table[26] = 32'b00000000000000000000000000001010;
  assign atan_table[27] = 32'b00000000000000000000000000000101;
  assign atan_table[28] = 32'b00000000000000000000000000000010;
  assign atan_table[29] = 32'b00000000000000000000000000000001;
  assign atan_table[30] = 32'b00000000000000000000000000000000;


  //------------------------------------------------------------------------------
  //  registers - for pipeline stages
  //  X and Y - 17-bit
  //  Z =	32-bit
  //  Set of registers for each stage - for calculation at each clock cycle
  //  			
  //------------------------------------------------------------------------------

  //stage outputs
  reg signed [XY_SZ:0] X [0:STG-1];
  reg signed [XY_SZ:0] Y [0:STG-1];
  reg signed    [31:0] Z [0:STG-1]; // 32bit


  //------------------------------------------------------------------------------
  //   First Stage of pipeline
  //   Checks if a pre-rotation of the inputs has to be done 
  //------------------------------------------------------------------------------
  wire	[1:0]	quadrant;      // upper two bits of the input angle - which determines the initial rotation angle
  assign	quardrant = angle[31:30];

  always @(posedge clk)
  begin
    case(quadrant)
	2'b00,
	2'b11:	// no pre-rotation needed for these quadrants
	begin
		X[0] <= Xin;
		Y[0] <= Yin;
		Z[0] <= angle;
	end

	2'b01:		// inputs in pi/2 to pi quadrant
	begin
		X[0] <= -Yin;   
		Y[0] <= Xin;
		Z[0] <= {2'b00,angle[29:0]}; // subtract pi/2 from phase_acc for this quadrant
	end

	2'b10:
	begin
		X[0] <= Yin;
		Y[0] <= -Xin;
		Z[0] <= {2'b11,angle[29:0]}; // add pi/2 to angle for this quadrant
	end
    endcase
  end

  //------------------------------------------------------------------------------
  //  stages 1 to STG-1
  //  pipeline replication logic
  //------------------------------------------------------------------------------
  genvar i;

  generate
    for (i=0; i < (STG-1); i=i+1)
    begin: XYZ
      wire 	Z_sign;
      wire signed [XY_SZ:0] X_shr, Y_shr; 

      assign X_shr = X[i] >>> i; // signed shift right
      assign Y_shr = Y[i] >>> i;

      //the sign of the current rotation angle
      assign Z_sign = Z[i][31]; // Z_sign = 1 if Z[i] < 0

      always @(posedge clk)
      begin
        // add/subtract shifted data
        X[i+1] <= Z_sign ? X[i] + Y_shr         : X[i] - Y_shr;
        Y[i+1] <= Z_sign ? Y[i] - X_shr         : Y[i] + X_shr;
        Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
      end
    end
  endgenerate


  //------------------------------------------------------------------------------
  // output
  //------------------------------------------------------------------------------
  assign Xout = X[STG-1];
  assign Yout = Y[STG-1];

endmodule
