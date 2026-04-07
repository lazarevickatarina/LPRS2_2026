

#define R_i $t2
#define R_N $t3
#define R_tmp $t4
#define R_addr $t5

.sdata
end_of_program: 0
out_data_type: 0 // i
out_data_size: 8
out_data:
	10
	10
	10
	10
	10
	10
	10
	10
exp_out_data:
	100
	1000
	100
	100
	100
	100
	1000
	100


.text
		nop
		v_d32_mov_i_lo        %t1 = 100 // Init
		nop
		nop
		nop
		nop
		nop
		nop
		s_d32_mov_i_lo        $p = 0x42 // Which streams will move it.
		nop
		nop
		nop
		nop
		nop
		nop
		nop
	(y)	v_d32_mov_i_lo        %t1 = 1000
		nop
		nop
		nop
		nop
		nop


for_init:
		s_d64_ld_i            R_N = $zero, out_data_size
		s_d64_mov             R_i = $zero
		nop
		nop
		nop
		nop


for_check:
		s_i64_cmp_e           $p = R_i, R_N
	(y)	jmp                  for_end
		//TODO Optimize
		nop
		nop
		nop
		nop
		nop


for_body:
		c_d64_to_s            R_tmp = %t1, R_i
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
		s_i64_add             R_i = R_i, $one
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
