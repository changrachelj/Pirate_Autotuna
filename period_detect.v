// Rachel Chang
// EECS 700
// Period detection for autotune plug in.
// Counts number of clock cycles between positive zero crossings.

module period_detect(
    input wire clock,
    input wire [15:0] in,
    output reg [15:0] out = 139,
    output reg ena = 1'b0);
        
    reg  current;           //current value of MSB
    reg  prev;              //previous value of MSB
    reg  [15:0] period;     
    reg  reset;
    reg [15:0] count = 0;
    
    always @(posedge clock) begin
        current <= in[15];
        prev <= current;
        
        if(~current & prev) begin //neg to pos zero crossing, reset counter and output count value.
            period <= count;
            reset <= 1'b1;
        end    
        
        // reset counter and set reset to 0
        if(reset == 1'b1) begin
            count <= 0;
            reset <= 1'b0;
            ena <= 1'b1;
        end else begin  
            count <= count + 1; //increment counter
        end
    end
    
    //assign output
    always@ (posedge clock)
        out <= period;

endmodule: period_detect