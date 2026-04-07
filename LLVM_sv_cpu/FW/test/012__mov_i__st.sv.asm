
#define R_tmp $t11
#define R_addr $t1

.sdata
end_of_program: 0
out_data_type: 0 // i
out_data_size: 1
out_data:
	1
exp_out_data:
	0x7766554433221100


.text
		nop
		s_d32_mov_i_lo R_tmp = 0x33221100
		nop
		nop
		s_d32_mov_i_hi R_tmp = R_tmp, 0x77665544
		
		s_d64_lea R_addr = $0, out_data
		nop
		nop

		s_d64_st R_addr, R_tmp
		nop
		nop

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		s_d64_st $zero,$one // *end_of_program = 1
infinite_loop:
		jmp infinite_loop
		// Min 6 nops after jmp
		nop
		nop
		nop
		nop
		nop
		nop
