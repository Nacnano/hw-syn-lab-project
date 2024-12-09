`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA Controller for 640x480 resolution at 60 Hz refresh rate with a 25 MHz pixel clock.
// Adapted for Basys 3 FPGA with a 100 MHz clock signal.
//
// Author: David J. Marion (adapted)
// Ref: "FPGA Prototyping by Verilog Examples" by Pong P. Chu
//////////////////////////////////////////////////////////////////////////////////

module vga_controller (
    input clk_100MHz,         // Input clock (100 MHz)
    input reset,              // System reset
    output video_on,          // Signal asserted when pixels are within the display area
    output hsync,             // Horizontal synchronization signal
    output vsync,             // Vertical synchronization signal
    output p_tick,            // 25 MHz pixel clock
    output [9:0] x,           // Current pixel X coordinate (0-799)
    output [9:0] y            // Current pixel Y coordinate (0-524)
);

    // VGA Timing Parameters for 640x480 resolution
    parameter HD = 640;       // Horizontal display area width (pixels)
    parameter HF = 48;        // Horizontal front porch (pixels)
    parameter HB = 16;        // Horizontal back porch (pixels)
    parameter HR = 96;        // Horizontal retrace (pixels)
    parameter HMAX = HD + HF + HB + HR - 1; // Total horizontal pixels (800)

    parameter VD = 480;       // Vertical display area height (pixels)
    parameter VF = 10;        // Vertical front porch (lines)
    parameter VB = 33;        // Vertical back porch (lines)
    parameter VR = 2;         // Vertical retrace (lines)
    parameter VMAX = VD + VF + VB + VR - 1; // Total vertical lines (525)

    // Generate 25 MHz Pixel Clock from 100 MHz Input Clock
    reg [1:0] clk_divider;
    always @(posedge clk_100MHz or posedge reset) begin
        if (reset)
            clk_divider <= 0;
        else
            clk_divider <= clk_divider + 1;
    end

    assign p_tick = (clk_divider == 2'b00); 

    // Horizontal and Vertical Counters
    reg [9:0] h_count = 0, v_count = 0;
    always @(posedge p_tick or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == HMAX) begin
                h_count <= 0;
                if (v_count == VMAX)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else
                h_count <= h_count + 1;
        end
    end

    // Horizontal and Vertical Sync Signals
    wire hsync_active = (h_count >= (HD + HB)) && (h_count < (HD + HB + HR));
    wire vsync_active = (v_count >= (VD + VB)) && (v_count < (VD + VB + VR));

    // Video On Signal
    assign video_on = (h_count < HD) && (v_count < VD);

    // Outputs
    assign hsync = ~hsync_active;   // Active low signal
    assign vsync = ~vsync_active;   // Active low signal
    assign x = h_count;
    assign y = v_count;

endmodule
