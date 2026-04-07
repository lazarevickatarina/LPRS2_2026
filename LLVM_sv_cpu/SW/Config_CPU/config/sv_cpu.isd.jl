
N_cores = 2
register_width = 64
registers_number = 1<<11

RegAliases = Dict{UInt32, Vector{String}}
_common_ra = RegAliases(
	# Up to 1024 are special purpose registers.
	0 => [ "zero" ],
	1 => [ "one" ], # 1 for i type

	20 => [ "fone" ], # +1.0 for f type
	21 => [ "2pi" ],
	22 => [ "pi" ],
	23 => [ "pi2" ],
	24 => [ "pi3" ],
	25 => [ "pi4" ],

	30 => [ "lanes_log2" ],
	31 => [ "lanes" ],
	#32 => [ "lane" ],
	33 => [ "waves_log2" ],
	34 => [ "waves" ],
	35 => [ "wave" ],
	36 => [ "streams_log2" ],
	37 => [ "streams" ],
	#38 => [ "stream" ],
	#50 => [ "perf_cnt_en" ],

	RegAliases(
		200+i => ["c$i"] for i in 0:64
	)...,
	RegAliases(
		300+i => ["b$i"] for i in 0:63
	)...,
	300 => [ "lsb" ],
	363 => [ "msb" ],

	1023 => [ "all_one", "all1" ],
	
	# From 1024 are normal registers.
	RegAliases(
		1024+i => ["t$i", "a$(1023-i)"] for i in 0:1023
	)...,
)
register_prefixes_aliases = Dict{String, RegAliases}(
	# Scalar registers.
	"\$" => RegAliases(
		_common_ra...,
		
		# Up to 1024 are special purpose registers.
		#TODO What is this?
		5 => [ "srbp" ], # scalar register base pointer
		6 => [ "vrbp" ], # vector register base pointer

		7 => [ "pc" ], # program counter

		# predicate reg for s and all v streams
		# s writting set to all words. v write specific chunks of bits.
		9 => [ "p" ],
		# If MAX_STREAMS > t_word'length
		10 => [ "p0" ],
		11 => [ "p1" ],

		38 => [ "stream0" ],

		40 => [ "v2s_a" ],
		41 => [ "r_rot_carry" ],

		50 => [ "perf_cnt_en" ],

		# From 1024 are normal registers.
		2047 => [ "ra" ], # return address
	),
	# Vector registers.
	"%" => RegAliases(
		_common_ra...,

		32 => [ "lane" ],
		38 => [ "stream" ],
	),
)

predicates = Dict{UInt32, Vector{String}}(
	0b00 => [ "" ], # execute anyway
	0b01 => [ "a" ], # s: ~$p == 0 aka all($p); v: $p[$stream]
	0b10 => [ "y" ], # s: $p != 0 aka any($p); v: $p[$stream]
	0b11 => [ "n" ], # ~$p == 0; v: !$p[$stream]
)
predicate_aliases = Dict{String, String}(
	""   => "default",
	"a"  => "yes_all", # yes on all predicate
	"y"  => "yes", # yes on any predicates
	"n"  => "no", # no on predicate
)

# Key is format, value is array of instructions with that format.
# d is destination register (left of =),
# s is source register,
# n is number (literal),
# a is address (label).


# - 2b for predicate
# - 8b opcode
# 	- 1b for s/v
# 	- 1b for i64/f64
# 	- 6b i|f opcode
# - 11b dst0
# - 11b src0
# - 32b
#	- 11b src1
#	- 21b
#		- 21b empty
#		or
#		- 11b dst1 | src2
#		- 10b empty
#	or
#	- 32b num | addr
# 2+8+11+11+32 = 64
# Explicit op-codes
#TODO Maybe Tuple of this and parsing format
# d0 = s0, s1
# sincos: d0, d1 = s0
# ld: d0 = [s0, a1]
# st: [s0] = s1
instructions = Dict{String, Vector{String}}(
	"p_2 o_8 0_11 0_11 0_11 0_21" => [ 
		"nop", # alias: s_i64_add $zero = $zero, $zero
	],
	
	"p_2 o_8 d0_11 s0_11 s1_11 0_21" => [
		"s_i64_add",
		"s_i64_sub",
		"s_i64_and",
		"s_i64_or",
		"s_i64_xor",
		"s_i64_shl", # s_i64_shl $d0 = $s0 << $s1
		"s_i64_shr_u",
		"s_i64_shr_s",
		"v_i64_add",

		
		# $d0 = $s0, $s1
		"s_i64_cmp_e",
		"s_i64_cmp_u_l",
		"s_i64_cmp_s_l",
		"s_i64_cmp_u_le",
		"s_i64_cmp_s_le",
		# concat bits and write to spr $p and all 1 to %d0
		# $p = streams[all](%d0 = %s0, %s1)
		"v_i64_cmp_e",
		"v_i64_cmp_u_l",
		"v_i64_cmp_s_l",
		"v_i64_cmp_u_le",
		"v_i64_cmp_s_le",
		
		"s_i64_mul",

		"s_f64_add",
		"v_f64_add",
		"s_f64_sub",
		"v_f64_sub",
		"s_f64_mul",
		"v_f64_mul",

		# $d0 = $s0, $s1
		"s_f64_cmp_e",
		"s_f64_cmp_l",
		"s_f64_cmp_le",
		# concat bits and write to spr $p and all 1 to %d0
		# $p = streams[all](%d0 = %s0, %s1)
		"v_f64_cmp_e",
		"v_f64_cmp_l",
		"v_f64_cmp_le",


		#TODO Check RTL for this.
		"c_d64_to_v", # %d0 = $s0, $s1; stream[$s1].%d0 = $s0
	],
	"p_2 o_8 d0_11 s0_11 0_11 0_21" => [
		"c_d64_v2s_mov", # $d0 = %s0; $d0 = stream[$v2s_a].%s0
		"c_d64_broadcast", # %d0 = $s0; stream[all].%d0 = $s0

		# stream[end:0].%d0 = (stream[end-1:0].%s0, $r_rot_carry)
		# $r_rot_carry = stream[end].%s0
		"c_d64_r_rot_l",
		# stream[end:0].%d0 = ($r_rot_carry, stream[end:1].%s0)
		# $r_rot_carry = stream[0].%s0
		"c_d64_r_rot_r", # %d0 = %s0
	],

	"p_2 o_8 d0_11 s0_11 n1_32" => [
		"s_i64_add_i",
		"v_i64_add_i",
		"s_i64_sub_i",
		"s_i64_and_i",
		"s_i64_or_i",
		"s_i64_xor_i",
		"s_d32_mov_i_hi",
	],
	"p_2 o_8 d0_11 s0_11 a1_32" => [
		"s_d64_ld_i", # $d0 = *($s0 + a1)
		"s_d64_lea", # s_i64_add_i $d0 = $s0, label
	],

	"p_2 o_8 d0_11 s0_11 38_11 0_21" => [
		"v_d64_ld", # %d0 = *($s0 + $stream0)
	],
	
	
	"p_2 o_8  0_11 s0_11 s1_11 0_21" => [
		"s_d64_st", # *$s0 = $s1
	],
	"p_2 o_8 d0_11 s0_11  0_11 0_21" => [
		"s_d64_mov", # alias: s_i64_add $d0 = $s0, $zero
		"v_d64_mov", # alias: v_i64_add %d0 = %s0, %zero
		#TODO r_f64_sum $d0 = sum(%d0)
	],
	
	"p_2 o_8 d0_11 0_11 n1_32" => [
		"s_d32_mov_i_lo", # alias: s_i64_add_i $d0 = $zero, n
		"v_d32_mov_i_lo", # alias: v_i64_add_i %d0 = %zero, n
	],
	
	"p_2 o_8 7_11 0_11 a1_32" => [ 
		"jmp", # alias: s_i64_add_i $pc = $zero, label
	],
	"p_2 o_8 7_11 s0_11 a1_32" => [ 
		"jmp_r", # s_i64_add_i $pc = $s0, label
	],

	"p_2 o_8 d0_11 s0_11  0_11 d1_11  0_10" => [
		"s_f64_sincos_lim",
	],
)

# - means don't care
#- 8b opcode
#	- 1b for s/v
#	- 1b for i64/f64
#	- 1b src1 | num/addr
#	- 5b point opcode
#		- 2b alu
#		- 3b fun
opcodes = Dict{String, String}(
	#                      s i 1 a  fun
	#                      / / / l
	#                      v f n u
	#                            | alu = 00 -> add
	"nop"              => "0 0 0 00 000",
	"s_i64_add"        => "0 0 0 00 000",
	"v_i64_add"        => "1 0 0 00 000",
	"s_d64_mov"        => "0 0 0 00 000",
	"v_d64_mov"        => "1 0 0 00 000",
	"s_i64_add_i"      => "0 0 1 00 000",
	"v_i64_add_i"      => "1 0 1 00 000",
	"s_d32_mov_i_lo"   => "0 0 1 00 000",
	"v_d32_mov_i_lo"   => "1 0 1 00 000",
	"s_d64_lea"        => "0 0 1 00 000",
	"jmp"              => "0 0 1 00 001",
	"jmp_r"            => "0 0 1 00 001",
	"s_d64_st"         => "0 0 0 00 011",
	"v_d64_ld"         => "1 0 0 10 010",
	
	"s_d32_mov_i_hi"   => "0 0 1 00 100",
	
	#                            | alu = 01 fun[2] = 0 -> sub and bitwise
	"s_i64_sub"        => "0 0 0 01 000",
	"s_i64_sub_i"      => "0 0 1 01 000",
	"s_i64_and"        => "0 0 0 01 001",
	"s_i64_or"         => "0 0 0 01 010",
	"s_i64_xor"        => "0 0 0 01 011",
	"s_i64_and_i"      => "0 0 1 01 001",
	"s_i64_or_i"       => "0 0 1 01 010",
	"s_i64_xor_i"      => "0 0 1 01 011",
	#                               | alu = 01 fun[2] = 1 -> shift
	"s_i64_shl"        => "0 0 0 01 100",
	"s_i64_shr_u"      => "0 0 0 01 110",
	"s_i64_shr_s"      => "0 0 0 01 111",
	
	#                            | alu = 10 -> ld/mul
	"s_d64_ld_i"       => "0 0 1 10 010", # use add op
	"s_i64_mul"        => "0 0 0 10 000",
	
	#                            | alu = 11 -> cmp
	"s_i64_cmp_e"      => "0 0 0 11 10-",
	"s_i64_cmp_u_l"    => "0 0 0 11 010",
	"s_i64_cmp_s_l"    => "0 0 0 11 011",
	"s_i64_cmp_u_le"   => "0 0 0 11 110",
	"s_i64_cmp_s_le"   => "0 0 0 11 111",
	"v_i64_cmp_e"      => "1 0 0 11 10-",
	"v_i64_cmp_u_l"    => "1 0 0 11 010",
	"v_i64_cmp_s_l"    => "1 0 0 11 011",
	"v_i64_cmp_u_le"   => "1 0 0 11 110",
	"v_i64_cmp_s_le"   => "1 0 0 11 111",

	#                      s i 1 a  fun
	#                      / / / l
	#                      v f n u
	#                            | alu = 00 -> add
	"s_f64_add"        => "0 1 0 00 000",
	"v_f64_add"        => "1 1 0 00 000",
	#                            | alu = 01 -> sub
	"s_f64_sub"        => "0 1 0 01 000",
	"v_f64_sub"        => "1 1 0 01 000",
	#                            | alu = 10 -> mul_oth
	"s_f64_mul"        => "0 1 0 10 000",
	"v_f64_mul"        => "1 1 0 10 000",
	"s_f64_sincos_lim" => "0 1 0 10 001",
	#TODO exp
	#                            | alu = 11 -> cmp
	"s_f64_cmp_e"      => "0 1 0 11 10-",
	"s_f64_cmp_l"      => "0 1 0 11 01-",
	"s_f64_cmp_le"     => "0 1 0 11 11-",
	"v_f64_cmp_e"      => "1 1 0 11 10-",
	"v_f64_cmp_l"      => "1 1 0 11 01-",
	"v_f64_cmp_le"     => "1 1 0 11 11-",


	"c_d64_v2s_mov"    => "0 0 0 00 101",
	"c_d64_to_v"       => "0 0 0 00 110",
	"c_d64_broadcast"  => "1 0 0 00 111",

	"c_d64_r_rot_l"    => "1 0 0 10 100",
	"c_d64_r_rot_r"    => "1 0 0 10 110",
)

# TODO alu and fun should be rearanged.
# alu=11 aka cmp do not touch.

###############################################################################
