-- magiczockerOS - Copyright by Julian Kriete 2016-2026

-- Define global variables as local
local fs = _G.fs
local t = _G.type

-- Variables
local p = {}
local minDepth = 3
local functions = {
	'attributes', -- added in CC:T 1.87.0
	'delete', -- added in CC 1.0
	'exists', -- added in CC 1.0
	'find', -- added in CC 1.6 through fs.lua
	'getCapacity', -- added in CC:T 1.87.0
	'getDir', -- added in CC 1.63
	'getDrive',
	'getFreeSpace', -- added in CC 1.4
	'getName', -- added in CC 1.2
	'getSize', -- added in CC 1.3
	'isDir', -- added in CC 1.0
	'isDriveRoot', -- added in CC:T 1.87.0 through fs.lua
	'isReadOnly', -- added in CC 1.0
	'makeDir' -- added in CC 1.0
}

-- Functions
local function fix( user, sPath )
	local path = { 'magiczockerOS', 'users', user }
	for word in (sPath or ''):gmatch('([^/]+)') do
		if word == '..' then
			table.remove( path )
			if #path < minDepth then
				return nil
			end
		elseif word == '.' or word == '' then
			-- ignore
		else
			table.insert( path, word )
		end
	end
	if path[ 4 ] == 'rom' then
		table.remove( path, 1 )
		table.remove( path, 1 )
		table.remove( path, 1 )
	end
	return table.concat( path, '/' )
end

p.new = function( user )
	local out = { -- define functions added in CC 1.0
		combine = function( ... )
			local a = { ... }
			return fix( user, table.concat( a, '/' ) )
		end,
		copy = function( path, dest )
			return fs.copy( fix( user, path ), fix( user, dest ) )
		end,
		list = function( path )
			local f = fix( user, path )
			local l = fs.list( f )
			if f == ('magiczockerOS/users/%s'):format( user ) then
				table.insert( l, 'rom' )
			end
			return l
		end,
		move = function( path, dest )
			return fs.move( fix( user, path ), fix( user, dest ) )
		end,
		open = function( path, mode )
			return fs.open( fix( user, path ), mode )
		end
	}

	for k, v in ipairs( functions ) do
		if t( fs[ v ] ) == 'function' then
			out[ v ] = function( path )
				return fs[ v ]( fix( user, path ) )
			end
		end
	end

	if t( fs.complete ) == 'function' then -- added in CC 1.74 through fs.lua
		out.complete = function( sPath, sLocation, bIncludeFiles, bIncludeDirs )
			return fs.complete( sPath, fix( user, sLocation, bIncludeFiles, bIncludeDirs ) )
		end
	end
	return out
end

return p