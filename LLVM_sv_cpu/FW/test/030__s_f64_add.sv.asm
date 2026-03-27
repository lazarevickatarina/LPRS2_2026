
#define ADDR1 $t10

.sdata
end_of_program: 0
out_data_size: 2
out_data:
	10.0
	20.0
exp_out_data:
	3.0
	4.0

in_data:
	1.0 // 0x3ff0000000000000
	2.0 // 0x4000000000000000
	3.0 // 0x4008000000000000
	4.0 // 0x4010000000000000
	


.text
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		
		// ld: 5 instr before usage of d0
		s_d64_ld $t1=$zero,in_data
		nop
		nop
		nop
		nop
		nop
		s_d64_ld $t2=$one,in_data
		nop
		nop
		nop
		nop
		nop
		
		
		
		// For sure.
		nop
		nop
		// after 16clk, $t3 = 3.0
		s_f64_add $t3 = $t1, $t2
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
		nop // If comment this nop, to be on 15clk then $t4 = 0 instead of 4.0
		// after 16clk, $t4 = 4.0
		s_f64_add $t4 = $t1, $t3
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
		// Enough for sure.
		
		
		// usual: 2 instr before usage of d0
		s_d64_lea ADDR1=$zero,out_data
		s_d64_lea ADDR1=$one,out_data
		nop
		s_d64_st ADDR1,$t3
		s_d64_st ADDR1,$t4
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