-------------------------------------------
--- Модуль (и Factory) для работы с путями.
-- Позволяет оперировать путями директорий и файлов.
-- Одновременно представляет из себя и модуль и конструктор.
-------------------------------------------
-- _VERSION = lua5.1

local setmetatable = setmetatable
local getfenv = getfenv
local assert = assert
local type = type
local select = select
local pairs = pairs

local debug = {getinfo = debug.getinfo,};
local table = {insert = table.insert,
	concat = table.concat};

--debug
local print = print

--@module path
--@author Black Masta (seller.nightmares@gmail.com petrilla.illia@gmail.com)
module "path"

---------------------------------------------------------------------------------
--- Получить путь до файла относительно "GAME" в котором произошел вызов функции.
--@tparam number i Инкрементатор уровня стека. (опционально)
--@treturn string path
function getCurrent(i)
	local _source = debug.getinfo(2 + (i and i or 0), "S")
		.source
	_source = _source:sub(2, #_source)
	assert(_source ~= "[C]", "Cannot get path from [C] source.")
	return _source
end

--- Извлеч текущее название аддона (дополнения) из контекста вызова.
--@treturn string name Название дополнения (addon name).
function getAddon()
	local path = getCurrent(1)
	return path:match("addons[/|\\]([^/|\\]+)")
end

--- Разделительная черта используемая системой
--@local
--@tfield string _delim
local _delim = getCurrent():match("([/|\\])")

--- Получить разделитель путей.
--@treturn string char Разделитель.
function delim() return _delim end

--- Метатаблица Path
--@local
--@table meta
local meta = {}

--- Получить метатаблицу пути.
--@treturn metatable path
function getmeta() return meta end

-- Определение конструктора.
setmetatable(_M, {__call = function(self, init_path)
	assert(type(init_path) == "string" or type(init_path) == "nil", 
		"#1 constructor call argument must be string (or nil) value.")
	local t = {_path = ""}
	setmetatable(t, meta)
	if init_path ~= nil then
		t:append(init_path, true)
	else 
		t._path = getCurrent(1):match("(.*[/|\\]).*$")
	end
	return t
end})
meta.__index, meta.__type = 
	meta, "path"

function meta:__tostring()
	local t = {}
	for k, v in pairs(self:mods()) do table.insert(t, k) end
	return ("path(%s) [%s]"):format(self._path and ("\"%s\""):format(self._path),
		table.concat(t, ","))
end

--- Убрать окончание пути.
--@tparam number i Кол-во итераций снятия сегментов (делителей) с конца пути.
--@treturn path Новый путь.
function meta:up(i)
	local ret = self._path
	for i = 1, (i or 1) do
		ret = ret:match("(.*[/|\\]).")
	end
	return setmetatable({_path = ret}, meta)
end

--- Опустить корень пути.
--@tparam number i кол-во итераций опускания сегментов. (делителей)
--@treturn path Новый путь
function meta:rdown(i)
	local ret = self._path
	for i = 1, (i or 1) do
		ret = ret:match(".-[/|\\](.*)")
	end
	return setmetatable({_path = ret}, meta)
end

--- Добавить путь в конец.
--@tparam string str Сегмент пути
--@tparam boolean ignore Флаг игнорирования проверки типа пути.
--@treturn path self
function meta:append(str, ignore)
	assert(self:isFolder() or ignore, "Cannot append to files. (only folders)")
	str = str:gsub("[/|\\]", _delim)
	str = str:gsub("^" .. _delim, "")
	self._path = self._path .. str
	return self
end

function meta:__add(rsv)
	local tp = type(rsv)
	assert(tp == "path" or tp == "string", "Only can sum path with string or path.")
	assert(self:isFolder(), "Cannot __SUM with files. (only folders)")

	if tp == "string" then
		return setmetatable({_path = self._path}, meta)
			:append(rsv)
	else
		local app = rsv._path:gsub("^" .. _delim, "")
		return setmetatable({_path = self._path .. app}, meta)
	end
end

function meta:__mul(rsv)
	assert(type(rsv) == "path", "Path must be multipy by another path only.")
	local seg_st, seg_end = self._path:find(rsv:root())
	if not seg_st then return _M("") end
	local str = self._path:sub(1, seg_st - 1) .. rsv._path
	return setmetatable({_path = str}, meta)
end

function meta:__div(rsv)
	assert(type(rsv) == "path", "Path must be divide by another path only.")
	local seg_st, seg_end = self._path:find(rsv:root())
	if not seg_st then return _M("") end
	return setmetatable({_path = self._path:sub(1, seg_end)}, meta)
end

--- Получить корень пути.
--@treturn string root
function meta:root() return self._path:match("(.-[/|\\])") end

--- Проверить, является ли путь директорией
--@treturn boolean
function meta:isFolder() return (self._path:find("[/|\\]$") and true or false) end

--- Проверить, является ли путь файлом.
--@treturn boolean
function meta:isFile() return (not self:isFolder()) end

--- Получить расширение файла пути.
--@treturn string extension
function meta:ext()
	assert(self:isFile(), "Cannot get file extension from folder path.")
	return self._path:match("%..*$")
end

--- Получить название файла в пути.
--@treturn string filename
function meta:fname()
	assert(self:isFile(), "Cannot get filename from folder path.")
	return self._path:match(".*[/|\\](.*)$")
end

--- Получить имя файла в пути без расширения
--@treturn string filename without extension
function meta:fname_noext()
	assert(self:isFile(), "Cannot get filename from folder path.")
	return self._path:match(".*[/|\\](.*)%..*$")
end

--- Получить (подсчитать) кол-во делителей в пути.
--@treturn number i path delims count
function meta:subs()
	local pt = self._path
	local st = pt:find("[/|\\]")
	local i = 0
	while st do
		i = i + 1
		st = pt:find("[/|\\]", st + 1)
	end
	return i
end

--- Проверить наличие сегмента по корню пути.
--@tparam path path Путь которым проверяем
--@treturn boolean
function meta:has_node(path)
	assert(type(path) == "path", "#1 must be path value.")
	return select(1, self._path:find(path:root())) and true or false
end

--- Получить модификатор(-ы) поиска текущего пути.
--@treturn table mod(-s)
function meta:mods()
	local root = self:root()
	root = root:sub(1, #root - 1)
	local ret = {}
	if root == "addons" then 
		ret["GAME"] = true
		if self:has_node(_M("lua/")) then
			ret["lsv"] = true
		end
	elseif root == "lua" then 
		ret["GAME"] = true 
	elseif root == "download" then
		ret["DOWNLOAD"] = true
	end
	return ret
end

--[[
	Тесты

	local p1, p2 = path(),
		path():up(2) + path("another_one/thereissome/")
	print(1, p1)
	print(2, p2:rdown(), p2:rdown():root())
	print("*", p1 * p2:rdown())
	print("/", p1 / p2:rdown())
	print(p1:subs())

	print(p1)
	PrintTable(p1:mods())
]]