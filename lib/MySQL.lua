local promise = promise
local Await = Citizen.Await
local GetCurrentResourceName = GetCurrentResourceName()
local GetResourceState = GetResourceState

local function await(fn, query, parameters)
	local p = promise.new()
	fn(nil, query, parameters, function(result, error)
		if error then
			return p:reject(error)
		end

		p:resolve(result)
	end, GetCurrentResourceName, true)
	return Await(p)
end

local type = type
local queryStore = {}

local function safeArgs(query, parameters, cb, transaction)
	local queryType = type(query)

	if queryType == 'number' then
		query = queryStore[query]
	elseif transaction then
		if queryType ~= 'table' then
			error(("First argument expected table, received '%s'"):format(query))
		end
	elseif queryType ~= 'string' then
		error(("First argument expected string, received '%s'"):format(query))
	end

	if parameters then
		local paramType = type(parameters)

		if paramType ~= 'table' and paramType ~= 'function' then
			error(("Second argument expected table or function, received '%s'"):format(parameters))
		end

		if paramType == 'function' or parameters.__cfx_functionReference then
			cb = parameters
			parameters = nil
		end
	end

	if cb and parameters then
		local cbType = type(cb)

		if cbType ~= 'function' and (cbType == 'table' and not cb.__cfx_functionReference) then
			error(("Third argument expected function, received '%s'"):format(cb))
		end
	end

	return query, parameters, cb
end

local oxmysql = exports.oxmysql

local mysql_method_mt = {
	__call = function(self, query, parameters, cb)
		query, parameters, cb = safeArgs(query, parameters, cb, self.method == 'transaction')
		return oxmysql[self.method](nil, query, parameters, cb, GetCurrentResourceName, false)
	end
}

local MySQL = setmetatable(MySQL or {}, {
	__index = function(_, index)
		return function(...)
			return oxmysql[index](nil, ...)
		end
	end
})

for _, method in pairs({
	'scalar', 'single', 'query', 'insert', 'update', 'prepare', 'transaction', 'rawExecute',
}) do
	MySQL[method] = setmetatable({
		method = method,
		await = function(query, parameters)
			query, parameters = safeArgs(query, parameters, nil, method == 'transaction')
			return await(oxmysql[method], query, parameters)
		end
	}, mysql_method_mt)
end

local alias = {
	fetchAll = 'query',
	fetchScalar = 'scalar',
	fetchSingle = 'single',
	insert = 'insert',
	execute = 'update',
	transaction = 'transaction',
	prepare = 'prepare'
}

local alias_mt = {
	__index = function(self, key)
		if alias[key] then
			local method = MySQL[alias[key]]
			MySQL.Async[key] = method
			MySQL.Sync[key] = method.await
			alias[key] = nil
			return self[key]
		end
	end
}

local function addStore(query, cb)
	assert(type(query) == 'string', 'The SQL Query must be a string')

	local storeN = #queryStore + 1
	queryStore[storeN] = query

	return cb and cb(storeN) or storeN
end

MySQL.Sync = setmetatable({ store = addStore }, alias_mt)
MySQL.Async = setmetatable({ store = addStore }, alias_mt)

local function onReady(cb)
	while GetResourceState('oxmysql') ~= 'started' do
		Wait(50)
	end

	oxmysql.awaitConnection()

	return cb and cb() or true
end

MySQL.ready = setmetatable({
	await = onReady
}, {
	__call = function(_, cb)
		Citizen.CreateThreadNow(function() onReady(cb) end)
	end,
})

function MySQL.PrepareQuery(query, parameters)
	local values = {}
	local parameterIndex = 0

	local newQuery = string.gsub(query, "%??%?", function(a)
		parameterIndex = parameterIndex + 1

		if a == '?' then
			if not (type(parameters[parameterIndex]) == 'table') then
				table.insert(values, parameters[parameterIndex])

				return '?'
			end

			local keys = {}
			local isArray = false
			for key, value in pairs(parameters[parameterIndex]) do
				if type(key) == 'number' then
					isArray = true
				else
					table.insert(keys, '`'..key..'`')
				end

				table.insert(values, value)
			end

			if isArray then
				return string.rep('?, ', #parameters[parameterIndex]):sub(1, -3)
			end

			return table.concat(keys, ' = ?, ') .. ' = ?'
		elseif a == '??' then
			local vars = parameters[parameterIndex]
			if type(vars) ~= "table" then
				vars = {vars}
			end

			local columns = {}
			for _, value in pairs(vars) do
				table.insert(columns, '`'..value..'`')
			end

			return table.concat(columns, ', ')
		end

		return 'UNKNOWN'
	end)

	return newQuery, values
end

_ENV.MySQL = MySQL
