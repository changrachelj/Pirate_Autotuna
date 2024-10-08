// Rachel Chang
// EECS 700
// Note selection for autotune plug in.
// Takes input period and finds the period bin in which it belongs,
// Outputs note index and period of correct note.
//
// Minimum frequency considered is c3 (130.81 Hz = 0.0076 s). Using a 16-bit period,
// The maximum allowable clock frequency is 8.5 MHz.
// Decimate input signal by 16 to get 7.8125 MHz.
// Considering c3-b5, there exist 36 bins into which the note may fall, requiring 6 bits for the index.

module note_select(
    input  wire clock,
    input  wire [15:0] period,
    output wire [5:0] note_ind,
    output reg [15:0] note_per = 139);
    
 //instantiate roms containing discrete period values and their mid points
    reg [11:0] note_ram [0:35];
    initial $readmemh("periods.mem", note_ram);

    reg [11:0] mid_ram [0:34];
    initial $readmemh("mid_periods.mem", mid_ram);         
    
// Comparator stage; find which bin the period falls into
wire bin[35:0];
assign bin[0]  =  period >= mid_ram[0];                    //C3
assign bin[1]  = (period < mid_ram[0]) && (period >= mid_ram[1]); //C#3
assign bin[2]  = (period < mid_ram[1]) && (period >= mid_ram[2]); //D3
assign bin[3]  = (period < mid_ram[2]) && (period >= mid_ram[3]); //D#3
assign bin[4]  = (period < mid_ram[3]) && (period >= mid_ram[4]); //E3
assign bin[5]  = (period < mid_ram[4]) && (period >= mid_ram[5]); //F3
assign bin[6]  = (period < mid_ram[5]) && (period >= mid_ram[6]); //F#3
assign bin[7]  = (period < mid_ram[6]) && (period >= mid_ram[7]); //G3
assign bin[8]  = (period < mid_ram[7]) && (period >= mid_ram[8]); //G#3
assign bin[9]  = (period < mid_ram[8]) && (period >= mid_ram[9]); //A3
assign bin[10] = (period < mid_ram[9]) && (period >= mid_ram[10]); //A#3
assign bin[11] = (period < mid_ram[10]) && (period >= mid_ram[11]); //B3
assign bin[12] = (period < mid_ram[11]) && (period >= mid_ram[12]); //C4
assign bin[13] = (period < mid_ram[12]) && (period >= mid_ram[13]); //C#4
assign bin[14] = (period < mid_ram[13]) && (period >= mid_ram[14]); //D4
assign bin[15] = (period < mid_ram[14]) && (period >= mid_ram[15]); //D#4
assign bin[16] = (period < mid_ram[15]) && (period >= mid_ram[16]); //E4
assign bin[17] = (period < mid_ram[16]) && (period >= mid_ram[17]); //F4
assign bin[18] = (period < mid_ram[17]) && (period >= mid_ram[18]); //F#4
assign bin[19] = (period < mid_ram[18]) && (period >= mid_ram[19]); //G4
assign bin[20] = (period < mid_ram[19]) && (period >= mid_ram[20]); //G#4
assign bin[21] = (period < mid_ram[20]) && (period >= mid_ram[21]); //A4
assign bin[22] = (period < mid_ram[21]) && (period >= mid_ram[22]); //A#4
assign bin[23] = (period < mid_ram[22]) && (period >= mid_ram[23]); //B4
assign bin[24] = (period < mid_ram[23]) && (period >= mid_ram[24]); //C5
assign bin[25] = (period < mid_ram[24]) && (period >= mid_ram[25]); //C#5
assign bin[26] = (period < mid_ram[25]) && (period >= mid_ram[26]); //D5
assign bin[27] = (period < mid_ram[26]) && (period >= mid_ram[27]); //D#5
assign bin[28] = (period < mid_ram[27]) && (period >= mid_ram[28]); //E5
assign bin[29] = (period < mid_ram[28]) && (period >= mid_ram[29]); //F5
assign bin[30] = (period < mid_ram[29]) && (period >= mid_ram[30]); //F#5
assign bin[31] = (period < mid_ram[30]) && (period >= mid_ram[31]); //G5
assign bin[32] = (period < mid_ram[31]) && (period >= mid_ram[32]); //G#5
assign bin[33] = (period < mid_ram[32]) && (period >= mid_ram[33]); //A5
assign bin[34] = (period < mid_ram[33]) && (period >= mid_ram[34]); //A#5
assign bin[35] =  period < mid_ram[34] ;                            //B5


// Multiplexer
// note index
assign note_ind = bin[0]  ? 6'b000000 : //C3
                  bin[1]  ? 6'b000001 : //C#3
                  bin[2]  ? 6'b000010 : //D3
                  bin[3]  ? 6'b000011 : //D#3
                  bin[4]  ? 6'b000100 : //E3
                  bin[5]  ? 6'b000101 : //F3
                  bin[6]  ? 6'b000110 : //F#3
                  bin[7]  ? 6'b000111 : //G3
                  bin[8]  ? 6'b001000 : //G#4
                  bin[9]  ? 6'b001001 : //A3
                  bin[10] ? 6'b001010 : //A#3
                  bin[11] ? 6'b001011 : //B3
                  bin[12] ? 6'b001100 : //C4
                  bin[13] ? 6'b001101 : //C#4
                  bin[14] ? 6'b001110 : //D4
                  bin[15] ? 6'b001111 : //D#4
                  bin[16] ? 6'b010000 : //E4
                  bin[17] ? 6'b010001 : //F4
                  bin[18] ? 6'b010010 : //F#4
                  bin[19] ? 6'b010011 : //G4
                  bin[20] ? 6'b010100 : //G#4
                  bin[21] ? 6'b010101 : //A4
                  bin[22] ? 6'b010110 : //A#4
                  bin[23] ? 6'b010111 : //B4
                  bin[24] ? 6'b011000 : //C5
                  bin[25] ? 6'b011001 : //C#5
                  bin[26] ? 6'b011010 : //D5
                  bin[27] ? 6'b011011 : //D#5
                  bin[28] ? 6'b011100 : //E5
                  bin[29] ? 6'b011101 : //F5
                  bin[30] ? 6'b011110 : //F#5
                  bin[31] ? 6'b011111 : //G5
                  bin[32] ? 6'b100000 : //G#5
                  bin[33] ? 6'b100001 : //A5
                  bin[34] ? 6'b100010 : //A#5
                            6'b100011 ; //B5

//correct period                             
always@ (posedge clock)
    note_per <= note_ram[note_ind];

               
endmodule: note_select

