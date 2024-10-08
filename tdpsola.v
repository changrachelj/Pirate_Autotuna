//this can be logic in the top level later
module tdpsola(
    input wire clock,
    input wire reset,
    input wire signed [15:0] signal,
    output reg [15:0] out);
    
// PERIOD DETECTION
// Count the number of clock cycles between neg-to-pos zero crossings
    wire enable;
    wire [15:0] detected;
    period_detect d0(.clock(clock),.in(signal),.out(detected),.ena(enable));
 
    reg ena_current;
    reg ena_last; 
    always@ (posedge clock) begin
        ena_current <= enable;
        ena_last <= ena_current;
    end
        
// PERIOD SELECTION
// Sort detected period into bins, select closest allowable frequency

    wire [15:0] selected;
    wire [5:0] note_ind;
    note_select s0 (.clock(clock),.period(detected),.note_ind(note_ind),.note_per(selected));
    
// CORRECTION FACTOR
// LSB determines whether the signal should be expanded (1) or compressed (0).
// Bits [5:1] gives the magnitude of the correction factor.
    wire [5:0] correction =  selected > detected ? {selected - detected, 1'b1}:
                             selected < detected ? {detected - selected, 1'b0}:
                             6'b0;
                             
// STEP SIZE AND LENGTH OF WINDOW
// There are 7 discrete lengths that the window can have, controlled by the step size of the address counter.
    wire [2:0] step;
    wire [9:0] win_size; 
    wire bin_step[6:0];
    
    // Select a step size / window size based on the selected note. 
    assign bin_step[6] = note_ind <  6'h0c;
    assign bin_step[5] = note_ind >= 6'h0c && note_ind < 6'h14;
    assign bin_step[4] = note_ind >= 6'h14 && note_ind < 6'h19;
    assign bin_step[3] = note_ind >= 6'h19 && note_ind < 6'h1C;
    assign bin_step[2] = note_ind >= 6'h1C && note_ind < 6'h20;
    assign bin_step[1] = note_ind >= 6'h20 && note_ind < 6'h22;
    assign bin_step[0] = note_ind >= 6'h22;
    
    assign step = bin_step[6] ? 1 :
                  bin_step[5] ? 2 :
                  bin_step[4] ? 3 :
                  bin_step[3] ? 4 :
                  bin_step[2] ? 5 :
                  bin_step[1] ? 6 :
                                7 ;
    assign win_size = bin_step[6] ? 934 :  //# samples for windowing
                      bin_step[5] ? 467 :
                      bin_step[4] ? 311 :
                      bin_step[3] ? 233 :
                      bin_step[2] ? 186 :
                      bin_step[1] ? 155 :
                                    133 ;
    //for some reason this doesnt work unless step is stored in a reg    
    reg [2:0] step_size = 3; //default 440 Hz
    always@ (posedge clock)
        if (step >=1) step_size <= step;
        else step_size <= 1;   
        
// SLIDING WINDOW & WRITE TO RAM
// cascade address counters for writing to RAM.
// When the address counter reaches the hop size, start the next address counter
    reg res0 = 1'b1; reg ena0 = 1'b0; wire wrap0; wire [9:0] write_addr0;
    reg res1 = 1'b1; reg ena1 = 1'b0; wire wrap1; wire [9:0] write_addr1;
    reg res2 = 1'b1; reg ena2 = 1'b0; wire wrap2; wire [9:0] write_addr2; 
    reg res3 = 1'b1; reg ena3 = 1'b0; wire wrap3; wire [9:0] write_addr3;
 
    wire [8:0] hop = win_size >> 1; // number of samples to overlap with next window is half the window size
    
    // Cascade logic
    always @(posedge clock) begin
        //counter0
        if ((ena_current && ~ena_last) || (write_addr3 == hop)) begin  //on
            res0 <= 1'b0; ena0 <= 1'b1; end
        if (wrap0) begin                         //off
            res0 <= 1'b1; ena0 <= 1'b0; end
            
        //counter1
        if (write_addr0 == hop) begin             //on
            res1 <= 1'b0; ena1 <= 1'b1; end
        if (wrap1) begin                         //off
            res1 <= 1'b1; ena1 <= 1'b0; end
            
        //counter2
        if (write_addr1 == hop) begin             //on
            res2 <= 1'b0; ena2 <= 1'b1; end
        if (wrap2) begin                    //off
            res2 <= 1'b1; ena2 <= 1'b0; end
            
        //counter3
        if (write_addr2 == hop) begin             //on
            res3 <= 1'b0; ena3 <= 1'b1; end
        if (wrap3) begin                    //off
            res3 <= 1'b1; ena3 <= 1'b0; end
    end
    
    // Window signal to store in RAMs. Probably want to add some registers to store win_size at each wrap of the address counter just so it can be variable
    wire signed [23:0] win_out0;
    wire signed [23:0] win_out1;
    wire signed [23:0] win_out2;
    wire signed [23:0] win_out3;
    
    window win0 (.clock(clock),.reset(res0),.enable(ena0),.step(step_size),.win_size(win_size),.signal(signal),.windowed_signal(win_out0)); 

    window win1 (.clock(clock),.reset(res1),.enable(ena1),.step(step_size),.win_size(win_size),.signal(signal),.windowed_signal(win_out1));
        
    window win2 (.clock(clock),.reset(res2),.enable(ena2),.step(step_size),.win_size(win_size),.signal(signal),.windowed_signal(win_out2));

    window win3 (.clock(clock),.reset(res3),.enable(ena3),.step(step_size),.win_size(win_size),.signal(signal),.windowed_signal(win_out3));

    // Address counters
    counter #(.WIDTH(10))
    waddr0  (.clock(clock),.reset(res0),.enable(ena0),.limit(win_size-1),.step(1),.n(write_addr0),.wrap(wrap0));
        
    counter #(.WIDTH(10))
    waddr1  (.clock(clock),.reset(res1),.enable(ena1),.limit(win_size-1),.step(1),.n(write_addr1),.wrap(wrap1));

    counter #(.WIDTH(10))
    waddr2  (.clock(clock),.reset(res2),.enable(ena2),.limit(win_size-1),.step(1),.n(write_addr2),.wrap(wrap2));
        
    counter #(.WIDTH(10))
    waddr3  (.clock(clock),.reset(res3),.enable(ena3),.limit(win_size-1),.step(1),.n(write_addr3),.wrap(wrap3));
    
    // Write to RAMs //-----------------------------------------------------------------------------------
    reg [23:0] memory0 [0:933];
    reg [23:0] memory1 [0:933];
    reg [23:0] memory2 [0:933];
    reg [23:0] memory3 [0:933];
    reg ena_out_cnt = 1'b0;
    always @(posedge clock) begin
            if (ena0) begin
                      memory0[write_addr0] <= win_out0;
                      ena_out_cnt <= 1'b1; end //enable 1 delay after write
            if (ena1) memory1[write_addr1] <= win_out1;
            if (ena2) memory2[write_addr2] <= win_out2;
            if (ena3) memory3[write_addr3] <= win_out3;
    end 
    
// READ TO RAM    
    // Allow one delay between writing and reading. Reset output after about 1 second
    wire [15:0] count_out;                // 16-bit counter (1.07 s)
    wire wrap_out = (count_out == 16'b1); // start counting immediately after writing to first RAM.
    counter #(.WIDTH(16))
    res_out  (.clock(clock),.reset(1'b0),.enable(ena_out_cnt),.limit(16'hFFFF),.step(1),.n(count_out),.wrap());
        
    // Cascade address counters
    wire [8:0] ena_next = correction[0] ? hop + correction : hop - correction;  // Expand or compress by x number of samples
    
    reg r0 = 1'b1; reg e0 = 1'b0; wire wr0; wire [9:0] read_addr0; 
    reg r1 = 1'b1; reg e1 = 1'b0; wire wr1; wire [9:0] read_addr1; 
    reg r2 = 1'b1; reg e2 = 1'b0; wire wr2; wire [9:0] read_addr2;
    reg r3 = 1'b1; reg e3 = 1'b0; wire wr3; wire [9:0] read_addr3;
    
    // Cascade logic
    always @(posedge clock) begin
        //counter0. start at the end of writing to the first RAM
        if (wrap_out || (read_addr3 == ena_next)) begin  //on
            r0 <= 1'b0; e0 <= 1'b1; end
        if (wr0) begin                                //off
            r0 <= 1'b1; e0 <= 1'b0; end
            
        //counter1
        if (read_addr0 == ena_next) begin             //on
            r1 <= 1'b0; e1 <= 1'b1; end
        if (wr1) begin                                //off
            r1 <= 1'b1; e1 <= 1'b0; end
            
        //counter2
        if (read_addr1 == ena_next) begin             //on
            r2 <= 1'b0; e2 <= 1'b1; end
        if (wr2) begin                                //off
            r2 <= 1'b1; e2 <= 1'b0; end
            
        //counter3
        if (read_addr2 == ena_next) begin             //on
            r3 <= 1'b0; e3 <= 1'b1; end
        if (wr3) begin                                //off
            r3 <= 1'b1; e3 <= 1'b0; end
    end
    
    // Address counters
    counter #(.WIDTH(10))
    raddr0  (.clock(clock),.reset(r0),.enable(e0),.limit(win_size-1),.step(1),.n(read_addr0),.wrap(wr0));
        
    counter #(.WIDTH(10))
    raddr1  (.clock(clock),.reset(r1),.enable(e1),.limit(win_size-1),.step(1),.n(read_addr1),.wrap(wr1));

    counter #(.WIDTH(10))
    raddr2  (.clock(clock),.reset(r2),.enable(e2),.limit(win_size-1),.step(1),.n(read_addr2),.wrap(wr2));
        
    counter #(.WIDTH(10))
    raddr3  (.clock(clock),.reset(r3),.enable(e3),.limit(win_size-1),.step(1),.n(read_addr3),.wrap(wr3));

// ADDER
    reg signed [23:0]  out0 = 16'b0;
    reg signed [23:0]  out1 = 16'b0;
    reg signed [23:0]  out2 = 16'b0;
    reg signed [23:0]  out3 = 16'b0;
    wire signed [25:0] out_wire = out0 + out1 + out2 + out3;
    
    always @(posedge clock) begin
            if (e0) begin  out0 <= memory0[read_addr0];
            end else begin out0 <= 16'b0; end
            if (e1) begin  out1 <= memory1[read_addr1];
            end else begin out1 <= 16'b0; end
            if (e2) begin  out2 <= memory2[read_addr2];
            end else begin out2 <= 16'b0; end
            if (e3) begin  out3 <= memory3[read_addr3];
            end else begin out3 <= 16'b0; end           
            out <= out_wire >>> 8;
    end 
endmodule
