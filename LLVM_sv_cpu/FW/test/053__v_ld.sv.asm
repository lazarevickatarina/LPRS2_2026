

#define R_i $t2
#define R_N $t3
#define R_tmp $t4
#define R_addr $t5

.sdata
end_of_program: 0
out_data_type: 0 // i
out_data_size: 8
out_data:
	0xfeed
	0xbeef
	0xdead
	0xbeef
	0xfeed
	0xbeef
	0xdead
	0xbeef
exp_out_data:
	0x888
	0x999
	0xaaa
	0xbbb
	0xccc
	0xddd
	0xeee
	0xfff

.vdata
in_data:
	0xdeda
	0xbaba
	0xdeda
	0xbaba
	0xdeda
	0xbaba
	0xdeda
	0xbaba
	0x000
	0x111
	0x222
	0x333
	0x444
	0x555
	0x666
	0x777
	0x888
	0x999
	0xaaa
	0xbbb
	0xccc
	0xddd
	0xeee
	0xfff


.text
		nop
		s_d32_mov_i_lo        $t20 = 0
		s_d32_mov_i_lo        $t21 = 8
		s_d32_mov_i_lo        $t22 = 16
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
		v_d64_ld              %t0 = $t20, in_data
		v_d64_ld              %t1 = $t21, in_data
		v_d64_ld              %t2 = $t22, in_data
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


for_init:
		s_d64_ld_i            R_N = $0, out_data_size
		s_d64_mov             R_i = $0
		nop
		nop
		nop
		nop


for_check:
		s_i64_cmp_e           $p = R_i, R_N
	(y)	jmp                   for_end
		nop
		nop
		nop
		nop
		nop


for_body:
		c_d64_to_s            R_tmp = %t2, R_i
		nop
		nop
		nop
		nop
		s_d64_lea             R_addr = R_i, out_data
		nop
		nop
		nop
		s_d64_st              R_addr, R_tmp
		nop
		nop
		nop
		nop
		nop
		nop
		nop
for_inc:
		s_i64_add             R_i = R_i, $1
		jmp                   for_check
		nop
		nop
		nop
		nop
		nop
for_end:
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
