
module Hex_Parser

	export parse_hex_file

	function parse_hex_file(hex_fn::String)
		lines = readlines(hex_fn)
		machine_code = Tuple{UInt32, String}[]
		segm = UInt32(0)
		word_B = nothing
		for line in lines
			bc = parse(UInt8, line[2:3], base = 16)
			la = parse(UInt16, line[4:7], base = 16)
			c = parse(UInt8, line[8:9], base = 16)
			data = line[10:10+bc*2-1]
			cs = line[10+bc*2:10+bc*2+1] #TODO
			
			if c == 4
				# Extended Linear Address
				ua = parse(UInt16, data, base = 16)
				segm = UInt32(ua) << 16
			elseif c == 0
				word = data
				if word_B == nothing
					word_B = bc
				else
					if bc != word_B
						error("Different size words!")
					end
				end
				addr_B = segm | la
				addr = addr_B/word_B
				push!(machine_code, (addr, word))
				# Data
			elseif c == 1
				#TODO EOF
			else
				error("$ifn: Not supported hex code $t")
			end
		end

		return machine_code, word_B
	end


end