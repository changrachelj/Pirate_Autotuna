// This module windows a portion of the signal and stores in a RAM
// Window function uses a Hann window.
// The ROM contains enough samples to accomodate the largest period twice.
// To vary the length of this window, appropriate step size is chosen

module window ( 
        input wire clock,
        input wire reset,
        input wire enable,
        input wire [2:0] step,
        input wire [9:0] win_size,
        input wire signed [15:0] signal,
        output reg [23:0] windowed_signal = 0);
 
// Window RAM address counter
    wire [9:0] address;
    counter #(
        .WIDTH(10))
        addr1  (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .limit(933),
        .step({7'b0,step}),
        .n(address),
        .wrap(wrap));     
      
// Read from ROM
    wire signed [7:0] rom_out;
    hann_rom hann0 (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .addr(address),
        .do(rom_out));
        
// Get window value and multiply       

    always@(posedge clock)
        windowed_signal <= rom_out*signal;
    
endmodule: window