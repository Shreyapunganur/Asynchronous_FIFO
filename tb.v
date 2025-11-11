


`timescale 1ns / 1ps

module tb;

  parameter DATAWIDTH = 8;
  parameter ADDR_WIDTH = 3;
  localparam DEPTH = 1 << ADDR_WIDTH;

  reg                   wclk = 0, rclk = 0;
  reg                   wrst_n = 0, rrst_n = 0;
  reg                   winc = 0, rinc = 0;
  reg  [DATAWIDTH-1:0]  wdata;
  wire [DATAWIDTH-1:0]  rdata;
  wire                  wfull, rempty;

  // Instantiate the FIFO
  top #(
    .datawidth(DATAWIDTH),
    .addr_width(ADDR_WIDTH)
  ) uut (
    .wdata(wdata),
    .winc(winc),
    .wclk(wclk),
    .rinc(rinc),
    .rclk(rclk),
    .wrst_n(wrst_n),
    .rrst_n(rrst_n),
    .rdata(rdata),
    .wfull(wfull),
    .rempty(rempty)
  );

  // Clock generators
  always #5 wclk = ~wclk;     // 10 ns period
  always #6.5 rclk = ~rclk;   // 13 ns period

  integer i;

  initial begin
    $dumpfile("fifo_dump.vcd");
    $dumpvars(0, tb);

    // Reset
    wrst_n = 0; rrst_n = 0;
    winc = 0;  rinc = 0;
    wdata = 0;
    #30;
    wrst_n = 1; rrst_n = 1;
    #20;

    // --------------------------
    // Step 1: Write until full
    // --------------------------
    $display("Writing until FIFO is full...");
    for (i = 0; i < DEPTH + 2; i = i + 1) begin
      @(posedge wclk);
      if (!wfull) begin
        wdata <= i;
        winc <= 1;
        $display("Time %0t ns: Writing %0d (wfull=%0b)", $time, i, wfull);
      end else begin
        $display("Time %0t ns: Cannot write, FIFO FULL! (wfull=%d)", $time,wfull);
        winc <= 0;
      end
      @(posedge wclk);
      winc <= 0;
    end

    // --------------------------
    // Step 2: Read until empty
    // --------------------------
    #50;
    $display("\nReading until FIFO is empty...");
    for (i = 0; i < DEPTH + 2; i = i + 1) begin
      @(posedge rclk);
      if (!rempty) begin
        rinc <= 1;
        @(posedge rclk);
        $display("Time %0t ns: Read data = %0d (rempty=%0b)", $time, rdata, rempty);
        rinc <= 0;
      end else begin
        $display("Time %0t ns: Cannot read, FIFO EMPTY!(rempty=%d)", $time,rempty);
        rinc <= 0;
      end
    end

    #50;
    $finish;
  end

endmodule

