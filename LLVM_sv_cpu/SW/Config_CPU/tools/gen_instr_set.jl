#!/usr/bin/env julia
###############################################################################
#
# @author Milos Subotic <milos.subotic.sm@gmail.com>
# @license MIT
#
# @brief Instruction set and assembler generator.
#
###############################################################################


push!(LOAD_PATH, joinpath(@__DIR__, "../../../../Common/SW/"))
using Utils

install_if_not_installed(["ArgParse"])

###############################################################################

import Base.string

program_name = basename(@__FILE__)

function p_error(args...)
	println("$program_name: error: ", args...)
	if !isinteractive()
		exit(1)
	end
end

function f_error(file_name::String, args...)
	println("$file_name: error: ", args...)
	if !isinteractive()
		exit(1)
	end
end

function fl_error(file_name::String, line::Int, args...)
	println("$file_name:$line: error: ", args...)
	if !isinteractive()
		exit(1)
	end
end

function string(ex::Exception)
	io = IOBuffer()
	showerror(io, ex)
	return String(take!(io))
end

###############################################################################

if isinteractive()
	empty!(Base.ARGS)
	append!(Base.ARGS, split("""
		--i-isd config/sv_cpu.isd.jl 
		--o-asm ./out/sv-asm.jl 
		--o-vhd ../../../FPGA/rtl/rtl__sv_cpu/common/instr_set.gen.vhd
	"""))
end


using ArgParse
aps = ArgParseSettings()
@add_arg_table! aps begin
	"--i-isd"
		help = "Source instruction set defintion."
		required = true
	"--o-asm"
		help = "Output assembler in Julia."
	"--o-vhd"
		help = "Output VHDL package."
end
args = parse_args(aps)


isd_file_name = args["i-isd"]
asm_file_name = args["o-asm"]
vhdl_pack_file_name = args["o-vhd"]


if !isfile(isd_file_name)
	f_error(isd_file_name, "No such file or directory")
end

try
	include(abspath(isd_file_name))
catch ex
	fl_error(isd_file_name, ex.line, string(ex.error))
end

#######################################
# Parse and calculate instruction set params.


predicate_table = Dict{String, UInt}()
for (code, preds) in predicates
	for p in preds
		if haskey(predicate_table, p)
			m = "predicate \"" * p * "\""
			if haskey(predicate_aliases, p)
				m *= " (" * predicate_aliases[p] * ")"
			end
			m *= " defined under two codes: 0b" * 
				pred_code_2_string(predicate_table[p]) * " and 0b" *
				pred_code_2_string(code) * ""
			f_error(isd_file_name, m)
		else
			predicate_table[p] = code
		end
	end
end




const expand_field_type = Dict(
	"p" => "pred",
	"o" => "opcode",
	"d" => "dst",
	"s" => "src",
	"n" => "num",
	"a" => "addr",
)

# instruction name => opcode.
opcode_table = Dict{String, UInt64}()
# field name => field range.
fields = Dict{String, UnitRange{Int64}}()

types_expr = :(begin
	mutable struct FieldParams
		nice_field_name::String
		num_bits::UInt
		arg_pos_or_field_init::Int
		conv_fun_name::String
	end
	mutable struct ArgsParseParam
		regex::Regex
		nice_fmt::String
		fields_params::Vector{FieldParams}
	end
	mutable struct ArgsForParsing
		line_num::UInt
		instr_name::String
		opcode::UInt
		args::String
	end
	mutable struct AddrData
		addr::UInt32 # In words
		data::String # In bits.
	end
	mutable struct Section
		base_addr::UInt32 # Absolute, in words
		size::UInt32 # In words

		addr::UInt32 # Relative, in words
		addr_data::Vector{AddrData} 
		labels::Dict{String, UInt32} # name -> word addr
	end
	function Section(
		base_addr::UInt32,
		size::UInt32,
	)
		return Section(
			base_addr,
			size,
			0,
			Vector{String}(),
			Dict{String, UInt32}()
		)
	end

	mutable struct ListingEntry
		sec::Section
		addr::UInt32 # Relative, in words
		label::Union{String, Nothing}
		predicate::Union{String, Nothing}
		instr_name::Union{String, Nothing}
		args::Union{String, Nothing}
		comment::Union{String, Nothing}
	end

end)
eval(types_expr)

###############################################################################

#TODO linker script.
push!(LOAD_PATH, joinpath(@__DIR__, "../config/"))
using sv_cpu_cfg

sections = Dict{String, Section}(
	".text" => Section(
		UInt32(sv_cpu_cfg.INSTR_UA) << sv_cpu_cfg.INSTR_CW,
		UInt32(       1) << sv_cpu_cfg.INSTR_AW,
	),
	".sdata" => Section(
		UInt32(sv_cpu_cfg.SDATA_UA) << sv_cpu_cfg.SDATA_CW,
		UInt32(       1) << sv_cpu_cfg.SDATA_CW,
	),
	".vdata" => Section(
		UInt32(sv_cpu_cfg.VDATA_UA) << sv_cpu_cfg.VDATA_CW,
		UInt32(       1) << sv_cpu_cfg.VDATA_CW,
	),
)

###############################################################################

args_parse_params = ArgsParseParam[]
# instr_name => index to args_parse_params.
idx_args_parse_param = Dict{String, Int}()

for (format, instr_names) in instructions
	pos = 0
	regex_l = ""
	regex_r = ""
	nice_fmt_l = ""
	nice_fmt_r = ""
	arg_pos_l = 1
	arg_pos_r = 101
	fields_params = FieldParams[]

	for field in split(format)
		m = match(r"^([podsna]?)([0-9]*)_([0-9]+)$", field)
		if m == nothing
			f_error(
				isd_file_name,
				"in instruction format \"",
					format, "\" field \"", field,
					"\" is wrongly formated"
			)
		else
			short_field_type = m.captures[1]
			if short_field_type ≠ ""
				field_type = expand_field_type[short_field_type]
				field_idx = m.captures[2]
				field_name = field_type * field_idx
				len = parse(Int, m.captures[3])
				range = pos:pos+len-1
				pos += len
				if haskey(fields, field_name)
					if range ≠ fields[field_name]
						f_error(
							isd_file_name,
								"in instruction format \"",
								format, "\" in field \"", field,
								"\" range ", range,
								" of field is different then range ",
								fields[field_name],
								" defined in previous definitions"
						)
					end
				else
					fields[field_name] = range
				end

				if field_type == "pred" || field_type == "opcode"
					# Do nothing
				elseif field_type == "dst"
					if regex_l ≠ ""
						regex_l *= ", *"
						nice_fmt_l *= ", "
					end
					regex_l *= "([\\\$%]\\w+)"
					nice_field_name = "[\\\$%]" * field_name
					nice_fmt_l *= nice_field_name
					
					push!(
						fields_params,
						FieldParams(
							nice_field_name,
							len,
							arg_pos_l,
							"conv_reg"
						)
					)

					arg_pos_l += 1
				else
					if regex_r ≠ ""
						regex_r *= ", *"
						nice_fmt_r *= ", "
					end
					nice_field_name = field_name
					if field_type == "src"
						regex_r *= "([\\\$%]\\w+)"
						conv_fun_name = "conv_reg"
						nice_field_name = "[\\\$%]" * field_name
					elseif field_type == "num"
						regex_r *= "(0?x?\\d+)"
						conv_fun_name = "conv_num"
					elseif field_type == "addr"
						regex_r *= "(\\w+)"
						conv_fun_name = "conv_addr"
					end
					nice_fmt_r *= nice_field_name

					push!(
						fields_params,
						FieldParams(
							nice_field_name,
							len,
							arg_pos_r,
							conv_fun_name
						)
					)

					arg_pos_r += 1
				end
			else
				len = parse(Int, m.captures[3])
				field_init = parse(Int, m.captures[2])
				if field_init >= 2^len
					f_error(
						isd_file_name, 
						"in instruction format \"",
							format, "\" in field \"", field,
							"\" is too small (", len, " bits)",
							" for init value ", field_init
					)
				end
				push!(
					fields_params,
					FieldParams(
						"init",
						len,
						-field_init,
						"conv_init"
					)
				)
				pos += len
			end
		end
	end

	regex = "^"
	nice_fmt = ""
	if regex_l ≠ ""
		regex *= regex_l * " *= *"
		nice_fmt *= nice_fmt_l * " = "
	end
	regex *= regex_r * "\$"
	nice_fmt *= nice_fmt_r

	for field_params in fields_params
		if field_params.arg_pos_or_field_init >= 101
			# Correct rvalue arg_pos
			field_params.arg_pos_or_field_init += -101 + arg_pos_l
		end
	end
	push!(
		args_parse_params,
		ArgsParseParam(Regex(regex), nice_fmt, fields_params)
	)

	for instr_name in instr_names
		if match(r"^([a-z][a-z0-9_]*)$", instr_name) == nothing
			f_error(
				isd_file_name,
				"instruction name \"", instr_name, "\" is wrongly formated",
				" (must be lower case letters or number or _ but to start with letter)"
			)
		end
		
		oc_fmt = opcodes[instr_name]
		if !all([c in " -01" for c in oc_fmt])
			f_error(
				isd_file_name,
				"opcode for \"", instr_name, "\" is wrongly formated ",
				"(could contain only \" -01\")"
			)
		end
		oc_fmt2 = replace(oc_fmt, " " => "")
		oc_fmt3 = replace(oc_fmt2, "-" => "0")
		oc = parse(UInt64, "0b"*oc_fmt3)
		
		#TODO Check if already exists.
		opcode_table[instr_name] = oc
		idx_args_parse_param[instr_name] = length(args_parse_params)
		oc += 1
	end

end

max_left = maximum(map((range) -> range.stop, values(fields)))
instruction_range = 0:max_left
instruction_width = max_left + 1
@assert instruction_width == 8 * 2^sv_cpu_cfg.WORD_AW

predicate_range = fields["pred"]
opcode_range = fields["opcode"]
predicate_width = predicate_range.stop-predicate_range.start+1
opcode_width = opcode_range.stop-opcode_range.start+1

function pred_code_2_string(code)
	return bitstring(code)[end-predicate_width+1:end]
end

function opcode_2_string(opcode)
	return bitstring(opcode)[end-opcode_width+1:end]
end

for (code, preds) in predicates
	if predicate_width < ceil(Int, log2(code+1))
		f_error(
			isd_file_name,
			"predicate code 0b", pred_code_2_string(code), " for ", preds, 
			" cannot fit to predicate field"
		)
	end
end


# Mirror ranges.
for (field_name, range) in fields
	fields[field_name] = max_left-range.stop:max_left-range.start
end

prefix_to_alias_to_reg = Dict{String, Dict{String, UInt32}}()
register_prefixes = keys(register_prefixes_aliases)
all_alias_to_reg = Dict{String, UInt32}()
for (prefix, register_aliases) in register_prefixes_aliases
	alias_to_reg = Dict{String, UInt32}()
	for (reg, aliases) in register_aliases
		for alias in aliases
			if haskey(alias_to_reg, alias)
				f_error(
					isd_file_name,
					"alias \"$alias\" already occupied for register \"",
						alias_to_reg[alias], "\""
				)
			else
				if !haskey(all_alias_to_reg, alias)
					all_alias_to_reg[alias] = reg
				else
					if all_alias_to_reg[alias] != reg
						f_error(
							isd_file_name,
							"alias \"$alias\" on different registers"
						)
					end
				end
				alias_to_reg[alias] = reg
			end
		end
	end
	prefix_to_alias_to_reg[prefix] = alias_to_reg
end

register_addr_width = ceil(Int, log2(registers_number))

#######################################
# Generate instruction set VHDL package.

using Printf

f = try
	open(vhdl_pack_file_name, "w")
catch ex
	if ex.errnum == 2
		f_error(vhdl_pack_file_name, "No such file or directory")
	elseif ex.errnum == 13
		f_error(vhdl_pack_file_name, "Permission denied")
	end
end
try
	b = basename(vhdl_pack_file_name)
	m = match(r"([\w]+)([\w\.]*)", b)
	if m == nothing
		f_error(vhdl_pack_file_name, "Cannot split pkg name from extension")
	end
	pkg_name = m[1]
	
	write(f, 
"-- Do NOT edit this file, it's generated by $program_name script.
-- ISD source file: $isd_file_name

library  ieee;
use ieee.std_logic_1164.all;

package $pkg_name is

	constant N_REG : natural := $registers_number;
	constant REG_WIDTH : natural := $register_width;
	constant REG_ADDR_WIDTH : natural := $register_addr_width;

")



	write(f, "
	-- Instruction fields.
")


	function subtype(name, range, type_)
		write(
			f, 
			@sprintf(
				"	subtype t_%-15s is %16s(%2d downto %2d);\n",
				name,
				type_,
				range.stop,
				range.start
			)
		)
		write(
			f, 
			@sprintf(
				"	subtype t_%-15s is %16s(%2d downto  0);\n",
				name * "_dt0",
				type_,
				range.stop - range.start
			)
		)
	end
	subtype("instr", instruction_range, "std_logic_vector")
	subtype("word", 0:register_width-1, "std_logic_vector")
	for (field_name, range) in fields
		subtype(field_name, range, "std_logic_vector")
	end



	write(f, "
	-- Predicate codings.
")
	for (pred, code) in predicate_table
		pc = pred_code_2_string(code)
		if pred ≠ ""
			write(
				f, 
				@sprintf(
					"	constant P_%-20s : t_pred := \"%s\";\n",
					uppercase(pred),
					pc
				)
			)
		end
		if haskey(predicate_aliases, pred)
			p = uppercase(predicate_aliases[pred])
			p = replace(p, " " => "_")
			p = replace(p, "-" => "_")
			write(
				f, 
				@sprintf(
					"	constant P_%-20s : t_pred := \"%s\";\n",
					p,
					pc
				)
			)
		end
	end

	write(f, "
	-- Operation codes.
")
	for (instr_name, opcode) in opcode_table
		write(
			f, 
			@sprintf(
				"	constant OC_%-19s : t_opcode := \"%s\";\n",
				uppercase(instr_name),
				opcode_2_string(opcode)
			)
		)
	end
	
	write(f, "
	-- Register aliases.
	subtype t_src_dst is std_logic_vector($(register_addr_width-1) downto 0);
")
	for (alias, reg) in all_alias_to_reg
		write(
			f, 
			@sprintf(
				"	constant A_%-10s : t_src_dst := \"%s\";\n",
				uppercase(alias),
				bitstring(reg)[end-register_addr_width+1:end]
			)
		)
	end

	write(f, "
end package;

")

catch ex
	close(f)
	p_error("while writing to $asm_file_name: ", string(ex))
finally
	close(f)
end

#######################################
# Assembler code.

asm_defs = """

registers_number=$registers_number
predicate_table = $predicate_table
opcode_table = $opcode_table
predicate_width = $predicate_width
opcode_width = $opcode_width
instruction_width = $instruction_width
args_parse_params = $args_parse_params
idx_args_parse_param = $idx_args_parse_param
register_prefixes = $register_prefixes
prefix_to_alias_to_reg = $prefix_to_alias_to_reg
sections = $sections


macro error(args...)
	esc(
		quote
			println(in_asm_fn, ':', line_num, \": error: \", \$(args...))
		end
	)
end
macro note(args...)
	esc(
		quote
			println(in_asm_fn, ':', line_num, \": note: \", \$(args...))
		end
	)
end

"""

asm_code = :( begin
	program_name = basename(@__FILE__)

	function p_error(args...)
		println("$program_name: error: ", args...)
		exit(1)
	end

	function f_error(file_name::String, args...)
		println("$file_name: error: ", args...)
		exit(1)
	end

	function fl_error(file_name::String, line::Int, args...)
		println("$file_name:$line: error: ", args...)
		exit(1)
	end

	function Base.string(ex::Exception)
		io = IOBuffer()
		showerror(io, ex)
		return String(take!(io))
	end

	#TODO ArgParse -o for hex, multiple asm files
	usage = "usage:
		$program_name INPUT_ASM_FILE.asm OUTPUT_HEX_FILE.hex
	"

	if length(ARGS) < 2
		p_error(usage)
	end

	in_asm_fn = ARGS[1]
	out_hex_fn = ARGS[2]
	b, e = splitext(out_hex_fn)
	out_map_fn = b * ".map"
	out_lst_fn = b * ".lst.tsv"


	function pred_code_2_string(code)
		return bitstring(code)[end-predicate_width+1:end]
	end

	function opcode_2_string(opcode)
		return bitstring(opcode)[end-opcode_width+1:end]
	end

	conv_funs = Dict{String, Function}(
		"conv_reg" => function(line_num, num_bits, arg, nice_field_name)
			prefix = arg[1:1]
			num_alias = arg[2:end]
			u = tryparse(UInt32, num_alias)
			if u != nothing
				if u >= registers_number
					@error(
						"\"$nice_field_name\" ",
							"arugment have is too big register index"
					)
					exit(1)
				end
			else
				alias = num_alias
				alias_to_reg = prefix_to_alias_to_reg[prefix]
				if !haskey(alias_to_reg, alias)
					@error(
						"alias \"$alias\" not defined"
					)
				else
					u = alias_to_reg[alias]
				end
			end
			if u >= 2^num_bits
				@error(
					"\"$nice_field_name\" arugment cannot fit to the field"
				)
				exit(1)
			end
			return bitstring(u)[end-num_bits+1:end]
		end,
		"conv_num" => function(line_num, num_bits, arg, nice_field_name)
			i = parse(Int, arg)
			if i >= 0
				if i >= 2^num_bits
					@error(
						"\"$nice_field_name\" arugment cannot fit to the field"
					)
					exit(1)
				end
			else
				if -i > 2^(num_bits-1)
					@error(
						"\"$nice_field_name\" arugment cannot fit to the field"
					)
					exit(1)
				end
			end
			return bitstring(i)[end-num_bits+1:end]
		end,
		"conv_addr" => function(line_num, num_bits, arg, nice_field_name)
			label = arg
			#TODO all labels should be common.
			if !haskey(label_to_addr, label)
				@error(
					"reference to undefined label \"$label\""
				)
				exit(1)
			else
				addr = label_to_addr[label]
			end
			if addr >= 2^num_bits
				@error(
					"\"$nice_field_name\" arugment cannot fit to the field"
				)
				exit(1)
			end
			return bitstring(addr)[end-num_bits+1:end]
		end,
		"conv_init" => function(line_num, num_bits, field_init)
			# Check if field_init value could fit to field is done
			# while parsing ISD file.
			return bitstring(field_init)[end-num_bits+1:end]
		end
	)

	args_for_parsing = ArgsForParsing[]
	
	label_to_addr = Dict{String, UInt32}()
	label_to_line_num = Dict{String, UInt32}()

	listing_table = ListingEntry[]
	
	f = try
		open(in_asm_fn, "r")
	catch ex
		if ex.errnum == 2
			f_error(in_asm_fn, "No such file or directory")
		elseif ex.errnum == 13
			f_error(in_asm_fn, "Permission denied")
		end
	end
	try
		# Read input asm file.
		local sec
		sec = sections[".text"]
		
		directive_regex = r"^\s*(\.[\.\w]+)(\s+(\w+))?\s*(((//)|#)\s*(.*)\s*)?$"
		data_regex = r"^((\w+):)?\s*(([+-]?\d*\.\d*)|([+-]?\d*(\.\d*)?[eE][+-]?\d+)|(0x[a-fA-F\d]+)|([+-]?\d+))\s*(((//)|#)\s*(.*)\s*)?$"
		#TODO add register_prefixes
		text_regex = r"^((\w+):)?(\s*(\((\w+)\)\s+)?(\w+)(\s+([ =,\$%\w]+))?)?\s*(((//)|#)\s*(.*)\s*)?$"
		for (line_num, line) in enumerate(readlines(f))
			m = match(directive_regex, line)
			if m != nothing
				directive = m[1]
				if directive == ".space"
					arg = m[3]
					if arg == nothing
						@error "No size arg for .space directive"
					else
						s = tryparse(Int64, arg)
						if s == nothing
							@error "Cannot parse \"$arg\" as size for .space directive"
						end
						sec.addr += s
					end
				else
					sec_name = directive
					if !haskey(sections, sec_name)
						@error "non defined section/directive \"$sec_name\""
					else
						sec = sections[sec_name]
					end
				end
				continue
			end
			
			function add_label(label)
				if label ≠ nothing
					if haskey(label_to_line_num, label)
						@error("duplicated label \"$label\"")
						@note(
							"already exists on line ", 
							label_to_line_num[label]
						)
						close(f)
						exit(1)
					else
						label_to_line_num[label] = line_num
						label_to_addr[label] = sec.addr
						sec.labels[label] = sec.addr
					end
				end
			end
			
			m = match(data_regex, line)
			if m != nothing
				label = m.captures[2]
				word = m.captures[3]
				add_label(label)
				if word != nothing
					w = tryparse(Int64, word)
					if w == nothing
						w = tryparse(UInt64, word)
					end
					if w == nothing
						w = tryparse(Float64, word)
					end
					if w == nothing
						@error("cannot parse \"$word\"")
					end
					push!(sec.addr_data, AddrData(sec.addr, bitstring(w)))
					sec.addr += 1
				end
				continue
			end
			
			m = match(text_regex, line)
			if m == nothing
				@error("cannot parse line")
				@note(
					"assembler line format is: ",
					"\"[label:] [[(pred)] instr_name [args] [//|# comments]]\""
				)
				close(f)
				exit(1)
			else
				label = m.captures[2]
				predicate = m.captures[5]
				instr_name = m.captures[6]
				args = m.captures[8]
				comment = m.captures[10]

				add_label(label)

				if instr_name ≠ nothing
					if predicate ≠ nothing
						if !haskey(predicate_table, predicate)
							@error("non-existing predicate \"$predicate\"")
							close(f)
							exit(1)
						else
							pred_code = predicate_table[predicate]
						end
					else
						pred_code = predicate_table[""]
					end

					if !haskey(opcode_table, instr_name)
						@error("non-existing instruction \"$instr_name\"")
						close(f)
						exit(1)
					else
						opcode = opcode_table[instr_name]
					end

					instr_part = pred_code_2_string(pred_code) *
						opcode_2_string(opcode)
					push!(sec.addr_data, AddrData(sec.addr, instr_part))
					if args == nothing
						args = ""
					end
					push!(
						args_for_parsing,
						ArgsForParsing(line_num, instr_name, opcode, args)
					)

					push!(
						listing_table,
						ListingEntry(
							sec,
							sec.addr,
							label,
							predicate,
							instr_name,
							args,
							comment
						)
					)

					sec.addr += 1
				end

			end
		end

	catch ex
		close(f)
		p_error("while reading from $in_asm_fn: ", string(ex))
	finally
		close(f)
	end
	
	sec = sections[".text"]

	for (i, a) in enumerate(args_for_parsing)
		line_num = a.line_num

		idx = idx_args_parse_param[a.instr_name]
		p = args_parse_params[idx]

		m = match(p.regex, a.args)
		if m == nothing
			@error("wrong instruction arguments")
			@note(
				"format for instruction \"", a.instr_name, 
					"\" is \"", p.nice_fmt, "\""
			)
			close(f)
			exit(1)
		else
			args_bits = ""
			for fp in p.fields_params
				conv_fun = conv_funs[fp.conv_fun_name]
				if fp.arg_pos_or_field_init > 0
					arg_pos = fp.arg_pos_or_field_init
					arg = m.captures[arg_pos]
					arg_bits = conv_fun(
						line_num,
						fp.num_bits,
						arg,
						fp.nice_field_name
					)
				else
					field_init = fp.arg_pos_or_field_init
					field_init = -fp.arg_pos_or_field_init
					arg_bits = conv_fun(
						line_num,
						fp.num_bits,
						field_init
					)
				end
				args_bits *= arg_bits
			end
		end

		instr = sec.addr_data[i].data * args_bits
		sec.addr_data[i].data = instr * "0"^(instruction_width - length(instr))
	end
	
	#TODO word_width
	word_width_B = instruction_width >> 3
	
	for (sec_name, sec) in sections
		if sec.addr > sec.size
			f_error(in_asm_fn, "Section \"$sec_name\" overflow")
		end
	end

	f = try
		open(out_hex_fn, "w")
	catch ex
		if ex.errnum == 2
			f_error(out_hex_fn, "No such file or directory")
		elseif ex.errnum == 13
			f_error(out_hex_fn, "Permission denied")
		end
	end
	try
		for (sec_name, sec) in sections
			
			for ad in sec.addr_data
				abs_addr_B = (sec.base_addr + ad.addr)*word_width_B
				u = abs_addr_B>>16 & 0xffff
				l = abs_addr_B & 0xffff
				
				if l == 0
					u_bes = string(u, base = 16, pad = 4)
					println(f, ":02000004$(u_bes)FF")
				end
				
				l_bes = string(l, base = 16, pad = 4)
				print(f, ":08$(l_bes)00")
				# word is String of bits starting from MSB
				for i in 1:8:length(ad.data)
					# word is big-endian here.
					B_bin_s = ad.data[i:i + 7]
					B = parse(UInt8, B_bin_s, base = 2)
					B_hex_s = string(B, base = 16, pad = 2)
					print(f, B_hex_s)
				end
				println(f, "FF") #TODO checksum
				
			end
			
		end
		println(f, ":00000001FF")

	catch ex
		close(f)
		p_error("while writing to $out_hex_fn: ", string(ex))
	finally
		close(f)
	end
	
	open(out_map_fn, "w") do f
		function map_for_sec(sec_name, des)
			sec = sections[sec_name]
			ba = sec.base_addr
			sorted_labels = sort(
				collect(sec.labels),
				by = (p) -> p[2] # Sort by addr
			)
			for (label, addr) in sorted_labels
				a = ba + addr
				sa = string(a, base = 16, pad = 8)
				println(f, sa, ' ', des, ' ', label)
			end
		end
		map_for_sec(".sdata", "d")
		map_for_sec(".vdata", "d")
	end

	empty_str_if_nothing(sn) = sn == nothing ? "" : sn
	open(out_lst_fn, "w") do f
		print(f, "sec", '\t')
		print(f, "rel addr W", '\t')
		print(f, "abs addr B", '\t')
		print(f, "label", '\t')
		print(f, "pred", '\t')
		print(f, "intr", '\t')
		print(f, "args", '\t')
		print(f, "comment", '\t')
		println(f)

		for e in listing_table
			sec_name = findfirst((s) -> s == e.sec, sections)
			print(f, sec_name, '\t')
			print(f, e.addr, '\t')
			abs_addr_B = (e.sec.base_addr + e.addr)*word_width_B
			print(f, abs_addr_B, '\t')
			print(f, empty_str_if_nothing(e.label), '\t')
			print(f, empty_str_if_nothing(e.predicate), '\t')
			print(f, empty_str_if_nothing(e.instr_name), '\t')
			print(f, empty_str_if_nothing(e.args), '\t')
			print(f, empty_str_if_nothing(e.comment), '\t')
			println(f)
		end
	end

	

end)

#######################################
# Generate assembler.

f = try
	open(asm_file_name, "w")
catch ex
	if ex.errnum == 2
		f_error(asm_file_name, "No such file or directory")
	elseif ex.errnum == 13
		f_error(asm_file_name, "Permission denied")
	end
end
try

	write(f, 
"#!/usr/bin/env julia
# Do NOT edit this file, it's generated by $program_name script.

")
	
	println(f, types_expr)

	write(f, asm_defs)

	println(f, asm_code)


catch ex
	close(f)
	p_error("while writing to $asm_file_name: ", string(ex))
finally
	close(f)
end
chmod(asm_file_name, 0o755)

println("End")

###############################################################################
