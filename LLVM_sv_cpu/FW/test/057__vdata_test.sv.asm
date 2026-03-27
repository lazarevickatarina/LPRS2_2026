


zero: // must be first to be 0
.sdata
end_of_program: 0
out_data_mem: 1 // v
out_data_type: 1 // f
out_data_size: 1

.vdata
out_data:
	0xba
exp_out_data:
	0xba


.text
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
