`timescale 1ns / 1ps

module system(
    input clk,       // 100MHz clock from Basys 3
    input reset,            // System reset (btnC on Basys 3)
    input btnU,             // User button for data transmission
    input RsRx,             // UART Receive
    output RsTx,            // UART Transmit
    input [7:0] sw,         // Input switches
    input ja1,              // UART Receive from another board
    output ja2,             // UART Transmit to another board
    output hsync,           // VGA Horizontal Sync
    output vsync,           // VGA Vertical Sync
    output [11:0] rgb      // RGB output to VGA
);

    // Internal Signals
    wire [9:0] pixel_x, pixel_y;  // VGA pixel coordinates
    wire video_on, pixel_tick;    // VGA control signals
    wire uart1_received, uart2_received; // UART received signals
    reg [11:0] rgb_reg;           // RGB buffer register
    wire [11:0] rgb_next;         // RGB output from character display
    wire [7:0] data_in, data_out; // UART data signals
    wire [3:0] char_row;          // Character row in text generation
    wire [2:0] bit_addr;          // Bit address in character ROM
    wire [7:0] ground_bus;        // Ground bus for UART communication

    // VGA Assignments
    assign char_row = pixel_y[3:0]; // Row number for character ROM
    assign bit_addr = pixel_x[2:0]; // Column number for character ROM

    // VGA Controller Instance
    vga_controller vga_inst (
        .clk_100MHz(clk),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .p_tick(pixel_tick),
        .x(pixel_x),
        .y(pixel_y)
    );

    // Text Generation Circuit
    char_display text_gen_inst (
        .clk_in(clk),
        .display_active(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .rgb_out(rgb_next),
        .uart_data(data_in),
        .write_en(uart1_received)
    );

    // UART1: Communication with another board
    uart uart1_inst (
        .clk(clk),
        .rx(ja1),
        .tx(RsTx),
        .data_received(data_in),
        .data_transmit(ground_bus),
        .received(uart1_received),
        .dte(1'b0)
    );

    // UART2: Communication with keyboard/switches
    uart uart2_inst (
        .clk(clk),
        .rx(RsRx),
        .tx(ja2),
        .data_received(ground_bus),
        .data_transmit(sw),
        .received(uart2_received),
        .dte(btnU)
    );

    // RGB Buffer Logic
    always @(posedge clk) begin
        if (pixel_tick) begin
            rgb_reg <= rgb_next;
        end
    end

    // Output Assignments
    assign rgb = rgb_reg;

endmodule
