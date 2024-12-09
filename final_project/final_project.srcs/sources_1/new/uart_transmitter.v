`timescale 1ns / 1ps

module uart_transmitter (
    input clk,                  // Clock signal
    input [7:0] tx_data,        // 8-bit data to transmit
    input enable,               // Enable signal
    output reg transmission_done, // Indicates data transmission completion
    output reg serial_out       // Serial data output
);

    reg prev_enable;            // Tracks the previous state of the enable signal
    reg is_transmitting = 0;    // Flag to indicate ongoing transmission
    reg [7:0] bit_counter;      // Counter for bit timing
    reg [7:0] data_buffer;      // Buffer to hold data during transmission

    always @(posedge clk) begin
        // Start transmission on rising edge of enable
        if (~is_transmitting && ~prev_enable && enable) begin
            data_buffer <= tx_data; // Load data into the buffer
            is_transmitting <= 1;
            transmission_done <= 0;
            bit_counter <= 0;
        end

        // Update the previous state of the enable signal
        prev_enable <= enable;

        // Manage counter and idle state
        if (is_transmitting)
            bit_counter <= bit_counter + 1;
        else begin
            bit_counter <= 0;
            serial_out <= 1; // Idle state of UART is high
        end

        // Transmit data bits at specific timing intervals
        case (bit_counter)
            8'd8:   serial_out <= 0;             // Start bit
            8'd24:  serial_out <= data_buffer[0];
            8'd40:  serial_out <= data_buffer[1];
            8'd56:  serial_out <= data_buffer[2];
            8'd72:  serial_out <= data_buffer[3];
            8'd88:  serial_out <= data_buffer[4];
            8'd104: serial_out <= data_buffer[5];
            8'd120: serial_out <= data_buffer[6];
            8'd136: serial_out <= data_buffer[7];
            8'd152: begin
                transmission_done <= 1; // Indicate transmission complete
                is_transmitting <= 0;   // End transmission
            end
        endcase
    end
endmodule
