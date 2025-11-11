`timescale 1ns / 1ps


module top #(parameter datawidth = 8, addr_width = 3)
(
  input  [datawidth-1:0] wdata,
  input  winc, wclk,
  input  rinc, rclk,
  input  wrst_n, rrst_n,
  output [datawidth-1:0] rdata,
  output wfull, rempty
);

  wire [addr_width:0] wptr, rptr;
  wire [addr_width:0] wq2_rptr, rq2_wptr;
  wire [addr_width:0] b2gr, b2gw;
  wire [addr_width:0] g2br, g2bw;
  wire [addr_width-1:0] waddr, raddr;
  wire wclken;

  assign wclken = winc & (~wfull);

  // Synchronize gray pointers across domains
  twoflopsync #(.addr_width(addr_width)) s1 (
    .clk(wclk), .rstn(wrst_n), .ptr(b2gw), .q2(g2bw)
  );

  twoflopsync #(.addr_width(addr_width)) s2 (
    .clk(rclk), .rstn(rrst_n), .ptr(b2gr), .q2(g2br)
  );

  // Binary to Gray
  binary2gray #(.addr_width(addr_width)) s3 (
    .data(wptr), .gray(b2gw)
  );

  binary2gray #(.addr_width(addr_width)) s4 (
    .data(rptr), .gray(b2gr)
  );

  // Gray to Binary
  gray2binary #(.addr_width(addr_width)) s5 (
    .gray(g2bw), .binary(rq2_wptr)
  );

  gray2binary #(.addr_width(addr_width)) s6 (
    .gray(g2br), .binary(wq2_rptr)
  );

  // Read and empty logic
  rptr_and_empty #(.addr_width(addr_width)) s7 (
    .rinc(rinc), .rclk(rclk), .rrst_n(rrst_n),
    .rq2_wptr(rq2_wptr), .rptr(rptr), .raddr(raddr), .rempty(rempty)
  );
  //write and full logic
  wptr_and_full #(.addr_width(addr_width)) s8 (
    .winc(winc), .wclk(wclk), .wrst_n(wrst_n),
    .wq2_rptr(wq2_rptr), .wptr(wptr), .waddr(waddr), .wfull(wfull)
  );

  // FIFO memory
  fifomem #(.addr_width(addr_width), .datawidth(datawidth)) s9 (
    .wdata(wdata), .wclken(wclken), .wclk(wclk),
    .waddr(waddr), .raddr(raddr), .rdata(rdata), .rempty(rempty)
  );

endmodule

module fifomem #(parameter datawidth = 8, parameter addr_width = 3)
(
  input  [datawidth-1:0] wdata,
  input                  wclken,
  input                  wclk,
  input                  rempty,
  input  [addr_width-1:0] waddr,
  input  [addr_width-1:0] raddr,
  output [datawidth-1:0] rdata
);

  localparam fifo_depth = 1 << addr_width;

  // RAM having 'fifo_depth' locations, each 'datawidth' wide
  reg [datawidth-1:0] fifo_ram [0:fifo_depth-1];

  // Write logic
  always @(posedge wclk) begin
    if (wclken)
      fifo_ram[waddr] <= wdata;
  end

  // Combinational read
  assign rdata = rempty?0:fifo_ram[raddr];

endmodule

module wptr_and_full #(parameter addr_width = 3)
(
  input winc,
  input wclk,
  input wrst_n,
  input [addr_width:0] wq2_rptr,  // Synchronized read pointer (Gray code) from read domain

  output reg [addr_width:0] wptr,
  output reg [addr_width-1:0] waddr,
  output wfull
);

  // Compute next write pointer
  wire [addr_width:0] wptr_next = wptr + 1;

  // FIFO is full when wrap around
  assign wfull = (wq2_rptr=={~wptr[addr_width],wptr[addr_width-1:0]});

  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr  <= 0;
      waddr <= 0;
    end else begin
      if (winc && !wfull)
        wptr <= wptr_next;

      waddr <= wptr[addr_width-1:0];
    end
  end

endmodule
module twoflopsync #(parameter addr_width=3) (input clk,rstn,input [addr_width:0] ptr,output reg [addr_width:0] q2);
  reg [addr_width:0] q1;

  always@(posedge clk or negedge rstn) begin
    
    if(!rstn) begin
      q2<=0;
      q1<=0;end
    else begin
      q1<=ptr;
      q2<=q1;
    end  
  end

endmodule
  module rptr_and_empty #(parameter addr_width = 3)
(
  input rinc,
  input rclk,
  input rrst_n,
  input [addr_width:0] rq2_wptr,  // synchronized wptr from write clock domain

  output reg [addr_width:0] rptr,
  output reg [addr_width-1:0] raddr,
  output rempty
);

  // Calculate next rptr
  wire [addr_width:0] rptr_next = rptr + 1;

  // FIFO is empty if rptr equals synchronized write pointer
  assign rempty = (!rrst_n) || (rq2_wptr == rptr);

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr <= 0;
      raddr <= 0;
    end else begin
      if (rinc && !rempty)
        rptr <= rptr_next;

      raddr <= rptr[addr_width-1:0];
    end
  end

endmodule

module gray2binary #(parameter addr_width = 3)(
    input  [addr_width:0] gray,
    output reg [addr_width:0] binary
);
    integer i;
    always @(*) begin
        binary[addr_width] = gray[addr_width];  // MSB is same
        for (i = addr_width - 1; i >= 0; i = i - 1)
            binary[i] = binary[i + 1] ^ gray[i];
    end
endmodule

module binary2gray #(parameter addr_width=3)(
    input  [addr_width:0] data,
    output reg [addr_width:0] gray
);
    integer i;
    always @(*) begin
        gray[addr_width] = data[addr_width];
        for(i = addr_width; i > 0; i = i - 1)
            gray[i-1] = data[i] ^ data[i-1];
    end
endmodule


