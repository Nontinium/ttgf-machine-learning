`default_nettype none

module tt_um_machinelearning (
    input  wire [7:0] ui_in,    
    output reg [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);
    
    assign uio_out = 0;
    assign uio_oe  = 0;

    // ===== STAGE 1: Compute hidden layer (COMBINATIONAL) =====
    wire signed [8:0] h0_raw, h2_raw, h3_raw;
    wire signed [8:0] h0, h2, h3; 
    
    assign h0_raw = (ui_in[0]?-3:0)+(ui_in[1]?-5:0)+(ui_in[3]?4:0)+(ui_in[4]?-1:0)+(ui_in[6]?-2:0);
    assign h2_raw = (ui_in[0]?28:0)+(ui_in[1]?19:0)+(ui_in[2]?-24:0)+(ui_in[3]?15:0)+(ui_in[4]?37:0)+(ui_in[5]?-37:0)+(ui_in[6]?29:0) + 5;
    assign h3_raw = (ui_in[0]?23:0)+(ui_in[1]?36:0)+(ui_in[2]?32:0)+(ui_in[3]?-9:0)+(ui_in[4]?3:0)+(ui_in[5]?-28:0)+(ui_in[6]?-30:0) + 9;

    assign h0 = (h0_raw[8]) ? 9'd0 : h0_raw;
    assign h2 = (h2_raw[8]) ? 9'd0 : h2_raw;
    assign h3 = (h3_raw[8]) ? 9'd0 : h3_raw;

    // ===== STAGE 1 → STAGE 2 PIPELINE REGISTER =====
    reg signed [8:0] h0_p, h2_p, h3_p;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h0_p <= 0;
            h2_p <= 0;
            h3_p <= 0;
        end else begin
            h0_p <= h0;
            h2_p <= h2;
            h3_p <= h3;
        end
    end

    // ===== STAGE 2: Compute output scores (COMBINATIONAL) =====
    wire signed [13:0] e0, e1, e2, e3, e4, e5, e6, e7, e8, e9;

    assign e0 = (-6 * h0_p) + (-1 * h2_p) + (23 * h3_p) - 180;
    assign e1 = ( 5 * h0_p) + (-38 * h2_p) + (32 * h3_p) - 120;
    assign e2 = ( 5 * h0_p) + ( 36 * h2_p) + (-30 * h3_p) - 280;
    assign e3 = ( 3 * h0_p) + ( 17 * h2_p) + ( 8 * h3_p) - 350;
    assign e4 = (-3 * h0_p) + (-27 * h2_p) + (20 * h3_p) + 380;
    assign e5 = (-4 * h0_p) + ( 23 * h2_p) + (-29 * h3_p) + 360;
    assign e6 = ( 3 * h0_p) + ( 36 * h2_p) + (-48 * h3_p) - 30;
    assign e7 = (-1 * h0_p) + (-17 * h2_p) + (31 * h3_p) - 340;
    assign e8 = (-6 * h0_p) + ( 28 * h2_p) + (-13 * h3_p) - 90;
    assign e9 = (-1 * h0_p) + ( 7 * h2_p) + ( 4 * h3_p) + 350;

    // ===== STAGE 3: Tournament argmax (COMBINATIONAL) =====
    wire signed [13:0] m01 = (e0 >= e1) ? e0 : e1;
    wire [3:0]         p01 = (e0 >= e1) ? 4'd0 : 4'd1;
    wire signed [13:0] m23 = (e2 >= e3) ? e2 : e3;
    wire [3:0]         p23 = (e2 >= e3) ? 4'd2 : 4'd3;
    wire signed [13:0] m45 = (e4 >= e5) ? e4 : e5;
    wire [3:0]         p45 = (e4 >= e5) ? 4'd4 : 4'd5;
    wire signed [13:0] m67 = (e6 >= e7) ? e6 : e7;
    wire [3:0]         p67 = (e6 >= e7) ? 4'd6 : 4'd7;
    wire signed [13:0] m89 = (e8 >= e9) ? e8 : e9;
    wire [3:0]         p89 = (e8 >= e9) ? 4'd8 : 4'd9;

    wire signed [13:0] m03 = (m01 >= m23) ? m01 : m23;
    wire [3:0]         p03 = (m01 >= m23) ? p01 : p23;
    wire signed [13:0] m47 = (m45 >= m67) ? m45 : m67;
    wire [3:0]         p47 = (m45 >= m67) ? p45 : p67;

    wire signed [13:0] m07 = (m03 >= m47) ? m03 : m47;
    wire [3:0]         p07 = (m03 >= m47) ? p03 : p47;

    wire [3:0] final_prediction = (m07 >= m89) ? p07 : p89;

    // ===== STAGE 4: Final output register =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uo_out <= 8'b0;
        end else begin
            uo_out <= {4'b0000, final_prediction}; 
        end
    end

    wire _unused = &{ena, ui_in[7], uio_in, 1'b0};

endmodule

`default_nettype wire
