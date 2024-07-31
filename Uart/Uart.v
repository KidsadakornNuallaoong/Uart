//////////////////////////////////////////////////////////////////////////////////
// Company: Sripatum University
// Engineer(Student): Kidsadakorn Nuallaoong
// 
// Create Date: 07/31/2024 12:13:13 PM
// Design Name: Uart-8bits
// Module Name: Uart
// Project Name: Uart-8bits
// Target Devices: Universal Asynchronous Transmitter and Receiver
// Tool Versions: Vivado 2024.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// * transmitter module (TX)
module Uart_TX #(
        parameter BAUD_RATE = 9600,  // Baud rate in bits per second
        parameter DATA_BITS = 8,     // Number of data bits per frame
        parameter PARITY = 0         // 0 for no parity, 1 for odd parity, 2 for even parity
    )(
        input clk,
        input rst,
        input [DATA_BITS-1:0] data_in,
        input tx_start,
        output reg tx_out,
        output reg tx_busy
    );

    reg [3:0] tx_state;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;
    reg [15:0] baud_counter;

    parameter BIT_PERIOD = 100_000_000 / BAUD_RATE; // Assuming 100 MHz clock

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_out <= 1;
            tx_busy <= 0;
            tx_state <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            baud_counter <= 0;
        end else begin
            case (tx_state)
                0: begin // Idle state
                    if (tx_start && !tx_busy) begin
                        tx_out <= 0; // Start bit
                        tx_state <= 1;
                        bit_count <= 0;
                        shift_reg <= data_in;
                        tx_busy <= 1;
                        baud_counter <= 0;
                    end
                end
                1: begin // Transmitting data
//                    if (baud_counter < BIT_PERIOD - 1) begin
//                        baud_counter <= baud_counter + 1;
//                    end else 
                    begin
                        baud_counter <= 0;
                        if (bit_count < DATA_BITS) begin
                            tx_out <= shift_reg[0];
                            shift_reg <= shift_reg >> 1;
                            bit_count <= bit_count + 1;
                        end else begin
                            tx_out <= 1; // Stop bit
                            tx_state <= 0;
                            tx_busy <= 0;
                        end
                    end
                end
            endcase
        end
    end
endmodule

// * transmitter test bench
module Uart_TB;
    // Parameters
    parameter BAUD_RATE = 9600;
    parameter DATA_BITS = 8;
    parameter CLK_PERIOD = 10;  // 100 MHz clock

    // Inputs
    reg clk;
    reg rst;
    reg [DATA_BITS-1:0] data_in;
    reg tx_start;

    // Outputs
    wire tx_out;
    wire tx_busy;

    // Instantiate the Unit Under Test (UUT)
    Uart_TX #(
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .tx_start(tx_start),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
    );

    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD/2) clk = 1;
        #(CLK_PERIOD/2);
    end

    // Test sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        data_in = 0;
        tx_start = 0;

        // Wait for global reset
        #(CLK_PERIOD*5);
        rst = 0;

        // Apply test vector
        #(CLK_PERIOD*5);
        data_in = 8'hA5;  // Data to transmit
        tx_start = 1;
        #(CLK_PERIOD*2);
        tx_start = 0;
        wait (!tx_busy);  // Wait until transmission is complete

        // Apply another test vector
        #(CLK_PERIOD*5);
        data_in = 8'hcc;  // Another data to transmit
        tx_start = 1;
        #(CLK_PERIOD*2);
        tx_start = 0;
        wait (!tx_busy);  // Wait until transmission is complete
        
        // Apply another test vector
        #(CLK_PERIOD*5);
        data_in = 8'hAB;  // Another data to transmit
        tx_start = 1;
        #(CLK_PERIOD*2);
        tx_start = 0;
        wait (!tx_busy);  // Wait until transmission is complete
        
        // Apply another test vector
        #(CLK_PERIOD*5);
        data_in = 8'hBC;  // Another data to transmit
        tx_start = 1;
        #(CLK_PERIOD*2);
        tx_start = 0;
        wait (!tx_busy);  // Wait until transmission is complete
        // Finish the simulation
        $stop;
    end
endmodule

// * wait for receiver (RX)