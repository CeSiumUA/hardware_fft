module SEG7_LUT	(	oSEG,iDIG	);
input	[3:0]	iDIG;
output	[7:0]	oSEG;
reg		[7:0]	oSEG;

always @(iDIG)
begin
		case(iDIG)
		4'h1: oSEG = 8'b11111001;	// ---t----
		4'h2: oSEG = 8'b10100100; 	// |	  |
		4'h3: oSEG = 8'b10110000; 	// lt	 rt
		4'h4: oSEG = 8'b10011001; 	// |	  |
		4'h5: oSEG = 8'b10010010; 	// ---m----
		4'h6: oSEG = 8'b10000010; 	// |	  |
		4'h7: oSEG = 8'b11111000; 	// lb	 rb
		4'h8: oSEG = 8'b10000000; 	// |	  |
		4'h9: oSEG = 8'b10011000; 	// ---b----
		4'ha: oSEG = 8'b10001000;
		4'hb: oSEG = 8'b10000011;
		4'hc: oSEG = 8'b11000110;
		4'hd: oSEG = 8'b10100001;
		4'he: oSEG = 8'b10000110;
		4'hf: oSEG = 8'b10001110;
		4'h0: oSEG = 8'b11000000;
		endcase
end

endmodule