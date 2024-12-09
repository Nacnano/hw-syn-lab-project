`timescale 1ns / 1ps

module baudrate_generator (
    input clk,                 // Input clock signal
    output reg baud_signal     // Output baudrate signal
);

    reg [8:0] clk_divider;     // 9-bit counter for clock division

    always @(posedge clk) begin
        // Increment the clock divider
        clk_divider <= clk_divider + 1;

        // Toggle the baud signal and reset the counter when it reaches the threshold
        if (clk_divider == 9'd325) begin
            clk_divider <= 0;
            baud_signal <= ~baud_signal;
        end
    end

endmodule
