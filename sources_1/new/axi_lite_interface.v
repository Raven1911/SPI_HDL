`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 03:36:03 PM
// Design Name: 
// Module Name: axi_lite_interface
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


module axi_lite_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(  
    input clk,
    input resetn,

    // AXI-Lite Write Address Channels
    input [ADDR_WIDTH-1:0] i_axi_awaddr,
    input i_axi_awvalid,
    output reg o_axi_awready,

    // AXI-Lite Write Data Channel
    input [DATA_WIDTH-1:0] i_axi_wdata,
    input [3:0] i_axi_wstrb,
    input i_axi_wvalid,
    output reg o_axi_wready,

    // AXI-Lite Write Response Channels
    output reg o_axi_bvalid,
    input i_axi_bready,

    // AXI-Lite Read Address Channels
    input [ADDR_WIDTH-1:0] i_axi_araddr,
    input i_axi_arvalid,
    output reg o_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0] o_axi_rdata,
    output reg o_axi_rvalid,
    input i_axi_rready,

    // Channel for slave
    output reg [3:0] o_wen,
    output reg [ADDR_WIDTH-1:0] o_addr_w,
    output wire [ADDR_WIDTH-1:0] o_addr_r,             
    output reg [DATA_WIDTH-1:0] o_data_w,
    input wire [DATA_WIDTH-1:0] i_data_r,
    output reg o_valid_w,
    output reg o_valid_r
);

    // State declaration
    // Write channel FSM
    localparam W_ADDRESS   = 2'b00;
    localparam W_WRITE     = 2'b01;
    localparam W_RESPONSE  = 2'b10;

    // Read channel FSM
    localparam R_ADDRESS   = 2'b00;
    localparam R_READ      = 2'b01;

    reg [1:0] W_state, R_state; // Current FSM states
    reg [1:0] W_state_next, R_state_next; // Next FSM states

    // Next value registers for outputs
    reg o_axi_awready_next, o_axi_wready_next, o_axi_bvalid_next;
    reg o_axi_arready_next, o_axi_rvalid_next;
    reg [DATA_WIDTH-1:0] o_axi_rdata_next;
    reg [3:0] o_wen_next;
    reg [ADDR_WIDTH-1:0] o_addr_w_next;
    reg [DATA_WIDTH-1:0] o_data_w_next;
    reg o_valid_w_next, o_valid_r_next;

    // Sequential circuit: Update states and outputs
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            W_state <= W_ADDRESS;
            R_state <= R_ADDRESS;
            o_axi_awready <= 0;
            o_axi_wready <= 0;
            o_axi_bvalid <= 0;
            o_axi_arready <= 0;
            o_axi_rvalid <= 0;
            o_axi_rdata <= 0;
            o_wen <= 4'b0000;
            o_addr_w <= 0;
            o_data_w <= 0;
            o_valid_w <= 0;
            o_valid_r <= 0;
        end
        else begin
            W_state <= W_state_next;
            R_state <= R_state_next;
            o_axi_awready <= o_axi_awready_next;
            o_axi_wready <= o_axi_wready_next;
            o_axi_bvalid <= o_axi_bvalid_next;
            o_axi_arready <= o_axi_arready_next;
            o_axi_rvalid <= o_axi_rvalid_next;
            o_axi_rdata <= o_axi_rdata_next;
            o_wen <= o_wen_next;
            o_addr_w <= o_addr_w_next;
            o_data_w <= o_data_w_next;
            o_valid_w <= o_valid_w_next;
            o_valid_r <= o_valid_r_next;
        end
    end

    // Combinational circuit: Determine next states and outputs
    always @(*) begin
        // Default values
        W_state_next = W_state;
        R_state_next = R_state;
        o_axi_awready_next = 0;
        o_axi_wready_next = 0;
        o_axi_bvalid_next = 0;
        o_axi_arready_next = 0;
        o_axi_rvalid_next = 0;
        o_axi_rdata_next = o_axi_rdata;
        o_wen_next = 4'b0000;
        o_addr_w_next = o_addr_w;
        o_data_w_next = o_data_w;
        o_valid_w_next = 0;
        o_valid_r_next = 0;

        // Write channel FSM
        case (W_state)
            W_ADDRESS: begin
                o_axi_bvalid_next = 0;
                o_valid_w_next = 0;
                if (i_axi_awvalid) begin
                    o_axi_awready_next = 1;
                    o_addr_w_next = i_axi_awaddr;
                    W_state_next = W_WRITE;
                end
            end
            W_WRITE: begin
                o_axi_awready_next = 0;
                if (i_axi_wvalid) begin
                    o_axi_wready_next = 1;
                    o_wen_next = i_axi_wstrb;
                    o_data_w_next = i_axi_wdata;
                    W_state_next = W_RESPONSE;
                end
            end
            W_RESPONSE: begin
                o_axi_wready_next = 0;
                o_wen_next = 4'b0000;
                if (i_axi_bready) begin
                    o_axi_bvalid_next = 1;
                    o_valid_w_next = 1;
                    W_state_next = W_ADDRESS;
                end
            end
            default: begin
                W_state_next = W_ADDRESS;
            end
        endcase

        // Read channel FSM
        case (R_state)
            R_ADDRESS: begin
                o_axi_rvalid_next = 0;
                o_valid_r_next = 0;
                if (i_axi_arvalid) begin
                    o_axi_arready_next = 1;
                    R_state_next = R_READ;
                end
            end
            R_READ: begin
                o_axi_arready_next = 0;
                if (i_axi_rready) begin
                    o_axi_rvalid_next = 1;
                    o_valid_r_next = 1;
                    o_axi_rdata_next = i_data_r;
                    R_state_next = R_ADDRESS;
                end
            end
            default: begin
                R_state_next = R_ADDRESS;
            end
        endcase
    end

    // Assign read address directly
    assign o_addr_r = i_axi_araddr;

endmodule