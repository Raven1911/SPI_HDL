`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 04:47:01 PM
// Design Name: 
// Module Name: spi_axi_lite_core_tb
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


module spi_axi_lite_core_tb;

    // Parameters
    parameter NSlave = 2;
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // 100 MHz clock

    // Inputs
    reg clk;
    reg resetn;
    reg [ADDR_WIDTH-1:0] i_axi_awaddr;
    reg i_axi_awvalid;
    reg [DATA_WIDTH-1:0] i_axi_wdata;
    reg [3:0] i_axi_wstrb;
    reg i_axi_wvalid;
    reg i_axi_bready;
    reg [ADDR_WIDTH-1:0] i_axi_araddr;
    reg i_axi_arvalid;
    reg i_axi_rready;
    reg spi_miso;

    // Outputs
    wire o_axi_awready;
    wire o_axi_wready;
    wire o_axi_bvalid;
    wire o_axi_arready;
    wire [DATA_WIDTH-1:0] o_axi_rdata;
    wire o_axi_rvalid;
    wire spi_clk;
    wire spi_mosi;
    wire [NSlave-1:0] spi_ss_n;

    // Instantiate the DUT
    Spi_axi_lite_core #(
        .NSlave(NSlave),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .i_axi_awaddr(i_axi_awaddr),
        .i_axi_awvalid(i_axi_awvalid),
        .o_axi_awready(o_axi_awready),
        .i_axi_wdata(i_axi_wdata),
        .i_axi_wstrb(i_axi_wstrb),
        .i_axi_wvalid(i_axi_wvalid),
        .o_axi_wready(o_axi_wready),
        .o_axi_bvalid(o_axi_bvalid),
        .i_axi_bready(i_axi_bready),
        .i_axi_araddr(i_axi_araddr),
        .i_axi_arvalid(i_axi_arvalid),
        .o_axi_arready(o_axi_arready),
        .o_axi_rdata(o_axi_rdata),
        .o_axi_rvalid(o_axi_rvalid),
        .i_axi_rready(i_axi_rready),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss_n(spi_ss_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset and initialization
    initial begin
        // Initialize inputs
        resetn = 0;
        i_axi_awaddr = 0;
        i_axi_awvalid = 0;
        i_axi_wdata = 0;
        i_axi_wstrb = 4'b1111;
        i_axi_wvalid = 0;
        i_axi_bready = 0;
        i_axi_araddr = 0;
        i_axi_arvalid = 0;
        i_axi_rready = 0;
        spi_miso = 0;

        // Apply reset
        #(CLK_PERIOD*5);
        resetn = 1;
        #(CLK_PERIOD*5);

        // Run test sequence
        test_sequence();
        $finish;
    end

    // Task for AXI-Lite write transaction
    task axi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            // Write address phase
            @(posedge clk);
            i_axi_awaddr = addr;
            i_axi_awvalid = 1;
            wait(o_axi_awready);
            @(posedge clk);
            i_axi_awvalid = 0;

            // Write data phase
            i_axi_wdata = data;
            i_axi_wvalid = 1;
            wait(o_axi_wready);
            @(posedge clk);
            i_axi_wvalid = 0;

            // Write response phase
            i_axi_bready = 1;
            wait(o_axi_bvalid);
            @(posedge clk);
            i_axi_bready = 0;
        end
    endtask

    // Task for AXI-Lite read transaction
    task axi_read;
        input [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] rdata;
        begin
            // Read address phase
            @(posedge clk);
            i_axi_araddr = addr;
            i_axi_arvalid = 1;
            wait(o_axi_arready);
            @(posedge clk);
            i_axi_arvalid = 0;

            // Read data phase
            i_axi_rready = 1;
            wait(o_axi_rvalid);
            rdata = o_axi_rdata;
            @(posedge clk);
            i_axi_rready = 0;
        end
    endtask

    // Test sequence
    task test_sequence;
        reg [DATA_WIDTH-1:0] rdata;
        begin
            $display("Starting test sequence at time %t", $time);

            // Test 1: Configure control register (cpha=0, cpol=0, dvsr=512)
            $display("Writing to control register (addr=0x3)");
            axi_write(32'h3, 32'h00000001); // cpha=0, cpol=0, dvsr=512
            #(CLK_PERIOD*10);

            // Test 2: Select slave 0 (spi_ss_n = 2'b10)
            $display("Writing to slave select register (addr=0x1)");
            axi_write(32'h1, 32'h00000002); // spi_ss_n = 2'b10
            #(CLK_PERIOD*10);

            // Test 3: Write SPI data (send 0xA5)
            $display("Writing to SPI data register (addr=0x2)");
            axi_write(32'h2, 32'h000000A5); // SPI data = 0xA5
            #(CLK_PERIOD*50);
            $display("Writing to SPI data register (addr=0x2)");
            axi_write(32'h2, 32'h000000A6); // SPI data = 0xA5
            #(CLK_PERIOD*50);
            $display("Writing to SPI data register (addr=0x2)");
            axi_write(32'h2, 32'h000000A7); // SPI data = 0xA5
            #(CLK_PERIOD*50);
            // #(CLK_PERIOD*10);
            //  // Test 2: Select slave 0 (spi_ss_n = 2'b10)
            // $display("Writing to slave select register (addr=0x1)");
            // axi_write(32'h1, 32'h00000002); // spi_ss_n = 2'b10
            // #(CLK_PERIOD*10);

            // // Test 3: Write SPI data (send 0xA5)
            // $display("Writing to SPI data register (addr=0x2)");
            // axi_write(32'h2, 32'h00000055); // SPI data = 0xA5
            // #(CLK_PERIOD*1000); // Wait for SPI transaction

            // Simulate MISO data (slave sends 0x5A)
            repeat(8) begin
                @(negedge spi_clk);
                spi_miso = ~spi_miso; // Toggle for simplicity (0x5A = 01011010)
            end

            // Test 4: Read SPI data
            $display("Reading from SPI data register (addr=0x2)");
            axi_read(32'h2, rdata);
            $display("Read data: 0x%h", rdata);
            #(CLK_PERIOD*10);

            // Test 5: Deselect slaves (spi_ss_n = 2'b11)
            $display("Deselecting slaves (addr=0x1)");
            axi_write(32'h1, 32'h00000003); // spi_ss_n = 2'b11
            #(CLK_PERIOD*10);

            $display("Test sequence completed at time %t", $time);
        end
    endtask

    // Monitor SPI signals
    initial begin
        $monitor("Time=%t, spi_clk=%b, spi_mosi=%b, spi_miso=%b, spi_ss_n=%b",
                 $time, spi_clk, spi_mosi, spi_miso, spi_ss_n);
    end

endmodule
