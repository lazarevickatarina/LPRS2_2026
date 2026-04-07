

// add vectors of i64 like z = x .+ y of lenght N

#define R_i $t1
#define R_N $t2
#define R_x $t3
#define R_y $t4
#define R_z $t5
#define R_za $t6

.sdata
end_of_program: 0
out_data_type: 0 // i
N: 4 // out_data_size
z:
	0xba
	0xba
	0xde
	0xda
exp_z:
	0x11
	0x22
	0x33
	0x44

x:
	1
	2
	3
	4
y:
	0x10
	0x20
	0x30
	0x40

.text
		nop
for_init:
		s_d64_ld_i            R_N = $zero, N
		s_d64_mov             R_i = $zero
		nop
		nop
		nop
		nop

for_check:
		s_i64_cmp_e           $p = R_i, R_N
	(y)	jmp                   for_end
		//TODO Optimize
		nop
		nop
		nop
		nop
		nop
		
for_body:
		s_d64_ld_i            R_x = R_i, x
		s_d64_ld_i            R_y = R_i, y
		nop
		nop
		nop
		s_d64_lea             R_za = R_i, z
		s_i64_add             R_z = R_x, R_y
		nop
		nop
		s_d64_st              R_za, R_z
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
		jmp                   infinite_loop
		nop
		nop
		nop
		nop
		nop
		nop
