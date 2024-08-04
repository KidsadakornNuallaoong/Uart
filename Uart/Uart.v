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
                    if (baud_counter < BIT_PERIOD - 1) begin
                        baud_counter <= baud_counter + 1;
                    end else 
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
module tb_Uart_TX;
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
module Uart_RX #(
        parameter BAUD_RATE = 9600,  // Baud rate in bits per second
        parameter DATA_BITS = 8      // Number of data bits per frame
    )(
        input clk,
        input rst,
        input rx_in,
        output reg [DATA_BITS-1:0] data_out,
        output reg data_ready
    );

    reg [3:0] rx_state;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;
    reg [15:0] baud_counter;
    reg [15:0] half_bit_counter;

    parameter BIT_PERIOD = 100_000_000 / BAUD_RATE; // Assuming 100 MHz clock

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            baud_counter <= 0;
            half_bit_counter <= 0;
            data_out <= 0;
            data_ready <= 0;
        end else begin
            case (rx_state)
                0: begin // Idle state
                    data_ready <= 0;
                    if (rx_in == 0) begin // Start bit detected
                        rx_state <= 1;
                        baud_counter <= 0;
                        half_bit_counter <= BIT_PERIOD / 2;
                    end
                end
                1: begin // Start bit verification
                    if (baud_counter < half_bit_counter - 1) begin
                        baud_counter <= baud_counter + 1;
                    end else begin
                        baud_counter <= 0;
                        rx_state <= 2;
                    end
                end
                2: begin // Receiving data bits
                    if (baud_counter < BIT_PERIOD - 1) begin
                        baud_counter <= baud_counter + 1;
                    end else begin
                        baud_counter <= 0;
                        shift_reg <= {rx_in, shift_reg[DATA_BITS-1:1]};
                        bit_count <= bit_count + 1;
                        if (bit_count == DATA_BITS - 1) begin
                            rx_state <= 3;
                        end
                    end
                end
                3: begin // Stop bit
                    if (baud_counter < BIT_PERIOD - 1) begin
                        baud_counter <= baud_counter + 1;
                    end else begin
                        baud_counter <= 0;
                        if (rx_in == 1) begin // Stop bit verification
                            data_out <= shift_reg;
                            data_ready <= 1;
                        end
                        rx_state <= 0;
                    end
                end
            endcase
        end
    end
endmodule

module tb_Uart_RX;

    // Parameters
    parameter BAUD_RATE = 9600;
    parameter DATA_BITS = 8;
    parameter CLK_PERIOD = 10;  // 100 MHz clock

    // Inputs
    reg clk;
    reg rst;
    reg rx_in;

    // Outputs
    wire [DATA_BITS-1:0] data_out;
    wire data_ready;

    // Instantiate the Unit Under Test (UUT)
    Uart_RX #(
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .rx_in(rx_in),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD/2) clk = 1;
        #(CLK_PERIOD/2);
    end

    // Task to send a byte over UART
    task send_byte;
        input [7:0] byte;
        integer i;
        begin
            // Start bit
            rx_in = 0;
            #(CLK_PERIOD * 1000000 / BAUD_RATE);
            // Data bits
            for (i = 0; i < DATA_BITS; i = i + 1) begin
                rx_in = byte[i];
                #(CLK_PERIOD * 1000000 / BAUD_RATE);
            end
            // Stop bit
            rx_in = 1;
            #(CLK_PERIOD * 1000000 / BAUD_RATE);
        end
    endtask

    // Test sequence
    initial begin
        // Initialize Inputs
        rst = 1;
        rx_in = 1; // Idle line is high

        // Wait for global reset
        #(CLK_PERIOD*5);
        rst = 0;

        // Wait for some time
        #(CLK_PERIOD*10);

        // Send a byte
        send_byte(8'b10101010);

        // Wait for data to be received
        wait (data_ready);

        // Check received data
        if (data_out == 8'b10101010)
            $display("Test Passed");
        else
            $display("Test Failed: Received %b", data_out);

        // Finish the simulation
        $stop;
    end

endmodule

// * Integrate module
module tb_Uart_TX_RX;

    // Parameters
    parameter BAUD_RATE = 9600;
    parameter DATA_BITS = 8;
    parameter CLK_PERIOD = 10;  // 100 MHz clock

    // Inputs for TX
    reg clk;
    reg rst;
    reg [DATA_BITS-1:0] tx_data_in;
    reg tx_start;

    // Outputs from TX
    wire tx_out;
    wire tx_busy;

    // Outputs from RX
    wire [DATA_BITS-1:0] rx_data_out;
    wire rx_data_ready;

    // Instantiate the Uart_TX module
    Uart_TX #(
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS)
    ) uart_tx (
        .clk(clk),
        .rst(rst),
        .data_in(tx_data_in),
        .tx_start(tx_start),
        .tx_out(tx_out),
        .tx_busy(tx_busy)
    );

    // Instantiate the Uart_RX module
    Uart_RX #(
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS)
    ) uart_rx (
        .clk(clk),
        .rst(rst),
        .rx_in(tx_out),
        .data_out(rx_data_out),
        .data_ready(rx_data_ready)
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
        tx_data_in = 0;
        tx_start = 0;

        // Wait for global reset
        #(CLK_PERIOD*5);
        rst = 0;

        // Wait for some time
        #(CLK_PERIOD*10);

        // Send a byte
        tx_data_in = 8'b10101010;
        tx_start = 1;
        #(CLK_PERIOD*2);
        tx_start = 0;

        // Wait for data to be received
        wait (rx_data_ready);

        // Check received data
        if (rx_data_out == 8'b10101010)
            $display("Test Passed: Received %b", rx_data_out);
        else
            $display("Test Failed: Received %b", rx_data_out);
        
        #960000;
//        // Send another byte
//        #(CLK_PERIOD*100);
//        tx_data_in = 8'b11001100;
//        tx_start = 1;
//        #(CLK_PERIOD*2);
//        tx_start = 0;

//        // Wait for data to be received
//        wait (rx_data_ready);

//        // Check received data
//        if (rx_data_out == 8'b11001100)
//            $display("Test Passed: Received %b", rx_data_out);
//        else
//            $display("Test Failed: Received %b", rx_data_out);

        // Initialize Inputs 
        rst = 1;
        tx_data_in = 0;
        tx_start = 0;

        // Wait for global reset
        #(CLK_PERIOD*5);
        rst = 0;

        // Wait for some time
        #(CLK_PERIOD*10);

        // Send a byte
        tx_data_in = 8'hfa;
        tx_start = 1;
        #(CLK_PERIOD*2);
        tx_start = 0;

        // Wait for data to be received
        wait (rx_data_ready);

        // Check received data
        if (rx_data_out == 8'hfa)
            $display("Test Passed: Received %b", rx_data_out);
        else
            $display("Test Failed: Received %b", rx_data_out);
        
        #960000;
        // Finish the simulation
        $stop;
    end

endmodule