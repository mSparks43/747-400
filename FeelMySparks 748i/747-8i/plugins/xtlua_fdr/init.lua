-- Wanna use STP with XLua?  Copy StackTracePlus.lua to be next to init.lua in the same folder
-- https://github.com/ignacio/StackTracePlus

-- Grab STP conditionally, do not squawk if it is missing.
--if pcall(
--	function()
--		local STP_chunk = XLuaGetCode("../../StackTracePlus.lua")
--		local STP = STP_chunk()
--		debug.traceback = STP.stacktrace
--	end)
--then
--	print("Using STP as debugger.")
--end



function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--------------------------------------------------------------------------------
-- DATAREF LUA GLUE
--------------------------------------------------------------------------------
-- This code creates property objects (or MT-enhanced tables) for arrays that
-- let authors work with 


function dref_array_read(table,key)
	idx = tonumber(key)
	if idx == nil then
		return nil
	end
	return XTLuaGetArray(table.dref,idx)
end

function dref_array_write(table,key,value)
	idx = tonumber(key)
	if idx == nil then
		return
	end
	XTLuaSetArray(table.dref,idx,value)
end

function wrap_dref_array(in_dref, dim)
	dr = {
		dref = in_dref,
		len = dim
	}
	mt = { __index = dref_array_read, __newindex = dref_array_write }
	setmetatable(dr,mt)
	return dr
end



function wrap_dref_number(in_dref)
	return {
		__get = function(self)
			return XTLuaGetNumber(self.dref)
		end,
		__set = function(self,v)
			XTLuaSetNumber(self.dref,v)
		end,
		dref = in_dref
	}
end

function wrap_dref_string(in_dref)
	return {
		__get = function(self)
			return XTLuaGetString(self.dref)
		end,
		__set = function(self,v)
			XTLuaSetString(self.dref,v)
		end,
		dref = in_dref
	}
end



function wrap_dref_any_deferred(in_dref)
	--[[
		This function builds a property object for a dataref where we do not
		know the type of dataref at wrapping time.  The callbacks inspect the 
		dataref on the fly and call the right callbacks basde on what they find.
		
		One special case: if we have an array we need to return a table so the client
		can then run the [] operator on the table.  We cache our table object after
		the first time we find it in "arr" and if askesd again we can just return it
		immediately and not leak out a huge number of tables to be GCed later.
		
		Right now I only expose the table in the read function, because in theory
		dr[4] = 5
		shows up as a "read" of DR in the global namespace - the write happens when the [4] = 5
		is applied to the subtable.  If we wake up one day and blow up in the write CB, 
		maybe I have reasoned wrong, but in the test code we write into the anonymous 
		dataref and it works.
	--]]
	return {
		__get = function(self)
			if self.arr ~= nil then
				return self.arr
			end
			t = XTLuaGetDataRefType(self.dref)
			b = string.find(t,"%[")
			if b ~= nil then
				dim = tonumber(string.sub(t,b+1,-2))
				if dim == nil then
					return nil
				end
				self.arr = wrap_dref_array(self.dref,dim)
				return self.arr
			end
			if t == "string" then
				return XTLuaGetString(self.dref)
			elseif t == "number" then
				return XTLuaGetNumber(self.dref)
			else
				return 0.0
			end			
		end,
		__set = function(self,v)
			if self.arr ~= nil then
				return self.arr
			end
			t = XTLuaGetDataRefType(self.dref)
			if t == "string" then
				return XTLuaSetString(self.dref,v)
			elseif t == "number" then
				return XTLuaSetNumber(self.dref,v)
			else
				return 0.0
				--error("Previously unresolved dataref is being written to but is an array or is still undefined.")
			end			
		end,	
		dref = in_dref,
		arr = nil,
	}	
end
	
function wrap_dref_any(dref,t)	
	b = string.find(t,"%[")
	if b ~= nil then
		dim = tonumber(string.sub(t,b+1,-2))
		if dim == nil then
			return nil
		end
		return wrap_dref_array(dref,dim)
	end
	if t == "string" then
		return wrap_dref_string(dref)
	end
	if t == "number" then
		return wrap_dref_number(dref)
	end
	return wrap_dref_any_deferred(dref)
end

function find_dataref(name)	
	dref = XTLuaFindDataRef(name)
	t = XTLuaGetDataRefType(dref)
	return wrap_dref_any(dref,t)
end

function create_dataref(name,type,notifier)
  error("create_dataref unsupported - use init script")
	--[[if notifier == nil then
		dref = XLuaCreateDataRef(name,type,"no",nil)
	else
		dref = XLuaCreateDataRef(name,type,"yes",notifier)
	end
	return wrap_dref_any(dref,type)
  ]]
end

--------------------------------------------------------------------------------
-- COMMAND LUA GLUE
--------------------------------------------------------------------------------

function make_command_obj(in_cmd, in_name)
	return { 
		start = function(self)
			if self.cmd == nil then
				self.cmd = XTLuaFindCommand(self.name)
				if self.cmd == nil then
					error("Unable to find command:"..name)
				end
			end
			XTLuaCommandStart(self.cmd)
		end,
		stop = function(self)
			if self.cmd == nil then
				self.cmd = XTLuaFindCommand(self.name)
				if self.cmd == nil then
					error("Unable to find command:"..name)
				end
			end
			XTLuaCommandStop(self.cmd)
		end,
		once = function(self)
			if self.cmd == nil then
				self.cmd = XTLuaFindCommand(self.name)
				if self.cmd == nil then
					error("Unable to find command:"..name)
				end
			end
			XTLuaCommandOnce(self.cmd)
		end,
		cmd = in_cmd,
		name = in_name
	}
end

function find_command(name)
	c = XTLuaFindCommand(name)
	return make_command_obj(c,name)
end

function replace_command(name, func)
	c = XTLuaFindCommand(name)
	XTLuaReplaceCommand(c,func)
	return make_command_obj(c)
end	

function wrap_command(name, before, after)
	c = XTLuaFindCommand(name)
	XTLuaWrapCommand(c,before,after)
	return make_command_obj(c)
end

--------------------------------------------------------------------------------
-- TIMER UTILITIES
--------------------------------------------------------------------------------

function run_timer(func,delay,rep)
	tobj = all_timers[func]
	if tobj == nil then
		tobj = XTLuaCreateTimer(func)
		all_timers[func] = tobj
	end
	XTLuaRunTimer(tobj,delay,rep)
end

function stop_timer(func)
	tobj = all_timers[func]
	if tobj ~= nil then
		XTLuaRunTimer(tobj, -1.0, -1.0)
	end
end

function is_timer_scheduled(func)
	tobj = all_timers[func]
	if tobj == nil then
		return false
	end
	return XTLuaIsTimerScheduled(tobj)
end

function run_at_interval(func, interval)
	run_timer(func,interval,interval)
end

function run_after_time(func,delay)
	run_timer(func,delay,-1.0)
end

--------------------------------------------------------------------------------
-- NAMESPACE UTILITIES
--------------------------------------------------------------------------------
-- These put all script actions in a private namespace with meta-table 
-- enhancements.

function seems_like_prop(p)
	if type(p) ~= "table" then
		return false
	end
	gfunc = rawget(p,"__get")
	sfunc = rawget(p,"__set")
	if type(gfunc) ~= "function" then
		return false
	end
	if type(sfunc) ~= "function" then
		return false
	end
	return true
end

function seems_like_object(p)
	if type(p) ~= "table" then
		return false
	end
	if getmetatable(p) ~= nil	 then
		return true
	end
	for k,vv in pairs(p) do
		if type(vv) == "function" then
			return true
		end
	end
end


function namespace_ipairs(table, i)
	local function namespace_iter(table, i)
		i = i + 1
		ftable = rawget(table,'functions')
		vtable = rawget(table,'values')
		local fv = ftable[i]
		if fv ~= nil then
			return i,fv.__get(fv)
		else
			local vv = vtable[i]
			if vv ~= nil then
				return i,vv
			end
		end
	end
	return namespace_iter, table, 0
end

function namespace_len(table)
	local count = 0
	for _ in namespace_ipairs(table) do count = count + 1 end
	return count
end
  

function namespace_pairs(table, key, value)
	local function namespace_next(table, index)
		ftable = rawget(table,'functions')
		vtable = rawget(table,'values')
		if index == nil then
			idx_f,key_f = next(ftable, nil)
			if idx_f == nil then
				idx_v,key_v = next(vtable, nil)
				return idx_v,key_v
			else
				return idx_f,key_f.__get(key_f)
			end
		else
			if ftable[index] ~= nil then
				idx_f,key_f = next(ftable,index)
				if idx_f == nil then
					return next(vtable, nil)
				else
					return idx_f,key_f.__get(key_f)
				end
			else
				return next(vtable, index)
			end
		end
	end

	return namespace_next, table, nil
end

function namespace_write(table, key, value)
	--print("Namespace write of "..key)
	ftable = rawget(table,'functions')
	vtable = rawget(table,'values')

	func = ftable[key]
	if func ~= nil then
		func.__set(func,value)
	else
		if seems_like_prop(value) then
			ftable[key] = value
		else
			if not seems_like_object(value) and type(value) == "table" and getmetatable(value) == nil then
				--print("Bare table wrap for "..key)
				v = {
					functions = {},
					values = {},
					parent = nil
				}
				for k,vv in pairs(value) do
					if seems_like_prop(vv) then
						v.functions[k] = vv						
					else
						v.values[k] = vv
					end
				end
				setmetatable(v,getmetatable(table))
				vtable[key] = v
			else
				--print("copy for "..key)			
				vtable[key] = value
			end
		end
	end
end

function namespace_read(table,key)
	ftable = rawget(table,'functions')
	vtable = rawget(table,'values')
	func = ftable[key]
	if func ~= nil then
		return func.__get(func)
	end
	var = vtable[key]
	if var ~= nil then
		return var
	end
	if table.parent ~= nil then
		return table.parent[key]
	end
	return nil
end

function create_namespace()
	ret = { 
		functions = {}, 
		values = {},
		create_prop = function(self,name, func)
			self.functions[name] = func
		end,
		parent = _G
	}
	-- TODO: use __len operator to restore # for Jim
	-- TODO: look at __pairs, __ipairs support
	mt = { __index = namespace_read, __newindex = namespace_write, __pairs = namespace_pairs, __ipairs = namespace_ipairs, __len = namespace_len }
	setmetatable(ret,mt)
	return ret
end

-- Build a custom-built closure replacement for dofile that uses get-path to
-- find same-dir scripts and does a setfenv to our NS
function get_run_file_in_namespace(ns)
	return function(fname)
		chunk = XLuaGetCode(fname)
		if chunk == nil then
			print("Error: unable to load the file '"..full_path.."' for dofile.")
			print(debug.traceback())
			print("")
		else
			setfenv(chunk,ns)
			chunk()
		end
	end
end

--------------------------------------------------------------------------------

function run_module_in_namespace(fn)
	n = create_namespace()
	all_timers = { }
	
	n.make_prop = function(name,func)
		n:create_prop(name,func)
	end
	
	n.find_dataref = find_dataref
	n.create_command = create_command
	n.find_command = find_command
	n.wrap_command = wrap_command
	n.replace_command = replace_command
	
	n.run_timer = run_timer
	n.stop_timer = stop_timer
	n.is_timer_scheduled = is_timer_scheduled
	n.run_after_time = run_after_time
	n.run_at_interval = run_at_interval
	n.dofile = get_run_file_in_namespace(n)
	
	setfenv(fn,n)
	fn()
end

function setup_callback_var(var_name,var_value)
	n[var_name] = var_value
end

function do_callout(fname)
	func=n[fname]
	if func ~= nil then
		if STP ~= nil then
			STP.add_known_function(func, fname)
		end
		func()
	end
end
