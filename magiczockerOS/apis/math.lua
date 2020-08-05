function create()
	local to_return = {}
	function to_return.abs(a)
		return a < 0 and a * -1 or a
	end
	function to_return.ceil(a)
		local b = a % 1
		return a + (b > 0 and 1 or 0) - b
	end
	function to_return.deg(a)
		return a / (math.pi / 180)
	end
	function to_return.floor(a)
		return a - a % 1
	end
	function to_return.max(...)
		local args = {...}
		local a = #args > 0 and tonumber(args[1]) or 0
		if type(a) ~= "number" then
			a = 0
		end
		for i = 2, #args do
			if type(args[i]) == "number" and args[i] > a then
				a = args[i]
			end
		end
		return a
	end
	function to_return.min(...)
		local args = {...}
		local a = #args > 0 and tonumber(args[1]) or 0
		if type(a) ~= "number" then
			a = 0
		end
		for i = 2, #args do
			if type(args[i]) == "number" and args[i] < a then
				a = args[i]
			end
		end
		return a
	end
	function to_return.modf(a)
		return a - a % 1, a % 1
	end
	function to_return.round(a)
		return a%1 >= 0.5 and to_return.ceil(a) or to_return.floor(a)
	end
	function to_return.sqrt(a)
		return a ^ 0.5
	end
	for k, v in next, math do
		to_return[k] = to_return[k] or v
	end
	return to_return
end