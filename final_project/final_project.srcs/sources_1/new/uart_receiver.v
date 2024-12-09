`timescale 1ns / 1ps

module uart_receiver (
    input clk,               // System clock input
    input serial_in,         // Serial data input
    output reg data_ready,   // Indicates data reception is complete
    output reg [7:0] rx_data // Received 8-bit data output
);

    reg prev_serial;         // Tracks the previous state of the serial input
    reg is_receiving = 0;    // Flag to indicate reception in progress
    reg [7:0] tick_count;    // Counter for bit sampling

    always @(posedge clk) begin
        // Start reception on falling edge of serial input when idle
        if (~is_receiving && prev_serial && ~serial_in) begin
            is_receiving <= 1;
            data_ready <= 0;
            tick_count <= 0;
        end

        // Update the previous state of the serial input
        prev_serial <= serial_in;

        // Increment the tick count during reception, reset otherwise
        tick_count <= is_receiving ? tick_count + 1 : 0;

        // Sample data bits at specified tick intervals
        case (tick_count)
            8'd24:  rx_data[0] <= serial_in;
            8'd40:  rx_data[1] <= serial_in;
            8'd56:  rx_data[2] <= serial_in;
            8'd72:  rx_data[3] <= serial_in;
            8'd88:  rx_data[4] <= serial_in;
            8'd104: rx_data[5] <= serial_in;
            8'd120: rx_data[6] <= serial_in;
            8'd136: rx_data[7] <= serial_in;
            8'd152: begin
                data_ready <= 1;  // Mark data as ready
                is_receiving <= 0; // End reception
            end
        endcase
    end
endmodule
