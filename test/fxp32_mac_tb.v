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
		#50; in_a <= 32'h25733D36; in_b <= 32'hFAF31EDE; 
		#50; in_a <= 32'hF3C4D562; in_b <= 32'hE99616FA; 
		#50; in_a <= 32'hF65CD36C; in_b <= 32'h1E3F66E9; 
		#50; in_a <= 32'hF0C1A3D3; in_b <= 32'h14B54519; 
		#50; in_a <= 32'hBB12C1DE; in_b <= 32'h09DBDF14; 
		#50; in_a <= 32'hE4848079; in_b <= 32'h0BD19FEA; 
		#50; in_a <= 32'hE9CE59C3; in_b <= 32'h15FB35B9; 
		#50; in_a <= 32'hB9B4C4AC; in_b <= 32'h08366123; 
		#50; in_a <= 32'h0E0E089A; in_b <= 32'h4466EEF6; 
		#50; in_a <= 32'hED8BA67B; in_b <= 32'hC359B83F; 
	end

	initial begin
		#100; clk <= 0;
		forever begin
			#25 clk <= ~clk;
		end
	end
endmodule
