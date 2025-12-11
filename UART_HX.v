`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Pravin Bhangare
// 
// Create Date: 12/11/2025 04:41:35 PM
// Design Name: 
// Module Name: UART_HX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_rx #(
    parameter integer CLOCK_FREQ = 100_000_000,
    parameter integer BAUD       = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,         // uart rx (from bluetooth TX)
    output reg [7:0]  rx_data,
    output reg        received
);
    localparam integer BAUD_TICKS = CLOCK_FREQ / BAUD;
    localparam IDLE   = 2'd0;
    localparam START  = 2'd1;
    localparam DATA   = 2'd2;
    localparam STOP   = 2'd3;

    reg [1:0] state;
    reg [15:0] tick_cnt;
    reg [3:0] bit_cnt;
    reg [7:0] data_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tick_cnt  <= 0;
            bit_cnt   <= 0;
            data_shift<= 8'b0;
            rx_data   <= 8'b0;
            received  <= 1'b0;
        end else begin
            received <= 1'b0;
            case (state)
                IDLE: begin
                    tick_cnt <= 0;
                    bit_cnt  <= 0;
                    if (rx == 1'b0) begin
                        tick_cnt <= (BAUD_TICKS>>1);
                        state <= START;
                    end
                end
                START: begin
                    if (tick_cnt > 0) tick_cnt <= tick_cnt - 1;
                    else begin
                        tick_cnt <= BAUD_TICKS - 1;
                        bit_cnt <= 0;
                        data_shift <= 8'b0;
                        state <= DATA;
                    end
                end
                DATA: begin
                    if (tick_cnt > 0) tick_cnt <= tick_cnt - 1;
                    else begin
                        tick_cnt <= BAUD_TICKS - 1;
                        data_shift[bit_cnt] <= rx;
                        if (bit_cnt == 7) state <= STOP;
                        else bit_cnt <= bit_cnt + 1;
                    end
                end
                STOP: begin
                    if (tick_cnt > 0) tick_cnt <= tick_cnt - 1;
                    else begin
                        rx_data  <= data_shift;
                        received <= 1'b1;
                        state    <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// UART TX

module uart_tx #(
    parameter integer CLOCK_FREQ = 100_000_000,
    parameter integer BAUD       = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       transmit,
    output reg        tx,
    output reg        busy
);
    localparam integer BAUD_TICKS = CLOCK_FREQ / BAUD;

    reg [15:0] tick_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx       <= 1'b1;
            busy     <= 1'b0;
            tick_cnt <= 0;
            bit_idx  <= 0;
            shift_reg<= 10'b1111111111;
        end else begin
            if (transmit && !busy) begin
                shift_reg <= {1'b1, tx_data, 1'b0};
                busy <= 1'b1;
                tick_cnt <= BAUD_TICKS - 1;
                bit_idx <= 0;
                tx <= 1'b0;
            end else if (busy) begin
                if (tick_cnt > 0) tick_cnt <= tick_cnt - 1;
                else begin
                    tick_cnt <= BAUD_TICKS - 1;
                    bit_idx <= bit_idx + 1;
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    tx <= shift_reg[1];
                    if (bit_idx == 9) begin
                        busy <= 0;
                        tx <= 1'b1;
                    end
                end
            end
        end
    end
endmodule

// bin2bcd

module bin2bcd(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] bin,
    output reg  [15:0] bcd
);
    integer i;
    reg [15:0] bcd_reg;
    reg [7:0] bin_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_reg <= 16'b0;
            bin_reg <= 8'b0;
            bcd     <= 16'b0;
        end else begin
            bin_reg = bin;
            bcd_reg = 16'b0;
            for (i=7; i>=0; i=i-1) begin
                if (bcd_reg[3:0]  >= 5) bcd_reg[3:0]  = bcd_reg[3:0] + 3;
                if (bcd_reg[7:4]  >= 5) bcd_reg[7:4]  = bcd_reg[7:4] + 3;
                if (bcd_reg[11:8] >= 5) bcd_reg[11:8] = bcd_reg[11:8] + 3;
                if (bcd_reg[15:12]>= 5) bcd_reg[15:12]= bcd_reg[15:12] + 3;
                bcd_reg = {bcd_reg[14:0], bin_reg[i]};
            end
            bcd <= bcd_reg;
        end
    end
endmodule

// 7-seg decoder (0-F)

module seg7_decoder_8(
    input  wire [3:0] digit,
    output reg  [7:0] seg
);
    always @(*) begin
        case(digit)
            4'h0: seg = 8'b1100_0000;
            4'h1: seg = 8'b1111_1001;
            4'h2: seg = 8'b1010_0100;
            4'h3: seg = 8'b1011_0000;
            4'h4: seg = 8'b1001_1001;
            4'h5: seg = 8'b1001_0010;
            4'h6: seg = 8'b1000_0010;
            4'h7: seg = 8'b1111_1000;
            4'h8: seg = 8'b1000_0000;
            4'h9: seg = 8'b1001_0000;
            4'hA: seg = 8'b1000_1000;
            4'hB: seg = 8'b1000_0011;
            4'hC: seg = 8'b1100_0110;
            4'hD: seg = 8'b1010_0001;
            4'hE: seg = 8'b1000_0110;
            4'hF: seg = 8'b1000_1110;
            default: seg = 8'b1111_1111;
        endcase
    end
endmodule

// 4-digit 7-segment display multiplexer

module seg7_display_4digit(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [15:0] value_bcd,
    output reg  [3:0] an,
    output wire [7:0] seg
);
    reg [1:0] digit_sel;
    reg [18:0] refresh_cnt;
    localparam REFRESH_DIV = 100_000;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            refresh_cnt <= 0;
            digit_sel <= 0;
        end else begin
            if(refresh_cnt < REFRESH_DIV-1)
                refresh_cnt <= refresh_cnt + 1;
            else begin
                refresh_cnt <= 0;
                digit_sel <= digit_sel + 1;
            end
        end
    end

    reg [3:0] current_nibble;
    always @(*) begin
        case(digit_sel)
            2'd0: current_nibble = value_bcd[3:0];
            2'd1: current_nibble = value_bcd[7:4];
            2'd2: current_nibble = value_bcd[11:8];
            2'd3: current_nibble = value_bcd[15:12];
            default: current_nibble = 4'd0;
        endcase
    end

    always @(*) begin
        an = 4'b1111;
        an[digit_sel] = 1'b0;
    end

    seg7_decoder_8 dec(.digit(current_nibble), .seg(seg));
endmodule

// Top module with decimal and hex 4-digit displays

module uart_bt_8digit(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output wire       tx,
    output wire [7:0] seg_dec,
    output wire [3:0] an_dec,
    output wire [7:0] seg_hex,
    output wire [3:0] an_hex,
    output wire [7:0] leds
);

    // UART RX
    wire [7:0] rx_data;
    wire received;
    uart_rx uart_rx_i (.clk(clk), .rst_n(rst_n), .rx(rx), .rx_data(rx_data), .received(received));

    // UART TX
    reg [7:0] tx_data;
    reg tx_start;
    wire tx_busy;
    uart_tx uart_tx_i (.clk(clk), .rst_n(rst_n), .tx_data(tx_data), .transmit(tx_start), .tx(tx), .busy(tx_busy));

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tx_start <= 0;
            tx_data <= 0;
        end else begin
            if(received && !tx_busy) begin
                tx_data <= rx_data;
                tx_start <= 1'b1;
            end else begin
                tx_start <= 1'b0;
            end
        end
    end

    // LEDs
    assign leds = rx_data;

    // Decimal display
    wire [15:0] bcd_value;
    bin2bcd b2b (.clk(clk), .rst_n(rst_n), .bin(rx_data), .bcd(bcd_value));
    seg7_display_4digit disp_dec (.clk(clk), .rst_n(rst_n), .value_bcd(bcd_value), .an(an_dec), .seg(seg_dec));

    // Hex display
    wire [15:0] hex_value;
    assign hex_value[3:0] = rx_data[3:0];    // lower nibble
    assign hex_value[7:4] = rx_data[7:4];    // upper nibble
    assign hex_value[11:8] = 4'd0;
    assign hex_value[15:12] = 4'd0;
    seg7_display_4digit disp_hex (.clk(clk), .rst_n(rst_n), .value_bcd(hex_value), .an(an_hex), .seg(seg_hex));

endmodule



