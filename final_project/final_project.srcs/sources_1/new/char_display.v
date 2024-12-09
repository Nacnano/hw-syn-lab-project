`timescale 1ns / 1ps

module char_display(
    input wire clk_in,             // Clock input
    input wire rst,                // Reset signal
    input wire write_en,           // Enable writing (UART control)
    input wire [7:0] uart_data,    // UART input data
    input wire display_active,     // Display enable signal
    input wire [9:0] pixel_x, pixel_y, // Pixel coordinates
    output reg [11:0] rgb_out      // RGB output
);

    // Constants and memory setup
    parameter BUFFER_SIZE = 128;       // Memory buffer size
    reg [6:0] buffer[BUFFER_SIZE-1:0]; // Memory buffer for ASCII
    reg [6:0] write_pointer;           // Write pointer
    reg [23:0] frame_counter;          // Frame counter for background fade
    integer idx;

    // ASCII ROM connections
    wire [10:0] rom_address;           // ROM address
    wire [6:0] character_code;         // ASCII character code
    wire [3:0] row_idx;                // Row index for character
    wire [2:0] column_idx;             // Column index for ROM
    wire [7:0] rom_row_data;           // Row data from ROM
    wire char_bit, render_pixel;       // ROM bit and rendering condition

    // Initialization
    initial begin
        write_pointer = 7'b1;
        buffer[0] = 7'h3E; // Default character ('>')
        frame_counter = 0; // Initialize frame counter
    end

    // ASCII ROM instantiation
    ascii_rom rom_inst(
        .clk(clk_in), 
        .addr(rom_address), 
        .data(rom_row_data)
    );

    // Generate ROM address and rendering conditions
    assign rom_address = {character_code, row_idx};
    assign char_bit = rom_row_data[~column_idx];
    assign row_idx = pixel_y[3:0];
    assign column_idx = pixel_x[2:0];
    assign character_code = buffer[
        ((pixel_x[7:3] + 8) & 5'b11111) + 
        32 * ((pixel_y[5:4] + 3) & 2'b11)
    ];
    assign render_pixel = (
        (pixel_x >= 192 && pixel_x < 448) && 
        (pixel_y >= 208 && pixel_y < 272)
    ) ? char_bit : 1'b0;

    // Handle UART write logic
    always @(posedge write_en) begin
        buffer[0] = 7'h3E;
        if (uart_data[6:0] == 13) begin // Handle newline
            write_pointer = (1 + (write_pointer >> 5)) << 5;
            if (write_pointer == 0)
                write_pointer = write_pointer + 1;
        end else begin
            buffer[write_pointer] = uart_data[6:0];
            write_pointer = 1 + (write_pointer % (BUFFER_SIZE - 1));
        end
    end

    // Frame counter for time-based background color
    always @(posedge clk_in) begin
        frame_counter <= frame_counter + 1;
    end

    // Rainbow color function (based on index)
    function [11:0] rainbow_color(input [3:0] index);
        begin
            case (index)
                4'd0: rainbow_color = 12'hF00; // Red
                4'd1: rainbow_color = 12'hF80; // Orange
                4'd2: rainbow_color = 12'hFF0; // Yellow
                4'd3: rainbow_color = 12'h8F0; // Light Green
                4'd4: rainbow_color = 12'h0F0; // Green
                4'd5: rainbow_color = 12'h0F8; // Cyan-Green
                4'd6: rainbow_color = 12'h0FF; // Cyan
                4'd7: rainbow_color = 12'h08F; // Light Blue
                4'd8: rainbow_color = 12'h00F; // Blue
                4'd9: rainbow_color = 12'h80F; // Purple
                4'd10: rainbow_color = 12'hF0F; // Magenta
                4'd11: rainbow_color = 12'hF08; // Pink
                default: rainbow_color = 12'hFFF; // White
            endcase
        end
    endfunction

    // Generate RGB output
    always @* begin
        if (~display_active)
            rgb_out = 12'h000; // Blank screen
        else if (render_pixel) begin
            // Assign letter colors based on typing order
            rgb_out = rainbow_color(write_pointer % 16);
        end else begin
            // Generate a fading rainbow background
            rgb_out[11:8] = (frame_counter[23:20] + 4'd1) % 16; // Red component
            rgb_out[7:4] = (frame_counter[19:16] + 4'd5) % 16;  // Green component
            rgb_out[3:0] = (frame_counter[15:12] + 4'd9) % 16;  // Blue component
        end
    end

endmodule
