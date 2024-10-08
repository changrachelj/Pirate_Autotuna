`timescale 1ns/1ps
module det_sel_tb;
  reg  clock = 1'b1;
  reg  reset = 1'b0;
  reg  enable = 1'b1;
  wire signed [15:0] wave;
  wire [15:0] detect;
  wire [15:0] select;
  wire [15:0] windowed;
    
  dds dds0 (
    .clock(clock),
    .reset(1'b0),
    .enable(1'b1),
    .step(12'h12C),
    .limit(8'hA), // 447 Hz signal (should autotune to 440 Hz)
    .wave(wave));

  period_detect per0(
    .clock(clock),
    .in(wave),
    .out(detect));
    
  note_select sel0(
    .period(detect),
    .note_ind(),
    .note_per(select));

  tdpsola td(
    .clock(clock),
    .reset(reset),
    .signal(wave),
    .out(windowed));   
    
  always begin
    #8192;
    clock <= 1'b0;
    #8192;
    clock <= 1'b1;
  end
  
//initial begin
//    #8360000
//    reset <= 1'b1;
//    #16384
//    reset <= 1'b0;
//end

endmodule: det_sel_tb
