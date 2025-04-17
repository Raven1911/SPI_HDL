`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/17/2025 11:39:06 PM
// Design Name: 
// Module Name: Spi
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


module Spi #(
    parameter DATA_WITH = 8
)(
    input                       clk,
    input                       resetn,
    input   [DATA_WITH-1:0]     din,
    input   [15:0]              dvsr, //0.5*(# clk in SCK period)
    input                       start,
    input                       cpol,
    input                       cpha,
    output  [DATA_WITH-1:0]     dout,
    output                      spi_done_tick,
    output                      ready,

    //spi interface
    output                      sclk,
    input                       miso,
    output                      mosi    


    );
endmodule
