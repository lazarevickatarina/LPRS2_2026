

#define R_i $t1
#define R_N $t2
#define R_tmp $t3
#define R_addr $t4

.sdata
end_of_program: 0
out_data_type: 0 // i
out_data_size: 2
out_data:
	0xbaba
	0xdeda
exp_out_data:
	0x03
	0xfe


.text
		nop
		v_i64_cmp_u_le        %t0 = %lane, %1
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		s_d64_lea             R_addr = $0, out_data
		nop
		nop
		nop
		s_d64_st              R_addr, $p
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		
		nop
		v_i64_cmp_u_le        %t0 = %1, %lane
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		s_d64_lea             R_addr = $1, out_data
		nop
		nop
		nop
		s_d64_st              R_addr, $p
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
		s_d64_st              $0, $1 // *end_of_program = 1
infinite_loop:
		jmp infinite_loop
		// Min 6 nops after jmp
		nop
		nop
		nop
		nop
		nop
		nop
