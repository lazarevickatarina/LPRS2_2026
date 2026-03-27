#!/usr/bin/env julia
###############################################################################

push!(LOAD_PATH, joinpath(@__DIR__, "../../../../Common/SW/"))
using Utils

install_if_not_installed(["ArgParse"])
using ArgParse
using Printf

###############################################################################

if isinteractive()
	empty!(Base.ARGS)
	append!(Base.ARGS, split("""
		--i-ihex build/st.hex
		--o-c-h ../../FPGA/FW/test__cpu/01_exec_hardcoded/src/machine_code.gen.h
	"""))
end

###############################################################################

aps = ArgParseSettings()
@add_arg_table! aps begin
	"--i-ihex"
		help = "HEX file."
		required = true
	"--o-vhd-pkg"
		help = "Destination package."
	"--o-vhd-rom"
		help = "Destination architecture."
	"--o-c-h"
		help = "Destination C."
end
args = parse_args(aps)

###############################################################################


push!(LOAD_PATH, @__DIR__)
using Hex_Parser

ifn = args["i-ihex"]
name, _ = splitext(basename(ifn))

# Hex
machine_code, word_B = parse_hex_file(ifn)


word_b = word_B*8
N_words = length(machine_code)

ofn = args["o-vhd-pkg"]
if ofn != nothing
	b = basename(ofn)
	m = match(r"([\w]+)([\w\.]*)", b)
	if m == nothing
		error("$ofn: Cannot split pkg name from extension")
	end
	pkg_name = m[1]
	open(ofn, "w") do f
		println(f, "")
		println(f, "")
		println(f, "
-- Generated from $ifn
-- name: $name

library  ieee;
use ieee.std_logic_1164.all;

package $pkg_name is
	type t_addr_word is record
		addr : std_logic_vector(31 downto 0);
		word : std_logic_vector($(word_b-1) downto 0);
	end record;
	
	type t_machine_code is array (0 to $(N_words-1)) of t_addr_word;
	constant machine_code : t_machine_code := ("
		)
		for (i, (addr, word)) in enumerate(machine_code)
			idx_s = @sprintf("%9d", i-1)
			addr_hex_s = string(addr, base = 16, pad = 8)
			word_hex_s = word
			println(f,
"		$idx_s => (x\"$addr_hex_s\", x\"$word_hex_s\"),"
			)
		end
		
		
		write(f, 
"		others => ((others => '0'), (others => '0')) -- write to magic.
	);
end package;

")
	end
end


ofn = args["o-c-h"]
if ofn != nothing
	open(ofn, "w") do f
		println(f, """
// Generated from $ifn
// name: $name

#pragma once

typedef struct {
	u32 addr;
	u64 word;
} t_addr_word;

static t_addr_word machine_code[] = {""")
		for (i, (addr, word)) in enumerate(machine_code)
			idx_s = @sprintf("%9d", i-1)
			addr_hex_s = string(addr, base = 16, pad = 8)
			word_hex_s = word
			println(f, "	{0x$addr_hex_s, 0x$word_hex_s},")
		end
println(f, """
};
""")


println(f, "")
		
	end
end


println("End")
