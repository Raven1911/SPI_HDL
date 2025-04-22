`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 03:35:24 PM
// Design Name: 
// Module Name: Spi_axi_lite_core
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


module Spi_axi_lite_core#(
    parameter NSlave = 2,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input resetn,

    //axi lite interface
    //AXI-Lite Write Address Channels
    input [ADDR_WIDTH-1:0]          i_axi_awaddr,
    input                           i_axi_awvalid,
    output wire                     o_axi_awready,

    //AXI-Lite Write Data Channel
    input [DATA_WIDTH-1:0]          i_axi_wdata,
    input [3:0]                     i_axi_wstrb,
    input                           i_axi_wvalid,
    output wire                     o_axi_wready,

    //AXI-Lite Write Response Channels
    output wire                     o_axi_bvalid,
    input                           i_axi_bready,

    //AXI-Lite Read Address Channels
    input [ADDR_WIDTH-1:0]          i_axi_araddr,
    input                           i_axi_arvalid,
    output wire                     o_axi_arready,

    //AXI4-Lite Read Data Channel
    output wire [DATA_WIDTH-1:0]    o_axi_rdata,
    output wire                     o_axi_rvalid,
    input                           i_axi_rready,

    //external logic
    output                          spi_clk,
    output                          spi_mosi,
    input                           spi_miso,
    output reg [NSlave-1:0]         spi_ss_n
    );

    
    //signals to connect
    //wire [3:0] o_wen;
    wire [ADDR_WIDTH-1:0] o_addr_w;
    //wire [ADDR_WIDTH-1:0] o_addr_r;                
    wire [DATA_WIDTH-1:0] o_data_w;
    wire [DATA_WIDTH-1:0] i_data_r;

    wire o_valid_w;
    //wire o_valid_r;


    //
    wire wr_ss, wr_spi, wr_ctrl;
    //reg [17:0] ctrl_reg;
    //reg [NSlave-1:0] ss_n_reg;
    wire [7:0] spi_out;
    wire spi_ready;
    reg cpol, cpha;
    reg [15:0] dvsr;


    //seq
    always @(posedge clk, negedge resetn) begin
        if(~resetn) begin
            {cpha, cpol, dvsr} <= 17'h0_0200;
            spi_ss_n <= {NSlave{1'b1}};
        end

        else begin
            if (wr_ctrl) begin
                //ctrl_reg <=  o_data_w[17:0];
                dvsr = o_data_w[15:0];
                cpol = o_data_w[16];
                cpha = o_data_w[17];
            end    
            
            if (wr_ss)  spi_ss_n <=  o_data_w[NSlave-1:0];
        end
    end

    //decoding 
    assign wr_ss    = (o_valid_w && (o_addr_w[31:0] == 32'b01)) ? 1 : 0;
    assign wr_spi   = (o_valid_w && (o_addr_w[31:0] == 32'b10)) ? 1 : 0;
    assign wr_ctrl  = (o_valid_w && (o_addr_w[31:0] == 32'b11)) ? 1 : 0;

    //read multiplexing
    assign i_data_r = {23'b0, spi_ready, spi_out};

    Spi #(.DATA_WITH(8)) Spi_unit
    (
        .clk(clk),
        .resetn(resetn),
        .din(o_data_w[7:0]),
        .dvsr(dvsr), //0.5*(# clk in SCK period)
        .start(wr_spi),
        .cpol(cpol),
        .cpha(cpha),
        .dout(spi_out),
        .spi_done_tick(),
        .ready(spi_ready),

        //spi interface
        .sclk(spi_clk),
        .miso(spi_miso),
        .mosi(spi_mosi)    

    );

    // Instantiate axi interface module
    axi_lite_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi_adapter(
        .clk(clk),
        .resetn(resetn),

        //AXI-Lite Write Address Channels
        .i_axi_awaddr(i_axi_awaddr),
        .i_axi_awvalid(i_axi_awvalid),
        .o_axi_awready(o_axi_awready),

        //AXI-Lite Write Data Channel
        .i_axi_wdata(i_axi_wdata),
        .i_axi_wstrb(i_axi_wstrb),
        .i_axi_wvalid(i_axi_wvalid),
        .o_axi_wready(o_axi_wready),

        //AXI-Lite Write Response Channels
        .o_axi_bvalid(o_axi_bvalid),
        .i_axi_bready(i_axi_bready),

        //AXI-Lite Read Address Channels
        .i_axi_araddr(i_axi_araddr),
        .i_axi_arvalid(i_axi_arvalid),
        .o_axi_arready(o_axi_arready),

        //AXI4-Lite Read Data Channel
        .o_axi_rdata(o_axi_rdata),
        .o_axi_rvalid(o_axi_rvalid),
        .i_axi_rready(i_axi_rready),    

        //channel for slave
        .o_wen(),
        .o_addr_w(o_addr_w),
        .o_addr_r(),             
        .o_data_w(o_data_w),
        .i_data_r(i_data_r),
        .o_valid_w(o_valid_w),
        .o_valid_r()
    );


    



endmodule
