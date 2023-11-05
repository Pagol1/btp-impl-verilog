module fxp32_mac_tb;
	// Inputs
	reg clk;
	reg rstn;
	reg prstn;
	reg acc;
	reg [31:0] in_a;
	reg [31:0] in_b;

	// Outputs
	wire [31:0] out_c;

	fxp32_mac uut(.clk(clk), .rstn(rstn), .prstn(prstn), .acc(acc), .in_a(in_a), .in_b(in_b), .out_c(out_c));

	initial begin
		clk <= 0; rstn <= 0; acc <= 0; prstn <= 0; in_a <= 0; in_b <= 0;
		// Wait 100 ns for global reset to finish
		#100;
		rstn <= 1'b1; prstn <= 1'b1; acc <= 1'b1; 
		#50; in_a <= 32'h9C633320; in_b <= 32'h3E0A7FBE; 
		#50; in_a <= 32'h6E254B8B; in_b <= 32'h942601F8; 
		#50; in_a <= 32'h2F2CC39D; in_b <= 32'hAA705D0B; 
		#50; in_a <= 32'hDEC4F88F; in_b <= 32'hE7649760; 
		#50; in_a <= 32'hA96AC34F; in_b <= 32'hAA06D951; 
		#50; in_a <= 32'hC3A6F2FF; in_b <= 32'h4DF5339A; 
		#50; in_a <= 32'hB9E1DB1; in_b <= 32'hBBE949D; 
		#50; in_a <= 32'h3EF04FDD; in_b <= 32'h3C7B9748; 
		#50; in_a <= 32'h610403B5; in_b <= 32'hA77D0F8A; 
		#50; in_a <= 32'hB474FF8; in_b <= 32'hE28D1059; 
	end

	initial begin
		#100; clk <= 0;
		forever begin
			#25 clk <= ~clk;
		end
	end
endmodule
