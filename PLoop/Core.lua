--======================================================================--
-- Copyright (c) 2011-2017 WangXH <kurapica125@outlook.com>             --
--                                                                      --
-- Permission is hereby granted, free of charge, to any person          --
-- obtaining a copy of this software and associated Documentation       --
-- files (the "Software"), to deal in the Software without              --
-- restriction, including without limitation the rights to use,         --
-- copy, modify, merge, publish, distribute, sublicense, and/or sell    --
-- copies of the Software, and to permit persons to whom the            --
-- Software is furnished to do so, subject to the following             --
-- conditions:                                                          --
--                                                                      --
-- The above copyright notice and this permission notice shall be       --
-- included in all copies or substantial portions of the Software.      --
--                                                                      --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,      --
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES      --
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND             --
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT          --
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,         --
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING         --
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR        --
-- OTHER DEALINGS IN THE SOFTWARE.                                      --
--======================================================================--

--======================================================================--
--               Pure Lua Object-Oriented Program System                --
--                                                                      --
-- Config :                                                             --
--    PLOOP_DOCUMENT_ENABLED                                            --
--      - Whether enable/disable document system, default true          --
--    PLOOP_SAVE_MEMORY                                                 --
--      - Whether save the memory, default false                        --
--======================================================================--

--======================================================================--
-- Author           :   kurapica125@outlook.com                         --
-- URL              :   http://github.com/kurapica/PLoop                --
-- Create Date      :   2011/02/03                                      --
-- Last Update Date :   2017/03/29                                      --
-- Version          :   r174                                            --
--======================================================================--

------------------------------------------------------
---------------- Private Environment -----------------
------------------------------------------------------
do
    local _G, rawset    = _G, rawset
    local _PLoopEnv     = setmetatable({}, {
        __index         = function(self, k) local v = _G[k] if v ~= nil then rawset(self, k, v) return v end end,
        __metatable     = true,
    })
    _PLoopEnv._PLoopEnv = _PLoopEnv

    -- Local Environment
    if setfenv then setfenv(1, _PLoopEnv) else _ENV = _PLoopEnv end
end

------------------------------------------------------
----------------- GLOBAL Definition ------------------
------------------------------------------------------
do
    -- Used to enable/disable document system
    DOCUMENT_ENABLED    = PLOOP_DOCUMENT_ENABLED == nil and true or PLOOP_DOCUMENT_ENABLED
    SAVE_MEMORY         = PLOOP_SAVE_MEMORY and true or false

    LUA_VERSION         = tonumber(_G._VERSION:match("[%d%.]+")) or 5.1

    WEAK_KEY            = { __mode = "k"  }
    WEAK_VALUE          = { __mode = "v"  }
    WEAK_ALL            = { __mode = "kv" }

    TYPE_CLASS          = "Class"
    TYPE_ENUM           = "Enum"
    TYPE_STRUCT         = "Struct"
    TYPE_INTERFACE      = "Interface"

    TYPE_NAMESPACE      = "NameSpace"
    TYPE_CLASSALIAS     = "ClassAlias"
    TYPE_EVENT          = "Event"

    -- Disposing method name
    DISPOSE_METHOD      = "Dispose"

    -- Struct Init method name
    STRUCT_INIT_METHOD  = "__init"

    -- Namespace field
    NAMESPACE_FIELD     = "__PLOOP_NameSpace"

    -- Owner field
    OWNER_FIELD         = "__PLOOP_OWNER"

    -- Base env field
    BASE_ENV_FIELD      = "__PLOOP_BASE_ENV"

    -- Import env field
    IMPORT_ENV_FIELD    = "__PLOOP_IMPORT_ENV"

    -- Special __index table filed
    INDEX_TABLE_FIELD   = "__PLOOP_INDEX_TABLE"

    -- Struct Special Index
    STRT_START_VALID    = 10001
    STRT_START_INIT     = 20001

    -- Attribute System
    ATTRIBUTE_INSTALLED = false

    -- MODIFIER
    MD_FINAL_FEATURE    = 2^0
    MD_FLAGS_ENUM       = 2^1
    MD_SEALED_FEATURE   = 2^2
    MD_ABSTRACT_CLASS   = 2^3
    MD_STATIC_FEATURE   = 2^4
    MD_REQUIRE_FEATURE  = 2^5
    MD_AUTO_PROPERTY    = 2^6
end

------------------------------------------------------
----------------------- Helper -----------------------
------------------------------------------------------
do
    -- Common features
    strlen              = string.len
    strformat           = string.format
    strfind             = string.find
    strsub              = string.sub
    strbyte             = string.byte
    strchar             = string.char
    strrep              = string.rep
    strgsub             = string.gsub
    strupper            = string.upper
    strlower            = string.lower
    strtrim             = strtrim or function(s) return s and (s:gsub("^%s*(.-)%s*$", "%1")) or "" end
    wipe                = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end

    tblconcat           = table.concat
    tinsert             = table.insert
    tremove             = table.remove
    sort                = table.sort
    floor               = math.floor
    log                 = math.log

    create              = coroutine.create
    resume              = coroutine.resume
    running             = coroutine.running
    status              = coroutine.status
    wrap                = coroutine.wrap
    yield               = coroutine.yield

    -- Check For lua 5.2
    newproxy            = newproxy or
        (function ()
            local _METATABLE_MAP = setmetatable({}, {__mode = "k"})

            return function (prototype)
                -- mean no userdata can be created in lua, use the table instead
                if type(prototype) == "table" and _METATABLE_MAP[prototype] then
                    return setmetatable({}, _METATABLE_MAP[prototype])
                elseif prototype == true then
                    local meta = {}
                    prototype = setmetatable({}, meta)
                    _METATABLE_MAP[prototype] = meta
                    return prototype
                else
                    return setmetatable({}, {__metatable = false})
                end
            end
        end)()

    FAKE_SETFENV        = false
    if setfenv and getfenv then
        -- AUTO ADDED PASS
    else
        if not debug and require then pcall(require, "debug") end
        if debug and debug.getinfo and debug.getupvalue and debug.upvaluejoin and debug.getlocal then
            local getinfo = debug.getinfo
            local getupvalue = debug.getupvalue
            local upvaluejoin = debug.upvaluejoin
            local getlocal = debug.getlocal

            setfenv = function(f, t)
                f = type(f) == 'function' and f or getinfo(f + 1, 'f').func
                local up, name = 0
                repeat
                    up = up + 1
                    name = getupvalue(f, up)
                until name == '_ENV' or name == nil
                if name then upvaluejoin(f, up, function() return t end, 1) end
            end

            getfenv = function(f)
                local cf, up, name, val = type(f) == 'function' and f or getinfo(f + 1, 'f').func, 0
                repeat
                    up = up + 1
                    name, val = getupvalue(cf, up)
                until name == '_ENV' or name == nil
                if val then return val end

                if type(f) == "number" then
                    f, up = f + 1, 0
                    repeat
                        up = up + 1
                        name, val = getlocal(f, up)
                    until name == '_ENV' or name == nil
                    if val then return val end
                end
            end
        else
            local _FENV_Cache = setmetatable({ [running() or 0] = _ENV }, {
                __call = function (self, env)
                    if env then
                        self[running() or 0] = env
                    else
                        return self[running() or 0]
                    end
                end, __mode = "k",
            })
            FAKE_SETFENV = true
            getfenv = function (lvl) return _FENV_Cache() end
            setfenv = function (lvl, env) _FENV_Cache(env) end
        end
    end

    -- In lua 5.2, the loadstring is deprecated
    loadstring          = loadstring or load
    loadfile            = loadfile

    if LUA_VERSION > 5.1 then
        loadInEnv       = function(chunk, source) return loadstring(chunk, source, nil, _PLoopEnv) end
    else
        loadInEnv       = function(chunk, source) local v = loadstring(chunk, source) setfenv(v, _PLoopEnv) return v end
    end

    -- Cache
    MAX_CACHE_COUNT     = 20
    CACHE_TABLE         = setmetatable({}, {__call = function(self, t) if t then if getmetatable(t) == nil and #self < MAX_CACHE_COUNT then wipe(t) tinsert(self, t) end else return tremove(self) or {} end end})

    -- Clone
    local function deepCloneObj(obj, cache)
        if type(obj) == "table" then
            if cache[obj] ~= nil then
                return cache[obj]
            elseif getmetatable(obj) then
                cache[obj] = type(obj.Clone) == "function" and obj:Clone(true) or obj
                return cache[obj]
            else
                local ret = {}
                cache[obj] = ret

                for k, v in pairs(obj) do ret[k] = deepCloneObj(v, cache) end

                return ret
            end
        else
            return obj
        end
    end

    function CloneObj(obj, deep)
        if type(obj) == "table" then
            if getmetatable(obj) then
                if type(obj.Clone) == "function" then return obj:Clone(deep) else return obj end
            else
                local ret = {}
                local cache = deep and CACHE_TABLE()

                if cache then cache[obj] = ret end

                for k, v in pairs(obj) do
                    if deep then ret[k] = deepCloneObj(v, cache) else ret[k] = v == obj and ret or v end
                end

                if cache then CACHE_TABLE(cache) end

                return ret
            end
        else
            return obj
        end
    end

    -- Local marker
    PrepareNameSpace_CACHE = setmetatable({}, WEAK_KEY)

    function PrepareNameSpace(target) PrepareNameSpace_CACHE[running() or 0] = target end
    function GetPrepareNameSpace() return PrepareNameSpace_CACHE[running() or 0] end

    -- Equal Check
    local function checkEqual(obj1, obj2, cache)
        if obj1 == obj2 then return true end
        if type(obj1) ~= "table" then return false end
        if type(obj2) ~= "table" then return false end

        if cache[obj1] and cache[obj2] then
            return true
        elseif cache[obj1] or cache[obj2] then
            return false
        else
            cache[obj1] = true
            cache[obj2] = true
        end

        if IsNameSpace(obj1) then return false end
        local cls = getmetatable(obj1)

        local info = cls and _NSInfo[cls]
        if info then
            if cls ~= getmetatable(obj2) then return false end
            if info.MetaTable.__eq then return false end

            -- Check properties
            for name, prop in pairs(info.Cache) do
                if type(prop) == "table" and not getmetatable(prop) and (prop.Get or prop.GetMethod or prop.Field) then
                    if not checkEqual(obj1[name], obj2[name], cache) then return false end
                end
            end
            return true
        end

        -- Check fields
        for k, v in pairs(obj1) do if not checkEqual(v, obj2[k], cache) then return false end end
        for k, v in pairs(obj2) do if obj1[k] == nil then return false end end

        return true
    end

    function IsEqual(obj1, obj2)
        local cache = CACHE_TABLE()
        local result = checkEqual(obj1, obj2, cache)
        CACHE_TABLE(cache)
        return result
    end

    -- Keyword access system
    local _KeywordAccessorInfo = {
        GetKeyword = function(self, owner, key)
            if type(key) == "string" and key:match("^%l") and self[key] then
                self.Owner, self.Keyword = owner, self[key]
                return self.KeyAccessor
            end
        end,
        ClearKeyword = function(self)
            self.Owner = nil
            self.Keyword = nil
        end,
    }
    local _KeyAccessor = newproxy(true)
    getmetatable(_KeyAccessor).__call = function (self, value, value2)
        self = _KeywordAccessorInfo[self]
        local keyword, owner = self.Keyword, self.Owner
        self.Keyword, self.Owner = nil, nil
        if keyword and owner then
            -- In 5.1, tail call for error & setfenv is not supported
            if value2 ~= nil then
                local ok, ret = pcall(keyword, owner, value, value2, 4)
                if not ok then error(ret:match("%d+:%s*(.-)$") or ret, 2) end
                return ret
            else
                local ok, ret = pcall(keyword, owner, value, 4)
                if not ok then error(ret:match("%d+:%s*(.-)$") or ret, 2) end
                return ret
            end
        end
    end
    getmetatable(_KeyAccessor).__metatable = false

    function _KeywordAccessor(key, value)
        if type(key) == "string" and type(value) == "function" then
            -- Save keywords to all accessors
            for _, info in pairs(_KeywordAccessorInfo) do if type(info) == "table" then info[key] = value end end
        else
            local keyAccessor = newproxy(_KeyAccessor)
            local info = { GetKeyword = _KeywordAccessorInfo.GetKeyword, ClearKeyword = _KeywordAccessorInfo.ClearKeyword, KeyAccessor = keyAccessor }
            _KeywordAccessorInfo[keyAccessor] = info
            return info
        end
    end

    --  ValidateFlags
    function ValidateFlags(checkValue, targetValue)
        if not targetValue or checkValue > targetValue then return false end
        targetValue = targetValue % (2 * checkValue)
        return (targetValue - targetValue % checkValue) == checkValue
    end

    function TurnOnFlags(checkValue, targetValue)
        if not ValidateFlags(checkValue, targetValue) then
            return checkValue + (targetValue or 0)
        end
        return targetValue
    end

    function TurnOffFlags(checkValue, targetValue)
        if ValidateFlags(checkValue, targetValue) then
            return targetValue - checkValue
        end
        return targetValue
    end

    if LUA_VERSION >= 5.3 then
        ValidateFlags = loadstring [[
            return function(checkValue, targetValue)
                return (checkValue & (targetValue or 0)) > 0
            end
        ]] ()

        TurnOnFlags = loadstring [[
            return function(checkValue, targetValue)
                return checkValue | (targetValue or 0)
            end
        ]] ()
    elseif (LUA_VERSION == 5.2 and type(bit32) == "table") or (LUA_VERSION == 5.1 and type(bit) == "table") then
        local band = bit32 and bit32.band or bit.band
        local bor = bit32 and bit32.bor  or bit.bor

        ValidateFlags = function (checkValue, targetValue)
            return band(checkValue, targetValue or 0) > 0
        end

        TurnOnFlags = function (checkValue, targetValue)
            return bor(checkValue, targetValue or 0)
        end
    end
end

------------------------------------------------------
--------------- NameSpace & ClassAlias ---------------
------------------------------------------------------
do
    PROTYPE_NAMESPACE   = newproxy(true)
    PROTYPE_CLASSALIAS  = newproxy(true)

    _NSInfo             = setmetatable({ [PROTYPE_NAMESPACE] = { Owner = PROTYPE_NAMESPACE } }, { __index = function(self, key) if type(key) == "string" then key = GetNameSpace(PROTYPE_NAMESPACE, key) return key and rawget(self, key) end end, __mode = "k" })
    _AliasMap           = setmetatable({}, WEAK_ALL)

    -- metatable for namespaces
    do
        local _MetaNS       = getmetatable(PROTYPE_NAMESPACE)
        local _UnmStruct    = {}
        local _MixedStruct  = {}

        _MetaNS.__call = function(self, ...)
            local info = _NSInfo[self]
            local iType = info.Type

            if iType == TYPE_CLASS then
                -- Create Class object, using ret avoid tail call error stack
                local ret = Class2Obj(info, ...)
                return ret
            elseif iType == TYPE_STRUCT then
                -- Create Struct
                local ret = Struct2Obj(info, ...)
                return ret
            elseif iType == TYPE_INTERFACE then
                -- Create interface's anonymousClass' object
                local ret = Interface2Obj(info, ...)
                return ret
            elseif iType == TYPE_ENUM then
                -- Parse Enum
                local value = ...
                if info.MaxValue and type(value) == "number" and value == floor(value) and value >= 0 and value <= info.MaxValue then
                    if value == 0 or info.Cache[value] then
                        return info.Cache[value]
                    else
                        local rCache = CACHE_TABLE()
                        local eCache = info.Cache
                        local ckv = 1

                        while ckv <= value do
                            if ValidateFlags(ckv, value) then tinsert(rCache, eCache[ckv]) end
                            ckv = ckv * 2
                        end

                        return unpack(rCache)
                    end
                else
                    return info.Cache[value]
                end
            end

            error(tostring(self) .. " is not callable.", 2)
        end

        if SAVE_MEMORY then
            _MetaNS.__index = function(self, key)
                local info = _NSInfo[self]

                -- Sub-NS first
                local ret = info.SubNS and info.SubNS[key]
                if ret then return ret end

                local iType = info.Type

                if iType == TYPE_STRUCT then
                    return info.Method and info.Method[key] or nil
                elseif iType == TYPE_CLASS or iType == TYPE_INTERFACE then
                    if iType == TYPE_CLASS then
                        -- Meta-method
                        if _KeyMeta[key] then
                            local v = info.MetaTable[_KeyMeta[key]]
                            if key == "__index" and type(v) == "table" and getmetatable(v) == nil then
                                return CloneObj(v, true)
                            else
                                return v
                            end
                        end

                        if key == "Super" then
                            info = _NSInfo[info.SuperClass]
                            if info then
                                return info.ClassAlias or BuildClassAlias(info)
                            else
                                return error("The class has no super class.", 2)
                            end
                        end

                        if key == "This" then return info.ClassAlias or BuildClassAlias(info) end
                    end

                    -- Method
                    ret = info.Cache[key] or info.Method and info.Method[key]
                    if type(ret) == "function" then return ret end

                    -- Property
                    ret = info.Property and info.Property[key]
                    if ret and ret.IsStatic then
                        -- Property
                        local oper = ret
                        local value
                        local default = oper.Default

                        -- Get Getter
                        local operTar = oper.Get-- or info.Method[oper.GetMethod]

                        -- Get Value
                        if operTar then
                            value = operTar()
                        else
                            operTar = oper.Field

                            if operTar then
                                value = oper.SetWeak and info.WeakStaticFields or info.StaticFields
                                value = value and value[operTar]
                            elseif default == nil then
                                error(("%s can't be read."):format(key), 2)
                            end
                        end

                        if value == nil then
                            operTar = oper.DefaultFunc
                            if operTar then
                                value = operTar(self)
                                if value ~= nil then
                                    if oper.Set == false then
                                        operTar = oper.Field

                                        -- Check container
                                        local container

                                        if oper.SetWeak then
                                            container = info.WeakStaticFields
                                            if not container then
                                                container = setmetatable({}, WEAK_VALUE)
                                                info.WeakStaticFields = container
                                            end
                                        else
                                            container = info.StaticFields
                                            if not container then
                                                container = {}
                                                info.StaticFields = container
                                            end
                                        end

                                        -- Set the value
                                        container[operTar] = value
                                    else
                                        self[key] = value
                                    end
                                end
                            else
                                value = default
                            end
                        end
                        if oper.GetClone then value = CloneObj(value, oper.GetDeepClone) end

                        return value
                    end
                elseif iType == TYPE_ENUM then
                    local val
                    if type(key) == "string" then val = info.Enum[strupper(key)] end
                    if val == nil and info.Cache[key] ~= nil then val = key end
                    if val == nil then error(("%s is not an enumeration value of %s."):format(tostring(key), tostring(self)), 2) end
                    return val
                end
            end

            _MetaNS.__newindex = function(self, key, value)
                local info = _NSInfo[self]

                if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
                    -- Static Property
                    local oper = info.Property and info.Property[key]

                    if oper and oper.IsStatic then
                        if oper.Set == false then error(("%s can't be set."):format(key), 2) end

                        -- Property
                        if oper.Type then value = Validate4Type(oper.Type, value, key, key, 3) end
                        if oper.SetClone then value = CloneObj(value, oper.SetDeepClone) end

                        -- Get Setter
                        local operTar = oper.Set-- or info.Method[oper.SetMethod]

                        -- Set Value
                        if operTar then
                            return operTar(value)
                        else
                            operTar = oper.Field

                            if operTar then
                                -- Check container
                                local container
                                local default = oper.Default

                                if oper.SetWeak then
                                    container = info.WeakStaticFields
                                    if not container then
                                        container = setmetatable({}, WEAK_VALUE)
                                        info.WeakStaticFields = container
                                    end
                                else
                                    container = info.StaticFields
                                    if not container then
                                        container = {}
                                        info.StaticFields = container
                                    end
                                end

                                -- Check old value
                                local old = container[operTar]
                                if old == nil then old = default end
                                if old == value then return end

                                -- Set the value
                                container[operTar] = value

                                -- Dispose old
                                if oper.SetRetain and old and old ~= default then
                                    DisposeObject(old)
                                    old = nil
                                end

                                -- Call handler
                                operTar = oper.Handler

                                return operTar and operTar(self, value, old, key)
                            else
                                error(("%s can't be set."):format(key), 2)
                            end
                        end
                    else
                        local ok, msg = pcall(SaveFeature, info, key, value)
                        if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                        return not info.BeginDefinition and RefreshCache(self)
                    end
                elseif info.Type == TYPE_STRUCT then
                    local ok, msg = pcall(SaveFeature, info, key, value)
                    if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                    return not info.BeginDefinition and RefreshStruct(self)
                end

                error(("Can't set data to %s, it's readonly."):format(tostring(self)), 2)
            end
        else
            _MetaNS.__index = function(self, key)
                local info = _NSInfo[self]

                -- Sub-NS first
                local ret = info.SubNS and info.SubNS[key]
                if ret then return ret end

                local iType = info.Type

                if iType == TYPE_STRUCT then
                    return info.Method and info.Method[key] or nil
                elseif iType == TYPE_CLASS or iType == TYPE_INTERFACE then
                    if iType == TYPE_CLASS then
                        -- Meta-method
                        if _KeyMeta[key] then
                            local v = info.MetaTable[_KeyMeta[key]]
                            if key == "__index" and type(v) == "table" and getmetatable(v) == nil then
                                return CloneObj(v, true)
                            else
                                return v
                            end
                        end

                        if key == "Super" then
                            info = _NSInfo[info.SuperClass]
                            if info then
                                return info.ClassAlias or BuildClassAlias(info)
                            else
                                return error("The class has no super class.", 2)
                            end
                        end

                        if key == "This" then return info.ClassAlias or BuildClassAlias(info) end
                    end

                    -- Method
                    ret = info.Cache[key] or info.Method and info.Method[key]
                    if type(ret) == "function" then return ret end

                    -- Property
                    ret = info.Property and info.Property[key]
                    if ret and ret.IsStatic then
                        return ret.RawGet(self)
                    end
                elseif iType == TYPE_ENUM then
                    local val
                    if type(key) == "string" then val = info.Enum[strupper(key)] end
                    if val == nil and info.Cache[key] ~= nil then val = key end
                    if val == nil then error(("%s is not an enumeration value of %s."):format(tostring(key), tostring(self)), 2) end
                    return val
                end
            end

            _MetaNS.__newindex = function(self, key, value)
                local info = _NSInfo[self]

                if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
                    -- Static Property
                    local oper = info.Property and info.Property[key]

                    if oper and oper.IsStatic then
                        oper.RawSet(self, value)
                        return
                    else
                        local ok, msg = pcall(SaveFeature, info, key, value)
                        if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                        return not info.BeginDefinition and RefreshCache(self)
                    end
                elseif info.Type == TYPE_STRUCT then
                    local ok, msg = pcall(SaveFeature, info, key, value)
                    if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                    return not info.BeginDefinition and RefreshStruct(self)
                end

                error(("Can't set data to %s, it's readonly."):format(tostring(self)), 2)
            end
        end

        _MetaNS.__tostring = function(self)
            local info = _NSInfo[self]

            if info then
                if info.OriginNS then
                    return "-" .. tostring(info.OriginNS)
                elseif info.CombineNS then
                    local name = ""
                    for _, ns in ipairs(info.CombineNS) do
                        ns = tostring(ns)
                        if ns:match("^%-") then ns = "(" .. ns .. ")" end
                        if name ~= "" then
                            name = name .. "+" .. ns
                        else
                            name = ns
                        end
                    end
                    return name
                elseif info.OriginIF then
                    return tostring(info.OriginIF) .. "." .. "AnonymousClass"
                else
                    local name = info.Name

                    while info and info.NameSpace do
                        info = _NSInfo[info.NameSpace]

                        if info.Name then name = info.Name.."."..name end
                    end

                    return name
                end
            end
        end

        _MetaNS.__unm = function(self)
            local sinfo = _NSInfo[self]
            if sinfo.Type == TYPE_CLASS or sinfo.Type == TYPE_INTERFACE then
                local strt = _UnmStruct[self]
                if not strt then
                    if sinfo.Type == TYPE_CLASS then
                        local errMsg = "%s must be child-class of [Class]" .. tostring(self)
                        __Sealed__()
                        __Default__(self)
                        strt = struct {
                            function (value)
                                assert(IsChildClass(self, value), errMsg)
                            end
                        }
                    else
                        local errorMsg = "%s must extend the [Interface]" .. tostring(self)
                        __Sealed__()
                        __Default__(self)
                        strt = struct {
                            function (value)
                                assert(IsExtend(self, value), errMsg)
                            end
                        }
                    end

                    _UnmStruct[self] = strt
                    _NSInfo[strt].OriginNS = self
                end
                return strt
            else
                error("The unary '-' operation only support class and interface types", 2)
            end
        end

        _MetaNS.__add = function(self, other)
            local sinfo = _NSInfo[self]
            local oinfo = _NSInfo[other]
            if sinfo and oinfo then
                local sref = tostring(sinfo):match("%w+$")
                local oref = tostring(oinfo):match("%w+$")

                local strt = _MixedStruct[sref .. "_" .. oref] or _MixedStruct[oref .. "_" .. sref]
                if strt then return strt end

                local errMsg = "%s must be value of "
                local sDef = {
                    function (value)
                        local ret = GetValidatedValue(self, value, true)
                        if ret == nil then ret = GetValidatedValue(other, value, true) end
                        assert(ret ~= nil, errMsg)
                        return ret
                    end
                }

                -- Check if need create init method
                local sInit = sinfo.Type == TYPE_ENUM or sinfo.Type == TYPE_STRUCT
                local oInit = oinfo.Type == TYPE_ENUM or oinfo.Type == TYPE_STRUCT

                if sInit and oInit then
                    sDef[STRUCT_INIT_METHOD] = function (value)
                        local ret = GetValidatedValue(self, value)
                        if ret == nil then ret = GetValidatedValue(other, value) end
                        return ret
                    end
                elseif sInit then
                    sDef[STRUCT_INIT_METHOD] = function (value)
                        return GetValidatedValue(self, value)
                    end
                elseif oInit then
                    sDef[STRUCT_INIT_METHOD] = function (value)
                        return GetValidatedValue(other, value)
                    end
                end

                __Sealed__()
                strt = struct (sDef)

                _MixedStruct[sref .. "_" .. oref] = strt
                _NSInfo[strt].CombineNS = { self, other }
                errMsg = errMsg .. tostring(strt)

                return strt
            end
        end

        _MetaNS.__metatable = TYPE_NAMESPACE

        _MetaNS = nil
    end

    -- metatable for super alias
    do
        local _MetaSA   = getmetatable(PROTYPE_CLASSALIAS)

        _MetaSA.__call = function(self, obj, ...)
            -- Init the class object
            local info = _AliasMap[self]
            if IsChildClass(info.Owner, getmetatable(obj)) then return Class1Obj(info, obj, ...) end
        end

        _MetaSA.__index = function(self, key)
            local info = _AliasMap[self]
            local ret = info.SubNS and info.SubNS[key]

            if ret then
                return ret
            elseif _KeyMeta[key] then
                local v = info.MetaTable[_KeyMeta[key]]
                if key == "__index" and type(v) == "table" and getmetatable(v) == nil then
                    return CloneObj(v, true)
                else
                    return v
                end
            else
                ret = info.Cache[key] or info.Method and info.Method[key]
                if type(ret) == "function" then return ret end
            end
        end

        _MetaSA.__tostring = function(self) return tostring(_AliasMap[self].Owner) end
        _MetaSA.__metatable = TYPE_CLASSALIAS

        _MetaSA = nil
    end

    -- BuildClassAlias
    function BuildClassAlias(info)
        local value = newproxy(PROTYPE_CLASSALIAS)
        info.ClassAlias = value
        _AliasMap[value] = info
        return value
    end

    -- IsNameSpace
    function IsNameSpace(ns) return rawget(_NSInfo, ns) and true or false end

    -- RecordNSFeatures
    local _newFeatures

    function RecordNSFeatures()
        _newFeatures = {}
    end

    function GetNsFeatures()
        local ret = _newFeatures
        _newFeatures = nil
        return ret
    end

    -- BuildNameSpace
    function BuildNameSpace(ns, namelist)
        if type(namelist) ~= "string" or (ns and not IsNameSpace(ns)) then return end

        local cls = ns
        local info = _NSInfo[cls]
        local parent = cls

        for name in namelist:gmatch("[_%w]+") do
            if not info then
                cls = newproxy(PROTYPE_NAMESPACE)
            elseif info.Type == TYPE_ENUM then
                return error(("The %s is an enumeration, can't define sub-namespace in it."):format(tostring(info.Owner)))
            else
                local scls = info.SubNS and info.SubNS[name]

                if not scls then
                    -- No conflict
                    if info.Members and info.Members[name] or info.Cache and info.Cache[name] or info.Method and info.Method[name] or info.Property and info.Property[name] then
                        return error(("The [%s] %s - %s is defined, can't be used as namespace."):format(info.Type, tostring(info.Owner), name))
                    end

                    scls = newproxy(PROTYPE_NAMESPACE)
                    info.SubNS = info.SubNS or {}
                    info.SubNS[name] = scls

                    if cls == PROTYPE_NAMESPACE and _G[name] == nil then _G[name] = scls end
                end

                cls = scls
            end

            info = _NSInfo[cls]
            if not info then
                info = { Owner = cls, Name = name, NameSpace = parent }
                _NSInfo[cls] = info
            end
            parent = cls
        end

        if cls == ns then return end

        if _newFeatures then _newFeatures[cls] = true end

        return cls
    end

    -- GetNameSpace
    function GetNameSpace(ns, namelist)
        if type(namelist) ~= "string" or not IsNameSpace(ns) then return end

        local cls = ns
        local info

        for name in namelist:gmatch("[_%w]+") do
            info = _NSInfo[cls]
            cls = info.SubNS and info.SubNS[name]

            if not cls then return end
        end

        if cls == ns then return end

        return cls
    end

    -- SetNameSpace
    function SetNameSpace4Env(env, name)
        if type(env) ~= "table" then return end

        local ns = type(name) == "string" and BuildNameSpace(PROTYPE_NAMESPACE, name) or IsNameSpace(name) and name or nil
        rawset(env, NAMESPACE_FIELD, ns)

        return ns
    end

    -- GetEnvNameSpace
    function GetNameSpace4Env(env, rawOnly)
        local ns = type(env) == "table" and ((rawOnly and rawget(env, NAMESPACE_FIELD)) or (not rawOnly and env[NAMESPACE_FIELD]))

        if IsNameSpace(ns) then return ns end
    end

    ------------------------------------
    --- Set the default namespace for the current environment, the class defined in this environment will be stored in this namespace
    ------------------------------------
    function namespace(env, name, stack)
        stack = stack or 2
        name = name or env
        if name ~= nil and type(name) ~= "string" and not IsNameSpace(name) then error([[Usage: namespace "namespace"]], stack) end
        env = type(env) == "table" and env or getfenv(stack) or _G

        local ok, ns = pcall(SetNameSpace4Env, env, name)

        if not ok then error(ns:match("%d+:%s*(.-)$") or ns, stack) end

        if ns and ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, ns, AttributeTargets.NameSpace)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
        end
    end

    function GetDefineNS(env, name, ty)
        if not name then
            -- Anonymous
            return BuildNameSpace(nil, "Anonymous" .. ty)
        elseif IsNameSpace(name) then
            return name
        elseif type(name) == "string" then
            if not name:match("^[_%w]+$") then return end

            local ns = GetPrepareNameSpace() == nil and GetNameSpace4Env(env) or GetPrepareNameSpace() or nil

            if ns then
                return BuildNameSpace(ns, name)
            else
                local tar = env[name]
                info = _NSInfo[tar]

                if not (info and info.NameSpace == nil and info.Type == ty ) then
                    tar = BuildNameSpace(nil, name)
                end

                return tar
            end
        end
    end
end

------------------------------------------------------
------------------- Type Validation ------------------
------------------------------------------------------
do
    function Validate4Type(oType, value, partName, mainName, stack, onlyValidate)
        if value == nil or not oType then return value end

        local info = _NSInfo[oType]
        if not info then return value end

        local iType = info.Type
        local flag, ret

        if iType == TYPE_STRUCT then
            flag, ret = pcall(info.RawValidate, info, value, onlyValidate)

            if flag then if onlyValidate then return value else return ret end end

            ret = strtrim(ret:match(":%d+:%s*(.-)$") or ret)
        elseif iType == TYPE_ENUM then
            local otype = type(value)
            -- Check if the value is an enumeration value of this enum
            if otype == "string" then
                local val = info.Enum[strupper(value)]
                if val ~= nil then if onlyValidate then return value else return val end end
            end

            if info.MaxValue then
                -- Bit flag validation, use MaxValue check to reduce cost
                if otype == "number" and value == floor(value) and ((value == 0 and info.Cache[0]) or (value >= 1 and value <= info.MaxValue)) then
                    return value
                end
            else
                if info.Cache[value] then return value end
            end

            ret = ("%s must be a value of [enum]%s ( %s )."):format("%s", tostring(oType), GetShortEnumInfo(oType))
        else
            local cls = getmetatable(value)

            if iType == TYPE_CLASS then
                if cls and IsChildClass(oType, cls) then return value end

                ret = ("%s must be an instance of [class]%s."):format("%s", tostring(oType))
            elseif iType == TYPE_INTERFACE then
                if cls and IsExtend(oType, cls) then return value end

                ret = ("%s must be an instance extended from [interface]%s."):format("%s", tostring(oType))
            end
        end

        if partName and partName ~= "" then
            if ret:find("%%s([_%w]+)") then
                ret = ret:gsub("%%s", "%%s"..partName..".")
            else
                ret = ret:gsub("%%s", "%%s"..partName)
            end
        end

        --if not ret:match("%(Optional%)$") then ret = ret .. "(Optional)" end
        if mainName and ret:find("%%s") then ret = ret:gsub("%%s[_%w]*", mainName) end

        error(ret, stack or 2)
    end

    function GetValidatedValue(oType, value, onlyValidate)
        if value == nil or not oType then return value end

        local info = _NSInfo[oType]
        if not info then return value end

        local iType = info.Type
        local flag, ret

        if iType == TYPE_STRUCT then
            flag, ret = pcall(info.RawValidate, info, value, onlyValidate)

            if flag then if onlyValidate then return value else return ret end end
        elseif iType == TYPE_ENUM then
            local otype = type(value)
            -- Check if the value is an enumeration value of this enum
            if otype == "string" then
                local val = info.Enum[strupper(value)]
                if val ~= nil then if onlyValidate then return value else return val end end
            end

            if info.MaxValue then
                -- Bit flag validation, use MaxValue check to reduce cost
                if otype == "number" and value == floor(value) and ((value == 0 and info.Cache[0]) or (value >= 1 and value <= info.MaxValue)) then
                    return value
                end
            else
                if info.Cache[value] then return value end
            end
        else
            local cls = getmetatable(value)

            if iType == TYPE_CLASS then
                if cls and IsChildClass(oType, cls) then return value end
            elseif iType == TYPE_INTERFACE then
                if cls and IsExtend(oType, cls) then return value end
            end
        end
    end
end

------------------------------------------------------
------------------- Documentation --------------------
------------------------------------------------------
do
    _DocMap = setmetatable({}, WEAK_KEY)

    function getSuperDoc(info, key, dkey)
        if info.SuperClass then
            local sinfo = _NSInfo[info.SuperClass]

            while sinfo do
                if _DocMap[sinfo] and (_DocMap[sinfo][key] or _DocMap[sinfo][dkey]) then
                    return _DocMap[sinfo][key] or _DocMap[sinfo][dkey]
                end

                if sinfo.SuperClass then
                    sinfo = _NSInfo[sinfo.SuperClass]
                else
                    break
                end
            end
        end

        -- Check Interface
        if info.Cache4Interface then
            for _, IF in ipairs(info.Cache4Interface) do
                local sinfo = _NSInfo[IF]

                if _DocMap[sinfo] and (_DocMap[sinfo][key] or _DocMap[sinfo][dkey]) then
                    return _DocMap[sinfo][key] or _DocMap[sinfo][dkey]
                end
            end
        end
    end

    function getTargetType(info, name, targetType)
        if targetType == nil then
            -- Find the targetType based on the name
            if name == info.Name then
                targetType = AttributeTargets[info.Type or TYPE_NAMESPACE]
            elseif info.Cache[name] then
                local tar = info.Cache[name]
                if type(tar) == "function" then
                    return AttributeTargets.Method
                elseif getmetatable(tar) then
                    return AttributeTargets.Event
                else
                    return AttributeTargets.Property
                end
            end
        elseif type(targetType) == "string" then
            targetType = AttributeTargets[targetType]
        elseif type(targetType) ~= "number" then
            targetType = nil
        end

        return targetType
    end

    function SaveDocument(data, name, targetType, owner)
        if not DOCUMENT_ENABLED or type(data) ~= "string" then return end

        local info = _NSInfo[owner]

        if not info then return end

        if not name then name = info.Name end

        -- Check the type
        targetType = getTargetType(info, name, targetType)

        -- Get the head space in the first line and remove it from all lines
        local space = data:match("^%s+")

        if space then data = data:gsub("^%s+", ""):gsub("([\n\r]+)"..space, "%1"):gsub("([\n\r]+)%s+$", "%1") end

        local key = name

        if targetType then key = tostring(targetType) .. name end

        _DocMap[info] = _DocMap[info] or {}
        _DocMap[info][key] = data
    end

    function GetDocument(owner, name, targetType)
        if not DOCUMENT_ENABLED then return end

        if type(owner) == "string" then owner = GetNameSpace(PROTYPE_NAMESPACE, owner) end

        local info = _NSInfo[owner]
        if not info then return end

        name = name or info.Name
        if type(name) ~= "string" then return end

        targetType = getTargetType(info, name, targetType)

        local key = targetType and tostring(targetType) .. name or nil

        return _DocMap[info] and (_DocMap[info][key] or _DocMap[info][name]) or (targetType ~= "CLASS" and targetType ~= "INTERFACE") and getSuperDoc(info, key, name) or nil
    end

    do
        local _name
        local _owner

        local function parseDoc(data)
            local info = _NSInfo[_owner]
            if _name == info.Name then
                return SaveDocument(data, _name, AttributeTargets[info.Type], _owner)
            else
                return SaveDocument(data, _name, AttributeTargets.Method, _owner)
            end
        end

        function document(env, name)
            _name = name
            _owner = env[OWNER_FIELD]

            return parseDoc
        end
    end
end

------------------------------------------------------
------------------- Cache System ---------------------
------------------------------------------------------
do
    Verb2Adj = { "(.+)(ed)$", "(.+)(able)$", "(.+)(ing)$", "(.+)(ive)$", "(.+)(ary)$", "(.+)(al)$", "(.+)(ous)$", "(.+)(ior)$", "(.+)(ful)$" }

    function ParseAdj(str, useIs)
        local noun, adj = str:match("^(.-)(%u%l+)$")

        if noun and adj and #noun > 0 and #adj > 0 then
            for _, pattern in ipairs(Verb2Adj) do
                local head, tail = adj:match(pattern)

                if head and tail and #head > 0 and #tail > 0 then
                    local c = head:sub(1, 1)

                    if useIs then
                        return "^[Ii]s[" .. strupper(c) .. strlower(c).."]" .. head:sub(2) .. "%w*" .. noun .. "$"
                    else
                        return "^[" .. strupper(c) .. strlower(c).."]" .. head:sub(2) .. "%w*" .. noun .. "$"
                    end
                end
            end
        end
    end

    function CloneWithOverride(dest, src, chkStatic)
        for key, value in pairs(src) do if not (chkStatic and value.IsStatic) then dest[key] = value end end
    end

    function CloneWithoutOverride(dest, src)
        for key, value in pairs(src) do if dest[key] == nil then dest[key] = value end end
    end

    function CloneInterfaceCache(dest, src, cache)
        if not src then return end
        for _, IF in ipairs(src) do if not cache[IF] then cache[IF] = true tinsert(dest, IF) end end
    end

    -- Property System
    WEAK_VALUE_MAP = setmetatable({}, WEAK_KEY)

    _PropGetBuilder = {}

    FLAG_GET_DISABLE = 2^0
    FLAG_GET_DEFAULT = 2^1
    FLAG_GET_DEFAULTFUNC = 2^2
    FLAG_GET_GET = 2^3
    FLAG_GET_GETMETHOD = 2^4
    FLAG_GET_FIELD = 2^5
    FLAG_GET_SETWEAK = 2^6
    FLAG_GET_SETFALSE = 2^7
    FLAG_GET_GETCLONE = 2^8
    FLAG_GET_STATIC = 2^9

    function BuildPropertyGet(name, oper)
        if oper.Get and oper.Default == nil and not oper.DefaultFunc and not oper.GetClone then
            return oper.Get
        end

        local propToken = 0
        local upValues = CACHE_TABLE()
        local needName = false

        if oper.Get == false or (not oper.Get and not oper.GetMethod and oper.Field == nil and not oper.DefaultFunc and oper.Default == nil) then
            propToken = TurnOnFlags(FLAG_GET_DISABLE, propToken)
            needName = true
        else
            -- Calc the token
            if oper.DefaultFunc then
                propToken = TurnOnFlags(FLAG_GET_DEFAULTFUNC, propToken)
                tinsert(upValues, oper.DefaultFunc)
                if oper.Set == false then
                    propToken = TurnOnFlags(FLAG_GET_SETFALSE, propToken)
                else
                    needName = true
                end
            elseif oper.Default ~= nil then
                propToken = TurnOnFlags(FLAG_GET_DEFAULT, propToken)
                tinsert(upValues, oper.Default)
            end

            if oper.Get then
                propToken = TurnOnFlags(FLAG_GET_GET, propToken)
                tinsert(upValues, oper.Get)
            elseif oper.GetMethod and not oper.IsStatic then
                propToken = TurnOnFlags(FLAG_GET_GETMETHOD, propToken)
                tinsert(upValues, oper.GetMethod)
            elseif oper.Field ~= nil then
                propToken = TurnOnFlags(FLAG_GET_FIELD, propToken)
                tinsert(upValues, oper.Field)
                if oper.IsStatic then
                    propToken = TurnOnFlags(FLAG_GET_STATIC, propToken)
                end
                if oper.SetWeak then
                    propToken = TurnOnFlags(FLAG_GET_SETWEAK, propToken)
                end
            end

            if oper.GetClone and (oper.Get or oper.GetMethod or oper.Field or oper.Default ~= nil or oper.DefaultFunc) then
                propToken = TurnOnFlags(FLAG_GET_GETCLONE, propToken)
                tinsert(upValues, oper.GetDeepClone or false)
            end
        end

        if needName then
            tinsert(upValues, name)
        end

        -- Building
        if not _PropGetBuilder[propToken] then
            local gHeader = CACHE_TABLE()
            local gbody = CACHE_TABLE()

            tinsert(gbody, "") -- Remain for closure values
            tinsert(gbody, [[return function(self)]])

            if ValidateFlags(FLAG_GET_DISABLE, propToken) then
                tinsert(gbody, [[error(("%s can't be read."):format(name),2)]])
            else
                if ValidateFlags(FLAG_GET_DEFAULTFUNC, propToken) then
                    tinsert(gHeader, "defaultFunc")
                elseif ValidateFlags(FLAG_GET_DEFAULT, propToken) then
                    tinsert(gHeader, "default")
                end

                tinsert(gbody, [[local value]])

                if ValidateFlags(FLAG_GET_GET, propToken) then
                    tinsert(gHeader, "get")
                    tinsert(gbody,[[value = get(self)]])
                elseif ValidateFlags(FLAG_GET_GETMETHOD, propToken) then
                    tinsert(gHeader, "getMethod")
                    tinsert(gbody,[[value = _NSInfo[getmetatable(self)].Cache[getMethod](self)]])
                elseif ValidateFlags(FLAG_GET_FIELD, propToken) then
                    tinsert(gHeader, "field")
                    if ValidateFlags(FLAG_GET_STATIC, propToken) then
                        if ValidateFlags(FLAG_GET_SETWEAK, propToken) then
                            tinsert(gbody, [[value = _NSInfo[self].WeakStaticFields]])
                        else
                            tinsert(gbody, [[value = _NSInfo[self].StaticFields]])
                        end
                        tinsert(gbody, [[if value then value = value[field] else value = nil end]])
                    else
                        if ValidateFlags(FLAG_GET_SETWEAK, propToken) then
                            tinsert(gbody, [[value = WEAK_VALUE_MAP[self] ]])
                            tinsert(gbody, [[if value then value = value[field] else value = nil end]])
                        else
                            tinsert(gbody, [[value=rawget(self, field)]])
                        end
                    end
                end

                -- Nil Handler
                if ValidateFlags(FLAG_GET_DEFAULTFUNC, propToken) or ValidateFlags(FLAG_GET_DEFAULT, propToken) then
                    tinsert(gbody, [[if value == nil then]])

                    if ValidateFlags(FLAG_GET_DEFAULTFUNC, propToken) then
                        tinsert(gbody, [[value=defaultFunc(self)]])
                        tinsert(gbody, [[if value ~= nil then]])

                        if ValidateFlags(FLAG_GET_STATIC, propToken) then
                            if ValidateFlags(FLAG_GET_SETFALSE, propToken) then
                                if ValidateFlags(FLAG_GET_SETWEAK, propToken) then
                                    tinsert(gbody, [[local container=_NSInfo[self].WeakStaticFields]])
                                    tinsert(gbody, [[if not container then]])
                                    tinsert(gbody, [[container = setmetatable({}, WEAK_VALUE)]])
                                    tinsert(gbody, [[_NSInfo[self].WeakStaticFields = container]])
                                    tinsert(gbody, [[end]])
                                else
                                    tinsert(gbody, [[local container=_NSInfo[self].StaticFields]])
                                    tinsert(gbody, [[if not container then]])
                                    tinsert(gbody, [[container = {}]])
                                    tinsert(gbody, [[_NSInfo[self].StaticFields = container]])
                                    tinsert(gbody, [[end]])
                                end
                                tinsert(gbody, [[container[field]=value]])
                            else
                                tinsert(gbody, [[self[name]=value]])
                            end
                        else
                            if ValidateFlags(FLAG_GET_SETFALSE, propToken) then
                                if ValidateFlags(FLAG_GET_SETWEAK, propToken) then
                                    tinsert(gbody, [[local container=WEAK_VALUE_MAP[self] ]])
                                    tinsert(gbody, [[if not container then]])
                                    tinsert(gbody, [[container = setmetatable({}, WEAK_VALUE)]])
                                    tinsert(gbody, [[WEAK_VALUE_MAP[self] = container]])
                                    tinsert(gbody, [[end]])
                                    tinsert(gbody, [[container[field]=value]])
                                else
                                    tinsert(gbody, [[rawset(self, field, value)]])
                                end
                            else
                                tinsert(gbody, [[self[name]=value]])
                            end
                        end

                        tinsert(gbody, [[end]])
                    elseif ValidateFlags(FLAG_GET_DEFAULT, propToken) then
                        tinsert(gbody, [[value=default]])
                    end

                    tinsert(gbody, [[end]])
                end

                -- Clone
                if ValidateFlags(FLAG_GET_GETCLONE, propToken) then
                    tinsert(gHeader, "deepClone")
                    tinsert(gbody, [[value=CloneObj(value, deepClone)]])
                end

                tinsert(gbody, [[return value]])
            end
            tinsert(gbody, [[end]])

            if needName then
                tinsert(gHeader, "name")
            end

            if #gHeader > 0 then
                gbody[1] = "local " .. tblconcat(gHeader, ",") .. "=..."
            end
            _PropGetBuilder[propToken] = loadInEnv(tblconcat(gbody, "\n"), tostring(propToken))
            CACHE_TABLE(gHeader)
            CACHE_TABLE(gbody)
        end

        local rs = _PropGetBuilder[propToken](unpack(upValues))
        CACHE_TABLE(upValues)
        return rs
    end

    _PropSetBuilder = {}

    FLAG_SET_DISABLE = 2^0
    FLAG_SET_TYPE = 2^1
    FLAG_SET_CLONE = 2^2
    FLAG_SET_SET = 2^3
    FLAG_SET_SETMETHOD = 2^4
    FLAG_SET_FIELD = 2^5
    FLAG_SET_DEFAULT = 2^6
    FLAG_SET_SETWEAK = 2^7
    FLAG_SET_RETAIN = 2^8
    FLAG_SET_SIMPLEDEFAULT = 2^9
    FLAG_SET_HANDLER = 2^10
    FLAG_SET_EVENT = 2^11
    FLAG_SET_STATIC = 2^12

    function BuildPropertySet(name, oper)
        if oper.Set and not oper.Type and not oper.SetClone then
            return oper.Set
        end

        local propToken = 0
        local upValues = CACHE_TABLE()
        local needName = false

        -- Calc the token
        if oper.Set == false or (not oper.Set and not oper.SetMethod and oper.Field == nil) then
            propToken = TurnOnFlags(FLAG_SET_DISABLE, propToken)
            needName = true
        else
            if oper.Type then
                propToken = TurnOnFlags(FLAG_SET_TYPE, propToken)
                tinsert(upValues, oper.Type)
                needName = true
            end

            if oper.SetClone then
                propToken = TurnOnFlags(FLAG_SET_CLONE, propToken)
                tinsert(upValues, oper.SetDeepClone or false)
            end

            if oper.Set then
                propToken = TurnOnFlags(FLAG_SET_SET, propToken)
                tinsert(upValues, oper.Set)
            elseif oper.SetMethod and not oper.IsStatic then
                propToken = TurnOnFlags(FLAG_SET_SETMETHOD, propToken)
                tinsert(upValues, oper.SetMethod)
            elseif oper.Field then
                propToken = TurnOnFlags(FLAG_SET_FIELD, propToken)
                tinsert(upValues, oper.Field)

                if oper.SetWeak then
                    propToken = TurnOnFlags(FLAG_SET_SETWEAK, propToken)
                end

                if oper.IsStatic then
                    propToken = TurnOnFlags(FLAG_SET_STATIC, propToken)
                end

                if oper.Default ~= nil then
                    propToken = TurnOnFlags(FLAG_SET_DEFAULT, propToken)
                    tinsert(upValues, oper.Default)

                    if type(oper.Default) ~= "table" then
                        propToken = TurnOnFlags(FLAG_SET_SIMPLEDEFAULT, propToken)
                    end
                end

                if oper.SetRetain then
                    propToken = TurnOnFlags(FLAG_SET_RETAIN, propToken)
                end

                if oper.Handler then
                    propToken = TurnOnFlags(FLAG_SET_HANDLER, propToken)
                    tinsert(upValues, oper.Handler)
                    needName = true
                end

                if oper.Event and not oper.IsStatic then
                    propToken = TurnOnFlags(FLAG_SET_EVENT, propToken)
                    tinsert(upValues, oper.Event)
                    needName = true
                end
            end
        end

        if needName then
            tinsert(upValues, name)
        end

        -- Building
        if not _PropSetBuilder[propToken] then
            local gHeader = CACHE_TABLE()
            local gbody = CACHE_TABLE()

            tinsert(gbody, "") -- Remain for closure values
            tinsert(gbody, [[return function(self, value)]])

            if ValidateFlags(FLAG_SET_DISABLE, propToken) then
                tinsert(gbody, [[error(("%s can't be set."):format(name), 3)]])
            else
                if ValidateFlags(FLAG_SET_TYPE, propToken) then
                    tinsert(gHeader, "vtype")
                    tinsert(gbody, [[value = Validate4Type(vtype, value, name, name, 4)]])
                end

                if ValidateFlags(FLAG_SET_CLONE, propToken) then
                    tinsert(gHeader, "deepClone")
                    tinsert(gbody, [[value = CloneObj(value, deepClone)]])
                end

                if ValidateFlags(FLAG_SET_SET, propToken) then
                    tinsert(gHeader, "set")
                    tinsert(gbody, [[return set(self, value)]])
                elseif ValidateFlags(FLAG_SET_SETMETHOD, propToken) then
                    tinsert(gHeader, "setmethod")
                    tinsert(gbody, [[return _NSInfo[getmetatable(self)].Cache[setmethod](self, value)]])
                elseif ValidateFlags(FLAG_SET_FIELD, propToken) then
                    tinsert(gHeader, "field")

                    if ValidateFlags(FLAG_SET_STATIC, propToken) then
                        if ValidateFlags(FLAG_SET_SETWEAK, propToken) then
                            tinsert(gbody, [[local container=_NSInfo[self].WeakStaticFields ]])
                            tinsert(gbody, [[if not container then]])
                            tinsert(gbody, [[container = setmetatable({}, WEAK_VALUE)]])
                            tinsert(gbody, [[_NSInfo[self].WeakStaticFields = container]])
                            tinsert(gbody, [[end]])
                        else
                            tinsert(gbody, [[local container=_NSInfo[self].StaticFields ]])
                            tinsert(gbody, [[if not container then]])
                            tinsert(gbody, [[container = {}]])
                            tinsert(gbody, [[_NSInfo[self].StaticFields = container]])
                            tinsert(gbody, [[end]])
                        end
                        tinsert(gbody, [[local old = container[field] ]])
                    else
                        if ValidateFlags(FLAG_SET_SETWEAK, propToken) then
                            tinsert(gbody, [[local container=WEAK_VALUE_MAP[self] ]])
                            tinsert(gbody, [[if not container then]])
                            tinsert(gbody, [[container = setmetatable({}, WEAK_VALUE)]])
                            tinsert(gbody, [[WEAK_VALUE_MAP[self] = container]])
                            tinsert(gbody, [[end]])
                            tinsert(gbody, [[local old = rawget(container, field)]])
                        else
                            tinsert(gbody, [[local old = rawget(self, field)]])
                        end
                    end

                    if ValidateFlags(FLAG_SET_DEFAULT, propToken) then
                        tinsert(gHeader, "default")
                        tinsert(gbody, [[if old == nil then old = default end]])
                        tinsert(gbody, [[if value == nil then value = default end]])
                    end

                    tinsert(gbody, [[if old == value then return end]])

                    if ValidateFlags(FLAG_SET_STATIC, propToken) then
                        tinsert(gbody, [[container[field]=value]])
                    else
                        if ValidateFlags(FLAG_SET_SETWEAK, propToken) then
                            tinsert(gbody, [[rawset(container, field, value)]])
                        else
                            tinsert(gbody, [[rawset(self, field, value)]])
                        end
                    end

                    if ValidateFlags(FLAG_SET_RETAIN, propToken) then
                        tinsert(gbody, [[if old and old ~= default then DisposeObject(old) old = nil end]])
                    end

                    if ValidateFlags(FLAG_SET_DEFAULT, propToken) and not ValidateFlags(FLAG_SET_SIMPLEDEFAULT, propToken) then
                        tinsert(gbody, [[if old == default then old = nil end]])
                    end

                    if ValidateFlags(FLAG_SET_HANDLER, propToken) then
                        tinsert(gHeader, "handler")
                        tinsert(gbody, [[handler(self, value, old, name)]])
                    end

                    if ValidateFlags(FLAG_SET_EVENT, propToken) then
                        tinsert(gHeader, "evt")
                        tinsert(gbody, [[return evt(self, value, old, name)]])
                    end
                end
            end

            tinsert(gbody, [[end]])

            if needName then
                tinsert(gHeader, "name")
            end

            if #gHeader > 0 then
                gbody[1] = "local " .. tblconcat(gHeader, ",") .. "=..."
            end
            _PropSetBuilder[propToken] = loadInEnv(tblconcat(gbody, "\n"), tostring(propToken))
            CACHE_TABLE(gHeader)
            CACHE_TABLE(gbody)
        end

        local rs = _PropSetBuilder[propToken](unpack(upValues))
        CACHE_TABLE(upValues)
        return rs
    end

    -- Feature Token For class & interface
    FLAG_HAS_METHOD       = 2^0
    FLAG_HAS_PROPERTY     = 2^1
    FLAG_HAS_EVENT        = 2^2

    function RefreshCache(ns)
        local info              = _NSInfo[ns]
        local cache             = CACHE_TABLE()
        local cache4Interface   = CACHE_TABLE()
        local iCache            = CACHE_TABLE()
        local iToken            = 0
        local installDispose    = false

        if info.SuperClass then CloneInterfaceCache(cache4Interface, _NSInfo[info.SuperClass].Cache4Interface, cache) end
        if info.ExtendInterface then
            for _, IF in ipairs(info.ExtendInterface) do CloneInterfaceCache(cache4Interface, _NSInfo[IF].Cache4Interface, cache) end
            CloneInterfaceCache(cache4Interface, info.ExtendInterface, cache)
        end

        CACHE_TABLE(cache)
        cache = info.Cache4Interface
        if next(cache4Interface) then
            info.Cache4Interface = cache4Interface
        else
            info.Cache4Interface = nil
            CACHE_TABLE(cache4Interface)
        end
        if cache then CACHE_TABLE(cache) end

        if info.SuperClass then
            local sinfo = _NSInfo[info.SuperClass]
            CloneWithOverride(iCache, sinfo.Cache)

            if sinfo.Cache[DISPOSE_METHOD] then installDispose = true end

            if ValidateFlags(FLAG_HAS_METHOD, sinfo.FeatureToken) then iToken = TurnOnFlags(FLAG_HAS_METHOD, iToken) end
            if ValidateFlags(FLAG_HAS_PROPERTY, sinfo.FeatureToken) then iToken = TurnOnFlags(FLAG_HAS_PROPERTY, iToken) end
            if ValidateFlags(FLAG_HAS_EVENT, sinfo.FeatureToken) then iToken = TurnOnFlags(FLAG_HAS_EVENT, iToken) end
        end

        if info.ExtendInterface then
            for _, IF in ipairs(info.ExtendInterface) do
                local sinfo = _NSInfo[IF]
                CloneWithoutOverride(iCache, sinfo.Cache)

                if sinfo[DISPOSE_METHOD] then installDispose = true end

                if ValidateFlags(FLAG_HAS_METHOD, sinfo.FeatureToken) then iToken = TurnOnFlags(FLAG_HAS_METHOD, iToken) end
                if ValidateFlags(FLAG_HAS_PROPERTY, sinfo.FeatureToken) then iToken = TurnOnFlags(FLAG_HAS_PROPERTY, iToken) end
                if ValidateFlags(FLAG_HAS_EVENT, sinfo.FeatureToken) then iToken = TurnOnFlags(FLAG_HAS_EVENT, iToken) end
            end
        end

        -- Cache for event
        if info.Event then
            CloneWithOverride(iCache, info.Event)
            iToken = TurnOnFlags(FLAG_HAS_EVENT, iToken)
        end

        -- Cache for Method
        if info.Method then
            local hasNoStatic = false
            for key, value in pairs(info.Method) do
                -- No static methods
                if not (info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[key])) then
                    hasNoStatic = true
                    iCache[key] = value
                end
            end
            if hasNoStatic then iToken = TurnOnFlags(FLAG_HAS_METHOD, iToken) end
        end

        -- Cache the Dispose
        if info.Type == TYPE_CLASS and (info[DISPOSE_METHOD] or installDispose) then
            iCache[DISPOSE_METHOD] = DisposeObject
            iToken = TurnOnFlags(FLAG_HAS_METHOD, iToken)
        end

        -- Cache for Property
        -- Validate the properties
        if info.Property then
            local autoProp      = ValidateFlags(MD_AUTO_PROPERTY, info.Modifier)
            local hasNoStatic   = false
            local newEvent      = false
            local newMethod     = false
            for name, prop in pairs(info.Property) do
                if prop.Predefined then
                    local set = prop.Predefined

                    prop.Predefined = nil

                    for k, v in pairs(set) do
                        if type(k) == "string" then
                            k = strlower(k)

                            if k == "get" then
                                if type(v) == "function" or type(v) == "boolean" then
                                    prop.Get = v
                                elseif type(v) == "string" then
                                    prop.GetMethod = v
                                end
                            elseif k == "set" then
                                if type(v) == "function" or type(v) == "boolean" then
                                    prop.Set = v
                                elseif type(v) == "string" then
                                    prop.SetMethod = v
                                end
                            elseif k == "getmethod" then
                                if type(v) == "string" then prop.GetMethod = v end
                            elseif k == "setmethod" then
                                if type(v) == "string" then prop.SetMethod = v end
                            elseif k == "field" then
                                prop.Field = v ~= name and v or nil
                            elseif k == "type" then
                                local tInfo = _NSInfo[v]
                                if tInfo and tInfo.Type then prop.Type = v end
                            elseif k == "default" then
                                prop.Default = v
                            elseif k == "event" then
                                if type(v) == "string" or getmetatable(v) == Event then
                                    prop.Event = v
                                elseif EVENT_MAP[v] then
                                    prop.Event = EVENT_MAP[v]
                                end
                            elseif k == "handler" then
                                if type(v) == "string" then
                                    prop.HandlerName = v
                                elseif type(v) == "function" then
                                    prop.Handler = v
                                end
                            elseif k == "setter" and type(v) == "number" and floor(v) == v and v > 0 and v <= _NSInfo[Setter].MaxValue then
                                prop.Setter = v
                            elseif k == "getter" and type(v) == "number" and floor(v) == v and v > 0 and v <= _NSInfo[Getter].MaxValue then
                                prop.Getter = v
                            elseif k == "isstatic" or k == "static" then
                                prop.IsStatic = v and true or false
                            end
                        end
                    end

                    -- Validate the default
                    if type(prop.Default) == "function" then
                        prop.DefaultFunc = prop.Default
                        prop.Default = nil
                    end

                    if prop.Default ~= nil and prop.Type then
                        prop.Default = GetValidatedValue(prop.Type, prop.Default)
                    end

                    -- Clear
                    if prop.Get ~= nil then prop.GetMethod = nil end
                    if prop.Set ~= nil then prop.SetMethod = nil end

                    local uname = name:gsub("^%a", strupper)

                    if prop.IsStatic then
                        -- Only use static methods
                        if prop.GetMethod then
                            if info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[prop.GetMethod]) then
                                prop.Get = info.Method[prop.GetMethod]
                            end
                            prop.GetMethod = nil
                        end
                        if prop.SetMethod then
                            if info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[prop.SetMethod]) then
                                prop.Set = info.Method[prop.SetMethod]
                            end
                            prop.SetMethod = nil
                        end

                        if info.FeatureModifier and info.Method then
                            -- Auto generate GetMethod
                            if prop.Get == true or (autoProp and prop.Get == nil and prop.Field == nil) then
                                prop.Get =  nil

                                -- GetMethod
                                if info.Method["get" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["get" .. uname]) then
                                    prop.Get = info.Method["get" .. uname]
                                elseif info.Method["Get" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["Get" .. uname]) then
                                    prop.Get = info.Method["Get" .. uname]
                                elseif prop.Type == Boolean or prop.Type == BooleanNil or prop.Type == RawBoolean then
                                    -- FlagEnabled -> IsFlagEnabled
                                    if info.Method["is" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["is" .. uname]) then
                                        prop.Get = info.Method["is" .. uname]
                                    elseif info.Method["Is" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["Is" .. uname]) then
                                        prop.Get = info.Method["Is" .. uname]
                                    else
                                        -- FlagEnable -> IsEnableFlag
                                        local pattern = ParseAdj(uname, true)

                                        if pattern then
                                            for mname, mod in pairs(info.FeatureModifier) do
                                                if info.Method[mname] and ValidateFlags(MD_STATIC_FEATURE, mod) and mname:match(pattern) then
                                                    prop.Get = info.Method[mname]
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- Auto generate SetMethod
                            if prop.Set == true or (autoProp and prop.Set == nil and prop.Field == nil) then
                                prop.Set = nil

                                -- SetMethod
                                if info.Method["set" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["set" .. uname]) then
                                    prop.Set = info.Method["set" .. uname]
                                elseif info.Method["Set" .. uname] and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier["Set" .. uname]) then
                                    prop.Set = info.Method["Set" .. uname]
                                elseif prop.Type == Boolean or prop.Type == BooleanNil or prop.Type == RawBoolean then
                                    -- FlagEnabled -> EnableFlag, FlagDisabled -> DisableFlag
                                    local pattern = ParseAdj(uname)

                                    if pattern then
                                        for mname, mod in pairs(info.FeatureModifier) do
                                            if info.Method[mname] and ValidateFlags(MD_STATIC_FEATURE, mod) and mname:match(pattern) then
                                                prop.Set = info.Method[mname]
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        if prop.GetMethod and type(iCache[prop.GetMethod]) ~= "function" then prop.GetMethod = nil end
                        if prop.SetMethod and type(iCache[prop.SetMethod]) ~= "function" then prop.SetMethod = nil end

                        -- Auto generate GetMethod
                        if prop.Get == true or (autoProp and prop.Get == nil and not prop.GetMethod and prop.Field == nil) then
                            prop.Get = nil

                            -- GetMethod
                            if type(iCache["get" .. uname]) == "function" then
                                prop.GetMethod = "get" .. uname
                            elseif type(iCache["Get" .. uname]) == "function" then
                                prop.GetMethod = "Get" .. uname
                            elseif prop.Type == Boolean or prop.Type == BooleanNil or prop.Type == RawBoolean then
                                -- FlagEnabled -> IsFlagEnabled
                                if type(iCache["is" .. uname]) == "function" then
                                    prop.GetMethod = "is" .. uname
                                elseif type(iCache["Is" .. uname]) == "function" then
                                    prop.GetMethod = "Is" .. uname
                                else
                                    -- FlagEnable -> IsEnableFlag
                                    local pattern = ParseAdj(uname, true)

                                    if pattern then
                                        for mname, method in pairs(iCache) do
                                            if type(method) == "function" and mname:match(pattern) then prop.GetMethod = mname break end
                                        end
                                    end
                                end
                            end
                        end

                        -- Auto generate SetMethod
                        if prop.Set == true or (autoProp and prop.Set == nil and not prop.SetMethod and prop.Field == nil) then
                            prop.Set = nil

                            -- SetMethod
                            if type(iCache["set" .. uname]) == "function" then
                                prop.SetMethod = "set" .. uname
                            elseif type(iCache["Set" .. uname]) == "function" then
                                prop.SetMethod = "Set" .. uname
                            elseif prop.Type == Boolean or prop.Type == BooleanNil or prop.Type == RawBoolean then
                                -- FlagEnabled -> EnableFlag, FlagDisabled -> DisableFlag
                                local pattern = ParseAdj(uname)

                                if pattern then
                                    for mname, method in pairs(iCache) do
                                        if type(method) == "function" and mname:match(pattern) then prop.SetMethod = mname break end
                                    end
                                end
                            end
                        end
                    end

                    -- Validate the Event
                    if type(prop.Event) == "string" and not prop.IsStatic then
                        local evt = iCache[prop.Event]
                        if getmetatable(evt) then
                            prop.Event = evt
                        elseif evt == nil then
                            -- Auto create
                            local ename = prop.Event
                            evt = Event(ename)
                            info.Event = info.Event or {}
                            info.Event[ename] = evt
                            iCache[ename] = evt
                            prop.Event = evt

                            newEvent = true
                        else
                            prop.Event = nil
                        end
                    else
                        prop.Event = nil
                    end

                    -- Validate the Handler
                    if prop.HandlerName then
                        prop.Handler = iCache[prop.HandlerName]
                        if type(prop.Handler) ~= "function" then prop.Handler = nil end
                    end

                    -- Validate the Setter
                    if prop.Setter then
                        prop.SetDeepClone = ValidateFlags(Setter.DeepClone, prop.Setter) or nil
                        prop.SetClone = ValidateFlags(Setter.Clone, prop.Setter) or prop.SetDeepClone

                        if prop.Set == nil and not prop.SetMethod then
                            if ValidateFlags(Setter.Retain, prop.Setter) and prop.Type then
                                local tinfo = _NSInfo[prop.Type]

                                if tinfo.Type == TYPE_CLASS or tinfo.Type == TYPE_INTERFACE then
                                    prop.SetRetain = true
                                end
                            end

                            if prop.Get == nil and not prop.GetMethod then
                                if ValidateFlags(Setter.Weak, prop.Setter) then prop.SetWeak = true end
                            end
                        end

                        prop.Setter = nil
                    end

                    -- Validate the Getter
                    if prop.Getter then
                        prop.GetDeepClone = ValidateFlags(Getter.DeepClone, prop.Getter) or nil
                        prop.GetClone = ValidateFlags(Getter.Clone, prop.Getter) or prop.GetDeepClone

                        prop.Getter = nil
                    end

                    -- Auto generate Default
                    if prop.Type and prop.Default == nil and prop.DefaultFunc == nil then
                        local pinfo = _NSInfo[prop.Type]
                        if pinfo and (pinfo.Type == TYPE_STRUCT or pinfo.Type == TYPE_ENUM) then prop.Default = pinfo.Default end
                    end

                    -- Auto generate Field or methods
                    local genField = false
                    if (prop.Set == nil or (prop.Set == false and prop.DefaultFunc)) and not prop.SetMethod and prop.Get == nil and not prop.GetMethod then
                        if prop.Field == true then prop.Field = nil end
                        genField = true

                        prop.Field = prop.Field or "_" .. info.Name:match("^_*(.-)$") .. "_" .. uname
                    end

                    if not SAVE_MEMORY then
                        prop.RawGet = BuildPropertyGet(name, prop)
                        prop.RawSet = BuildPropertySet(name, prop)
                    end

                    if genField and set.Synthesize and prop.Set == nil then
                        local getName, setName

                        if set.Synthesize == __Synthesize__.NameCases.Pascal then
                            getName, setName = "Get" .. uname, "Set" .. uname
                            if prop.Type == Boolean or prop.Type == BooleanNil or prop.Type == RawBoolean then getName = "Is" .. uname end
                        elseif set.Synthesize == __Synthesize__.NameCases.Camel then
                            getName, setName = "get" .. uname, "set" .. uname
                            if prop.Type == Boolean or prop.Type == BooleanNil or prop.Type == RawBoolean then getName = "is" .. uname end
                        end

                        if set.SynthesizeGet then getName = set.SynthesizeGet end
                        if set.SynthesizeSet then setName = set.SynthesizeSet end

                        info.Method = info.Method or {}
                        info.Method[getName] = prop.RawGet or BuildPropertyGet(name, prop)
                        info.Method[setName] = prop.RawSet or BuildPropertySet(name, prop)

                        if prop.IsStatic then
                            if not SAVE_MEMORY then
                                prop.RawGet = info.Method[getName]
                                prop.RawSet = info.Method[setName]
                            else
                                prop.Get = info.Method[getName]
                                prop.Set = info.Method[setName]
                            end

                            info.FeatureModifier = info.FeatureModifier or {}
                            info.FeatureModifier[getName] = TurnOnFlags(MD_STATIC_FEATURE, info.FeatureModifier[getName])
                            info.FeatureModifier[setName] = TurnOnFlags(MD_STATIC_FEATURE, info.FeatureModifier[setName])
                        else
                            iCache[getName] = info.Method[getName]
                            iCache[setName] = info.Method[setName]

                            newMethod = true

                            prop.GetMethod = getName
                            prop.SetMethod = setName

                            if not SAVE_MEMORY then
                                prop.RawGet = BuildPropertyGet(name, prop)
                                prop.RawSet = BuildPropertySet(name, prop)
                            end
                        end
                    end
                end
                if not prop.IsStatic then hasNoStatic = true end
            end

            --- self property
            CloneWithOverride(iCache, info.Property, true)
            if hasNoStatic then iToken = TurnOnFlags(FLAG_HAS_PROPERTY, iToken) end
            if newEvent then iToken = TurnOnFlags(FLAG_HAS_EVENT, iToken) end
            if newMethod then iToken = TurnOnFlags(FLAG_HAS_METHOD, iToken) end
        end

        -- AutoCache
        if info.SuperClass and _NSInfo[info.SuperClass].AutoCache and not info.AutoCache then
            info.AutoCache = true
        end

        -- Simple Class Check(No Constructor, No Property)
        if info.Type == TYPE_CLASS then
            info.IsSimpleClass = (not (info.Constructor or ValidateFlags(FLAG_HAS_PROPERTY, iToken) or (info.SuperClass and not _NSInfo[info.SuperClass].IsSimpleClass))) and true or nil
        end

        -- One-required method interface check
        if info.Type == TYPE_INTERFACE then
            local isOneReqMethod = nil
            if info.FeatureModifier and info.Method then
                for name, mod in pairs(info.FeatureModifier) do
                    if info.Method[name] and ValidateFlags(MD_REQUIRE_FEATURE, mod) then
                        if isOneReqMethod then isOneReqMethod = false break end
                        isOneReqMethod = name
                    end
                end

                if info.ExtendInterface then
                    if isOneReqMethod ~= false then
                        for _, IF in ipairs(info.ExtendInterface) do
                            local iInfo = _NSInfo[IF]
                            if isOneReqMethod then
                                if iInfo.IsOneReqMethod and iInfo.IsOneReqMethod ~= isOneReqMethod then
                                    isOneReqMethod = false
                                    break
                                elseif iInfo.IsOneReqMethod == false then
                                    isOneReqMethod = false
                                    break
                                end
                            else
                                if iInfo.IsOneReqMethod then
                                    isOneReqMethod = iInfo.IsOneReqMethod
                                elseif iInfo.IsOneReqMethod == false then
                                    isOneReqMethod = false
                                    break
                                end
                            end
                        end
                    end
                end
            end
            info.IsOneReqMethod = isOneReqMethod
        end

        -- Reset the cache
        cache = info.Cache
        info.Cache = iCache
        info.FeatureToken = iToken
        if cache then CACHE_TABLE(cache) end

        -- Regenerate MetaTable
        if info.Type == TYPE_CLASS then
            GenerateMetaTable(info)
            info.Ctor = nil
        end

        -- Refresh branch
        if info.ChildClass then
            for _, subcls in ipairs(info.ChildClass) do RefreshCache(subcls) end
        elseif info.ExtendChild then
            for _, subcls in ipairs(info.ExtendChild) do RefreshCache(subcls) end
        end
    end

    function RefreshStruct(strt)
        local info = _NSInfo[strt]

        if info[0] then
            info.SubType = STRUCT_TYPE_ARRAY

            local cache = info.Members
            info.Members = nil
            info.ArrayElement = info[0]
            if cache then CACHE_TABLE(cache) end
        elseif info[1] then
            info.SubType = STRUCT_TYPE_MEMBER

            local members = CACHE_TABLE()

            for _, mem in ipairs(info) do
                if mem.Predefined then
                    for k, v in pairs(mem.Predefined) do
                        if type(k) == "string" then
                            k = k:lower()

                            if k == "type" then
                                if IsNameSpace(v) and _NSInfo[v].Type then
                                    mem.Type = v
                                end
                            elseif k == "default" then
                                mem.Default = v
                            elseif k == "require" then
                                mem.Require = true
                            end
                        end
                    end

                    mem.Predefined = nil

                    if mem.Require then
                        mem.Default = nil
                    elseif mem.Type then
                        if mem.Default ~= nil then
                            mem.Default = GetValidatedValue(mem.Type, mem.Default)
                        end
                        if mem.Default == nil and _NSInfo[mem.Type].Default ~= nil then
                            mem.Default = _NSInfo[mem.Type].Default
                        end
                    end
                end

                members[mem.Name] = mem
                tinsert(members, mem)
            end

            local cache = info.Members
            info.Members = members
            info.ArrayElement = nil
            if cache then CACHE_TABLE(cache) end
        else
            info.SubType = STRUCT_TYPE_CUSTOM

            if info.Default ~= nil and not pcall(info.RawValidate, info, info.Default) then
                info.Default = nil
            end

            local cache = info.Members
            info.Members = nil
            info.ArrayElement = nil
            if cache then CACHE_TABLE(cache) end
        end

        if info.BaseStruct and _NSInfo[info.BaseStruct].SubType ~= info.SubType then
            info.BaseStruct = nil
        end

        -- Save validator and initializer
        local i = STRT_START_VALID
        while info[i] do info[i] = nil i = i + 1 end
        i = STRT_START_INIT
        while info[i] do info[i] = nil i = i + 1 end

        if info.BaseStruct then
            local binfo = _NSInfo[info.BaseStruct]

            i = STRT_START_VALID
            while binfo[i] do info[i] = binfo[i] i = i + 1 end
            info[i] = info.Validator

            i = STRT_START_INIT
            while binfo[i] do info[i] = binfo[i] i = i + 1 end
            info[i] = info.Initializer
        else
            info[STRT_START_VALID] = info.Validator
            info[STRT_START_INIT]  = info.Initializer
        end

        -- Cache methods
        if info.Method or (info.BaseStruct and _NSInfo[info.BaseStruct].Cache) then
            local cache = CACHE_TABLE()
            if info.BaseStruct and _NSInfo[info.BaseStruct].Cache then
                for k, v in pairs(_NSInfo[info.BaseStruct].Cache) do
                    cache[k] = v
                end
            end

            if info.Method then
                for k, v in pairs(info.Method) do
                    if not(info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[k])) then
                        cache[k] = v
                    end
                end
            end

            if not next(cache) then CACHE_TABLE(cache) cache = nil end
            local temp = info.Cache
            info.Cache = cache
            if temp then CACHE_TABLE(temp) end
        else
            local temp = info.Cache
            info.Cache = nil
            if temp then CACHE_TABLE(temp) end
        end

        info.RawValidate = SAVE_MEMORY and ValidateStruct or GenerateRawValidate(info)
    end
end

------------------------------------------------------
----------------- Feature Definition -----------------
------------------------------------------------------
do
    function checkTypeParams(...)
        local cnt = select('#', ...)
        local env, target, defintion, stack

        if cnt > 0 then
            if cnt > 4 then cnt = 4 end

            stack = select(cnt, ...)

            if type(stack) == "number" then
                cnt = cnt - 1
            else
                stack = nil
            end

            if cnt == 1 then
                local val = select(1, ...)
                local ty = type(val)

                if ty == "table" then
                    if getmetatable(val) == nil then
                        defintion = val
                    elseif _NSInfo[val] then
                        target = val
                    end
                elseif ty == "string" then
                    if val:find("^[%w_]+$") then
                        target = val
                    else
                        defintion = val
                    end
                elseif ty == "function" then
                    defintion = val
                elseif _NSInfo[val] then
                    target = val
                end
            elseif cnt == 2 then
                local val = select(2, ...)
                local ty = type(val)

                if ty == "table" then
                    if getmetatable(val) == nil then
                        defintion = val
                    elseif _NSInfo[val] then
                        target = val
                    end
                elseif ty == "string" then
                    if val:find("^[%w_]+$") then
                        target = val
                    else
                        defintion = val
                    end
                elseif ty == "function" then
                    defintion = val
                elseif _NSInfo[val] then
                    target = val
                end

                -- Check first value
                val = select(1, ...)
                ty = type(val)

                if target then
                    if ty == "table" then env = val end
                elseif defintion then
                    if ty == "table" then
                        if _NSInfo[val] then
                            target = val
                        else
                            env = val
                        end
                    elseif ty == "string" then
                        if val:find("^[%w_]+$") then
                            target = val
                        end
                    elseif _NSInfo[val] then
                        target = val
                    end
                else
                    if ty == "table" then
                        if getmetatable(val) == nil then
                            defintion = val
                        elseif _NSInfo[val] then
                            target = val
                        end
                    elseif ty == "string" then
                        if val:find("^[%w_]+$") then
                            target = val
                        else
                            defintion = val
                        end
                    elseif ty == "function" then
                        defintion = val
                    elseif _NSInfo[val] then
                        target = val
                    end
                end
            elseif cnt == 3 then
                -- No match just check
                env, target, defintion = ...
                if type(env) ~= "table" then env = nil end
                if type(target) ~= "string" and not _NSInfo[target] then target = nil end
                if type(target) == "string" and not target:find("^[%w_]+$") then target = nil end
                local ty = type(defintion)
                if not (ty == "function" or ty == "table" or ty == "string") then defintion = nil end
            end
        end

        stack = stack or 2

        if type(defintion) == "string" then
            local ret, msg = loadstring("return function(_ENV) " .. defintion .. " end")
            if not ret then error(msg:match("%d+:%s*(.-)$") or msg, stack + 1) end
            ret, msg = pcall(ret)
            if not ret then error(msg:match("%d+:%s*(.-)$") or msg, stack + 1) end
            defintion = msg
        end

        return env, target, defintion, stack
    end

    function IsPropertyReadable(ns, name)
        local info = _NSInfo[ns]

        if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
            local prop = info.Cache[name]
            if prop then return type(prop) == "table" and getmetatable(prop) == nil and (prop.Get or prop.GetMethod or prop.Field or prop.Default ~= nil) and true or false end
            prop = info.Property and info.Property[name]
            if prop and prop.IsStatic then return (prop.Get or prop.GetMethod or prop.Default ~= nil) and true or false end
        end
    end

    function IsPropertyWritable(ns, name)
        local info = _NSInfo[ns]

        if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
            local prop = info.Cache[name]
            if prop then return type(prop) == "table" and getmetatable(prop) == nil and (prop.Set or prop.SetMethod or prop.Field) and true or false end
            prop = info.Property and info.Property[name]
            if prop and prop.IsStatic then return (prop.Set or prop.SetMethod) and true or false end
        end
    end

    function IsFinalFeature(ns, name, isSuper)
        ns = _NSInfo[ns]

        if not ns then return false end

        if not name then
            return ValidateFlags(MD_FINAL_FEATURE, ns.Modifier)
        else
            if isSuper and not ns.Cache[name] then return nil end

            -- Check self
            if ns.FeatureModifier and ValidateFlags(MD_FINAL_FEATURE, ns.FeatureModifier[name]) then return true end
            if ns.Method and ns.Method[name] then return isSuper and ValidateFlags(MD_FINAL_FEATURE, ns.Modifier) or false end
            if ns.Property and ns.Property[name] then return isSuper and ValidateFlags(MD_FINAL_FEATURE, ns.Modifier) or false end

            -- Check Super class
            if ns.SuperClass then
                local ret = IsFinalFeature(ns.SuperClass, name, true)
                if ret ~= nil then return ret end
            end

            -- Check Extened interfaces
            if ns.ExtendInterface then
                for _, IF in ipairs(ns.ExtendInterface) do
                    local ret = IsFinalFeature(IF, name, true)
                    if ret ~= nil then return ret end
                end
            end

            return false
        end
    end

    function IsExtend(IF, cls)
        if not IF or not cls or not _NSInfo[IF] or _NSInfo[IF].Type ~= TYPE_INTERFACE or not _NSInfo[cls] then return false end

        if IF == cls then return true end

        local cache = _NSInfo[cls].Cache4Interface
        if cache then for _, pIF in ipairs(cache) do if pIF == IF then return true end end end

        return false
    end

    function IsChildClass(cls, child)
        if not cls or not child or not _NSInfo[cls] or _NSInfo[cls].Type ~= TYPE_CLASS then return false end

        if cls == child then return true end

        local info = _NSInfo[child]

        if not info or info.Type ~= TYPE_CLASS then return false end

        local scls = info.SuperClass

        while scls and scls ~= cls do scls = _NSInfo[scls].SuperClass end

        return scls == cls
    end

    function UpdateMeta4Child(meta, cls, pre, now)
        if pre == now then return end

        local info = _NSInfo[cls]
        local key = _KeyMeta[meta]

        if not info.MetaTable[key] or info.MetaTable[key] == pre then
            return SaveMethod(info, meta, now)
        end
    end

    function UpdateMeta4Children(meta, sub, pre, now)
        if sub and pre ~= now then for _, cls in ipairs(sub) do UpdateMeta4Child(meta, cls, pre, now) end end
    end

    function SaveInheritEnableObjMethodAttr(cls)
        local info = _NSInfo[cls]
        info.EnableObjMethodAttr = true
        info.InheritEnableObjMethodAttr = true

        if info.ChildClass then
            for _, scls in ipairs(info.ChildClass) do
                SaveInheritEnableObjMethodAttr(scls)
            end
        end
    end

    function SaveMethod(info, key, value)
        local storage = info
        local isMeta, rMeta, oldValue, isConstructor
        local rkey = key

        if key == info.Name then
            if info.Type == TYPE_CLASS then
                -- Constructor
                if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the constructor."):format(tostring(info.Owner))) end
                isConstructor = true
                rkey = "Constructor"
            elseif info.Type == TYPE_INTERFACE then
                -- Initializer
                if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the initializer."):format(tostring(info.Owner))) end
                info.Initializer = value
                return
            elseif info.Type == TYPE_STRUCT then
                -- Valiator
                if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the validator."):format(tostring(info.Owner))) end
                info.Validator = value
                return
            end
        elseif key == DISPOSE_METHOD and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
            -- Dispose
            if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the dispose method."):format(tostring(info.Owner))) end
            info[DISPOSE_METHOD] = value
            return
        elseif key == STRUCT_INIT_METHOD and info.Type == TYPE_STRUCT then
            -- init
            if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the initializer."):format(tostring(info.Owner))) end
            info.Initializer = value
            return
        elseif _KeyMeta[key] and info.Type == TYPE_CLASS then
            -- Meta-method
            if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the meta-method."):format(tostring(info.Owner))) end
            isMeta = key
            rkey = _KeyMeta[key]
            storage = info.MetaTable
            oldValue = storage[rkey]
        else
            -- Method
            if info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS then
                if IsFinalFeature(info.Owner, key) then return error(("%s.%s is final, can't be overwrited."):format(tostring(info.Owner), key)) end
                if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) and (info.Cache[key] or info.Method and info.Method[key]) then return error(("%s.%s is sealed, can't be overwrited."):format(tostring(info.Owner), key)) end
            elseif info.Type == TYPE_STRUCT then
                if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) and info.Method and info.Method[key] then return error(("%s.%s is sealed, can't be overwrited."):format(tostring(info.Owner), key)) end
                if info.Members and info.Members[key] then return error(("'%s' already existed as struct member."):format(key)) end
            end
            info.Method = info.Method or {}
            storage = info.Method
        end

        if ATTRIBUTE_INSTALLED and not (isMeta == "__index" and type(value) == "table") then
            local ok, ret = pcall(ConsumePreparedAttributes, value, isConstructor and AttributeTargets.Constructor or AttributeTargets.Method, info.Owner, key)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
            storage[rkey] = ret or value
        else
            storage[rkey] = value
        end

        -- Update child's meta-method
        if isMeta then
            return UpdateMeta4Children(key, info.ChildClass, oldValue, storage[rkey])
        end
    end

    function SaveProperty(info, name, set)
        if type(set) ~= "table" then return error([[Usage: property "Name" { Property Definition }]]) end

        local prop = {}
        info.Property = info.Property or {}
        info.Property[name] = prop

        prop.Name = name
        prop.Predefined = set

        if ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, prop, AttributeTargets.Property, info.Owner, name)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
        end
    end

    function SaveEvent(info, name)
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) and (info.Cache[name] or info.Event and info.Event[name]) then return error(("%s.%s is sealed, can't be overwrited."):format(tostring(info.Owner), name)) end

        info.Event = info.Event or {}
        info.Event[name] = info.Event[name] or Event(name)

        if ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, info.Event[name], AttributeTargets.Event, info.Owner, name)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
        end
    end

    function SaveExtend(info, IF)
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't extend interface."):format(tostring(info.Owner))) end

        local IFInfo = _NSInfo[IF]

        if not IFInfo or IFInfo.Type ~= TYPE_INTERFACE then
            return error("Usage: extend (interface) : 'interface' - interface expected")
        elseif ValidateFlags(MD_FINAL_FEATURE, IFInfo.Modifier) then
            return error(("%s is marked as final, can't be extened."):format(tostring(IF)))
        end

        if info.Type == TYPE_CLASS then
            if IFInfo.RequireClass then
                if not IsChildClass(IFInfo.RequireClass, info.Owner) then
                    return error(("Usage: extend (%s) : %s should be sub-class of %s."):format(tostring(IF), tostring(info.Owner), tostring(IFInfo.RequireClass)))
                end
            elseif IFInfo.ExtendInterface then
                for _, sIF in ipairs(IFInfo.ExtendInterface) do
                    local req = _NSInfo[sIF].RequireClass

                    if req and not IsChildClass(req, info.Owner) then
                        return error(("Usage: extend (%s) : %s should be sub-class of %s."):format(tostring(IF), tostring(info.Owner), tostring(req)))
                    end
                end
            end
        elseif info.Type == TYPE_INTERFACE then
            if IsExtend(info.Owner, IF) then
                return error(("%s is extended from %s, can't be used here."):format(tostring(IF), tostring(info.Owner)))
            end
            if info.RequireClass then
                if IFInfo.RequireClass then
                    if not IsChildClass(IFInfo.RequireClass, info.RequireClass) then
                        return error(("%s require class %s, it's conflicted with current settings."):format(tostring(IF), tostring(IFInfo.RequireClass)))
                    end
                else
                    if IFInfo.ExtendInterface then
                        for _, sIF in ipairs(IFInfo.ExtendInterface) do
                            local req = _NSInfo[sIF].RequireClass

                            if req and not IsChildClass(req, info.RequireClass) then
                                return error(("%s require class %s, it's conflicted with current settings."):format(tostring(sIF), tostring(req)))
                            end
                        end
                    end
                end
            else
                if IFInfo.RequireClass then
                    if info.ExtendInterface then
                        for _, sIF in ipairs(info.ExtendInterface) do
                            local req = _NSInfo[sIF].RequireClass

                            if req and not IsChildClass(req, IFInfo.RequireClass) and not IsChildClass(IFInfo.RequireClass, req) then
                                return error(("%s require class %s, it's conflicted with current settings."):format(tostring(IF), tostring(IFInfo.RequireClass)))
                            end
                        end
                    end
                elseif info.ExtendInterface and IFInfo.ExtendInterface then
                    local cache = CACHE_TABLE()
                    local pass = true

                    for _, sIF in ipairs(info.ExtendInterface) do
                        local req = _NSInfo[sIF].RequireClass

                        if req then tinsert(cache, req) end
                    end

                    if #cache > 0 then
                        for _, sIF in ipairs(IFInfo.ExtendInterface) do
                            local req = _NSInfo[sIF].RequireClass

                            if req then
                                for _, required in ipairs(cache) do
                                    if not IsChildClass(req, required) and not IsChildClass(required, req) then
                                        pass = false
                                        break
                                    end
                                end
                            end

                            if not pass then break end
                        end

                        while tremove(cache) do end
                    end

                    CACHE_TABLE(cache)

                    if not pass then
                        return error(("%s require class %s, it's conflicted with current settings."):format(tostring(IF), tostring(IFInfo.RequireClass)))
                    end
                end
            end
        end

        info.ExtendInterface = info.ExtendInterface or {}

        -- Check if IF is already extend by extend tree
        for _, pIF in ipairs(info.ExtendInterface) do if IsExtend(IF, pIF) then return end end

        local owner = info.Owner
        for i = #(info.ExtendInterface), 1, -1 do
            local pIF = info.ExtendInterface[i]
            if IsExtend(pIF, IF) then
                local pExtend = _NSInfo[pIF].ExtendChild
                for j, v in ipairs(pExtend) do
                    if v == owner then
                        tremove(pExtend, j)
                        break
                    end
                end
                tremove(info.ExtendInterface, i)
            end
        end

        IFInfo.ExtendChild = IFInfo.ExtendChild or setmetatable({}, WEAK_VALUE)
        tinsert(IFInfo.ExtendChild, owner)

        tinsert(info.ExtendInterface, IF)
    end

    function SaveInherit(info, superCls)
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set super class."):format(tostring(info.Owner))) end

        local superInfo = _NSInfo[superCls]

        if not superInfo or superInfo.Type ~= TYPE_CLASS then return error("Usage: inherit (class) : 'class' - class expected") end
        if ValidateFlags(MD_FINAL_FEATURE, superInfo.Modifier) then return error(("%s is marked as final, can't be inherited."):format(tostring(superCls))) end
        if IsChildClass(info.Owner, superCls) then return error(("%s is inherited from %s, can't be used as super class."):format(tostring(superCls), tostring(info.Owner))) end
        if info.SuperClass == superCls then return end
        if info.SuperClass then return error(("%s is inherited from %s, can't inherit another class."):format(tostring(info.Owner), tostring(info.SuperClass))) end

        superInfo.ChildClass = superInfo.ChildClass or setmetatable({}, WEAK_VALUE)
        tinsert(superInfo.ChildClass, info.Owner)

        info.SuperClass = superCls

        -- Copy MetaTable
        if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

        for meta, rMeta in pairs(_KeyMeta) do
            if superInfo.MetaTable[rMeta] then UpdateMeta4Child(meta, info.Owner, nil, superInfo.MetaTable[rMeta]) end
        end

        -- Enable Object Method Attribute
        if superInfo.InheritEnableObjMethodAttr then
            SaveInheritEnableObjMethodAttr(info.Owner)
        end

        -- Clone Attributes
        return ATTRIBUTE_INSTALLED and InheritAttributes(superCls, info.Owner, AttributeTargets.Class)
    end

    local function CheckRequireConflict(info, req, child)
        -- Only check the conflict caused by child interfaces or classes
        if child and info.RequireClass and not IsChildClass(req, info.RequireClass) then return false, info.Owner end

        if info.ExtendChild then
            for _, subcls in ipairs(info.ExtendChild) do
                local sinfo = _NSInfo[subcls]
                if sinfo.Type == TYPE_CLASS then
                    if not IsChildClass(req, subcls) then return false, subcls end
                elseif sinfo.Type == TYPE_INTERFACE then
                    local ok, ret = CheckRequireConflict(sinfo, req, true)
                    if not ok then return false, ret end
                end
            end
        end

        return true
    end

    function SaveRequire(info, req)
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then return error(("%s is sealed, can't set the required class."):format(tostring(info.Owner))) end
        if not rawget(_NSInfo, req) or _NSInfo[req].Type ~= TYPE_CLASS then error("Usage : require 'class'") end

        local ok, ret = CheckRequireConflict(info, req)
        if not ok then return error(("The new required class is conflicted with %s that extened from the interface."):format(tostring(ret))) end

        info.RequireClass = req
    end

    function SaveStructMember(info, key, value)
        -- Check if a member setting
        if tonumber(key) and type(value) == "table" and getmetatable(value) == nil then
            for k, v in pairs(value) do
                if type(k) == "string" and k:lower() == "name" and type(v) == "string" and not tonumber(v) then
                    key = v
                    value[k] = nil
                    break
                end
            end
        end

        -- Check if is array element type
        if tonumber(key) then
            if not (IsNameSpace(value) and _NSInfo[value].Type) then
                return error("The array element's type is not valid.")
            end

            if info[0] then
                local pass = false
                if info[0] == value then
                    pass = true
                elseif Reflector.IsStruct(value) then
                    local base = __Base__:GetStructAttribute(value)
                    while base and base ~= info[0] do base = __Base__:GetStructAttribute(base) end
                    if base == info[0] then pass = true end
                elseif Reflector.IsClass(value) then
                    if Reflector.IsInterface(info[0]) and Reflector.IsExtendedInterface(value, info[0]) then pass = true end
                    if Reflector.IsClass(info[0]) and Reflector.IsSuperClass(value, info[0]) then pass = true end
                elseif Reflector.IsInterface(value) then
                    if Reflector.IsInterface(info[0]) and Reflector.IsExtendedInterface(value, info[0]) then pass = true end
                end

                if not pass then return error("The array's element type is already set.") end
            elseif info[1] then
                return error("The struct has member settings.")
            end

            info[0] = value
        else
            if info[0] then return error("The struct is an element arry type.") end

            for i, s in ipairs(info) do
                if s.Name == key then
                    return error("The struct already has a member named " .. key)
                end
            end

            if IsNameSpace(value) and _NSInfo[value].Type then value = { Type = value } end
            if type(value) ~= "table" then return error([[Usage: member "Name" { -- Field Definition }]]) end

            -- Prepare the table
            local memberInfo = { Name = key, Predefined = value }

            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ConsumePreparedAttributes, memberInfo, AttributeTargets.Member, info.Owner, key)
                if not ok then return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
            end

            tinsert(info, memberInfo)
        end
    end

    function SaveFeature(info, key, value)
        -- Forbidden
        if key == DISPOSE_METHOD and type(value) ~= "function" and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
            return error(("'%s' must be a function as the dispose method."):format(key))
        elseif key == info.Name and type(value) ~= "function" then
            return error(("'%s' must be a function as the %s."):format(key, info.Type == TYPE_CLASS and "Constructor" or info.Type == TYPE_INTERFACE and "Initializer" or "Validator"))
        elseif key == STRUCT_INIT_METHOD and info.Type == TYPE_STRUCT and type(value) ~= "function" then
            return error(("'%s' must be a function as the initializer."):format(key))
        elseif _KeyMeta[key] and type(value) ~= "function" and info.Type == TYPE_CLASS then
            if not (key == "__index" and type(value) == "table") then
                return error(("'%s' must be a function as meta-method."):format(key))
            end
        end

        -- Save feature
        if tonumber(key) then
            if IsNameSpace(value) then
                local vType = _NSInfo[value].Type

                if info.Type == TYPE_STRUCT then
                    -- Array element
                    return SaveStructMember(info, key, value)
                elseif vType == TYPE_CLASS then
                    if info.Type == TYPE_CLASS then
                        -- inherit
                        return SaveInherit(info, value)
                    elseif info.Type == TYPE_INTERFACE then
                        -- require
                        return SaveRequire(info, value)
                    end
                elseif vType == TYPE_INTERFACE then
                    if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
                        -- extend
                        return SaveExtend(info, value)
                    end
                end
            elseif type(value) == "string" and not tonumber(value) and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
                -- event
                return SaveEvent(info, value)
            elseif type(value) == "function" then
                return SaveMethod(info, info.Name, value)
            elseif info.Type == TYPE_STRUCT then
                if type(value) == "table" then
                    SaveStructMember(info, key, value)
                else
                    -- Default value for struct
                    info.Default = value
                end
                return
            end
        elseif type(key) == "string" then
            local vType = type(value)

            if IsNameSpace(value) then
                if info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
                    return SaveProperty(info, key, { Type = value })
                elseif info.Type == TYPE_STRUCT then
                    return SaveStructMember(info, key, value)
                end
            elseif vType == "table" then
                if info.Type == TYPE_CLASS and key == "__index" then
                    return SaveMethod(info, key, value)
                elseif info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE then
                    return SaveProperty(info, key, value)
                elseif info.Type == TYPE_STRUCT then
                    return SaveStructMember(info, key, value)
                end
            elseif vType == "function" then
                return SaveMethod(info, key, value)
            elseif value == true and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) then
                return SaveEvent(info, key)
            end
        end

        return error(("The definition '%s' for %s is not supported."):format(tostring(key), tostring(info.Owner)))
    end

    function ParseTableDefinition(info, definition)
        -- Number keys means the core of the feature
        for k, v in ipairs(definition) do SaveFeature(info, k, v) end

        -- Only string key can be accepted(number is handled)
        for k, v in pairs(definition) do if type(k) == "string" then SaveFeature(info, k, v) end end
    end

    function import_Def(env, name)
        if type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: import "namespaceA.namespaceB"]]) end

        local ns

        if type(name) == "string" then
            ns = GetNameSpace(PROTYPE_NAMESPACE, name)
        elseif IsNameSpace(name) then
            ns = name
        end

        if not ns then return error(("No namespace is found with name : %s"):format(name)) end

        env[IMPORT_ENV_FIELD] = env[IMPORT_ENV_FIELD] or {}

        for _, v in ipairs(env[IMPORT_ENV_FIELD]) do if v == ns then return end end

        tinsert(env[IMPORT_ENV_FIELD], ns)
    end

    local fetchPropertyCache = setmetatable({}, WEAK_KEY)

    local function fetchPropertyDefine(set)
        local cache = fetchPropertyCache[running() or 0]
        if not cache then return end

        local info, name = cache.Info, cache.Name

        cache.Info = nil
        cache.Name = nil

        local ok, msg = pcall(SaveProperty, info, name, set)
        if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
    end

    function property_Def(env, name)
        if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then
            return error([[Usage: property "Name" { Property Definition }]])
        end

        local cur = running() or 0

        fetchPropertyCache[cur] = fetchPropertyCache[cur] or {}

        fetchPropertyCache[cur].Info = _NSInfo[env[OWNER_FIELD]]
        fetchPropertyCache[cur].Name = name:match("[_%w]+")

        return fetchPropertyDefine
    end

    local fetchMemberCache = setmetatable({}, WEAK_KEY)

    local function fetchMemberDefine(set)
        local cache = fetchMemberCache[running() or 0]
        if not cache then return end

        local info, name = cache.Info, cache.Name

        cache.Info = nil
        cache.Name = nil

        local ok, msg = pcall(SaveStructMember, info, name, set)
        if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
    end

    function member_Def(env, name)
        if type(name) ~= "string" or strtrim(name:match("[_%w]+")) == "" then
            return error([[Usage: member "Name" { -- Field Definition }]])
        end

        local cur = running() or 0

        fetchMemberCache[cur] = fetchMemberCache[cur] or {}

        fetchMemberCache[cur].Info = _NSInfo[env[OWNER_FIELD]]
        fetchMemberCache[cur].Name = name:match("[_%w]+")

        return fetchMemberDefine
    end

    function event_Def(env, name)
        if type(name) ~= "string" or not name:match("^[_%w]+$") then return error([[Usage: event "eventName"]]) end

        local info = _NSInfo[env[OWNER_FIELD]]

        if not info then return error("can't use event here.") end

        return SaveEvent(info, name)
    end

    function extend_Def(env, name)
        if name and type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: extend "namespace.interfacename"]]) end

        local info = _NSInfo[env[OWNER_FIELD]]
        local IF

        if type(name) == "string" then
            IF = GetNameSpace(info.NameSpace, name) or env[name]

            if not IF then
                for subname in name:gmatch("[_%w]+") do
                    IF = IF and IF[subname] or env[subname]

                    if not IsNameSpace(IF) then
                        return error(("No interface is found with the name : %s"):format(name))
                    end
                end
            end
        else
            IF = name
        end

        return SaveExtend(info, IF)
    end

    function extend_IF(env, name)
        extend_Def(env, name)
        return _KeyWord4IFEnv:GetKeyword(env, "extend")
    end

    function extend_Cls(env, name)
        extend_Def(env, name)
        return _KeyWord4ClsEnv:GetKeyword(env, "extend")
    end

    function inherit_Def(env, name)
        if name and type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: inherit "namespace.classname"]]) end

        local info = _NSInfo[env[OWNER_FIELD]]

        local superCls

        if type(name) == "string" then
            superCls = GetNameSpace(info.NameSpace, name) or env[name]

            if not superCls then
                for subname in name:gmatch("[_%w]+") do
                    if not superCls then
                        superCls = env[subname]
                    else
                        superCls = superCls[subname]
                    end

                    if not IsNameSpace(superCls) then return error(("No class is found with the name : %s"):format(name)) end
                end
            end
        else
            superCls = name
        end

        return SaveInherit(info, superCls)
    end

    function require_IF(env, name)
        if name and type(name) ~= "string" and not IsNameSpace(name) then return error([[Usage: require "namespace.classname"]]) end

        local info = _NSInfo[env[OWNER_FIELD]]
        local cls

        if type(name) == "string" then
            cls = GetNameSpace(info.NameSpace, name) or env[name]

            if not cls then
                for subname in name:gmatch("[_%w]+") do
                    cls = cls and cls[subname] or env[subname]

                    if not IsNameSpace(cls) then return error(("No class is found with the name : %s"):format(name)) end
                end
            end
        else
            cls = name
        end

        return SaveRequire(info, cls)
    end
end

------------------------------------------------------
--------------------- Interface ----------------------
------------------------------------------------------
do
    _KeyWord4IFEnv = _KeywordAccessor()

    -- metatable for interface's env
    _MetaIFEnv = { __metatable = true }
    _MetaIFDefEnv = {}
    do
        local function __index(self, info, key)
            local value

            -- Check namespace
            if info.NameSpace then
                if key == _NSInfo[info.NameSpace].Name then
                    return info.NameSpace
                else
                    value = info.NameSpace[key]
                    if value ~= nil then return value end
                end
            end

            -- Check imports
            if rawget(self, IMPORT_ENV_FIELD) then
                for _, ns in ipairs(self[IMPORT_ENV_FIELD]) do
                    if key == _NSInfo[ns].Name then
                        return ns
                    else
                        value = ns[key]
                        if value ~= nil then return value end
                    end
                end
            end

            -- Check base namespace
            value = GetNameSpace(PROTYPE_NAMESPACE, key)
            if value then return value end

            -- Check method, so definition environment can use existed method
            -- created by another definition environment for the same interface
            value = info.Method and info.Method[key]
            if value then return value end

            -- Check event
            value = info.Event and info.Event[key]
            if value then return value.Userdata end

            -- Check Base
            return self[BASE_ENV_FIELD][key]
        end

        _MetaIFEnv.__index = function(self, key)
            local info = _NSInfo[self[OWNER_FIELD]]
            local value

            -- Check owner
            if key == info.Name then return info.Owner end

            -- Check keywords
            value = _KeyWord4IFEnv:GetKeyword(self, key)
            if value then return value end

            -- Check Static Property
            value = info.Property and info.Property[key]
            if value and value.IsStatic then return info.Owner[key] end

            -- Check others
            value = __index(self, info, key)
            if value ~= nil then rawset(self, key, value) return value end
        end

        -- Don't cache item in definition to reduce some one time access feature
        _MetaIFDefEnv.__index = function(self, key)
            local info = _NSInfo[self[OWNER_FIELD]]
            local value

            -- Check owner
            if key == info.Name then return info.Owner end

            -- Check keywords
            value = _KeyWord4IFEnv:GetKeyword(self, key)
            if value then return value end

            -- Check Static Property
            value = info.Property and info.Property[key]
            if value and value.IsStatic then return info.Owner[key] end

            -- Check others
            return __index(self, info, key)
        end

        _MetaIFDefEnv.__newindex = function(self, key, value)
            local info = _NSInfo[self[OWNER_FIELD]]

            if _KeyWord4IFEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

            if key == info.Name or key == DISPOSE_METHOD or (type(key) == "string" and type(value) == "function") then
                local ok, msg = pcall(SaveFeature, info, key, value)
                if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                return
            end

            -- Check Static Property
            if info.Property and info.Property[key] and info.Property[key].IsStatic then
                info.Owner[key] = value
                return
            end

            rawset(self, key, value)
        end

        _MetaIFDefEnv.__call = function(self, definition)
            ParseDefinition(self, definition)

            local owner = self[OWNER_FIELD]

            setfenv(2, self[BASE_ENV_FIELD])
            _KeyWord4IFEnv:ClearKeyword()
            pcall(setmetatable, self, _MetaIFEnv)
            RefreshCache(owner)

            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, owner, AttributeTargets.Interface)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end
            end

            return owner
        end
    end

    ------------------------------------
    --- Create interface in currect environment's namespace or default namespace
    ------------------------------------
    function interface(...)
        local env, name, definition, stack = checkTypeParams(...)

        local fenv = env or getfenv(stack) or _G

        local ok, IF = pcall(GetDefineNS, fenv, name, TYPE_INTERFACE)
        if not ok then error(IF:match("%d+:%s*(.-)$") or IF, stack) end

        local info = _NSInfo[IF]

        if not info then
            error([[Usage: interface "name"]], stack)
        elseif info.Type and info.Type ~= TYPE_INTERFACE then
            error(("%s is existed as %s, not interface."):format(tostring(name), tostring(info.Type)), stack)
        end

        -- Check if the class is final
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The interface is sealed, can't be re-defined.", stack) end

        if not info.Type then
            info.Type = TYPE_INTERFACE
            info.Cache = info.Cache or {}
        end

        -- No super target for interface
        if ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, info.Owner, AttributeTargets.Interface)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
        end

        if type(definition) == "table" then
            local ok, msg = pcall(ParseTableDefinition, info, definition)
            if not ok then error(msg:match("%d+:%s*(.-)$") or msg, stack) end

            RefreshCache(IF)
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, IF, AttributeTargets.Interface)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
            end

            return IF
        else
            -- Generate the interface environment
            local interfaceEnv = setmetatable({
                [OWNER_FIELD] = IF,
                [BASE_ENV_FIELD] = fenv,
            }, _MetaIFDefEnv)

            -- Set namespace
            SetNameSpace4Env(interfaceEnv, IF)

            if definition then
                setfenv(definition, interfaceEnv)
                definition(interfaceEnv)

                _KeyWord4IFEnv:ClearKeyword()
                pcall(setmetatable, interfaceEnv, _MetaIFEnv)
                RefreshCache(IF)
                if ATTRIBUTE_INSTALLED then
                    local ok, ret = pcall(ApplyRestAttribute, IF, AttributeTargets.Interface)
                    if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
                end

                return IF
            else
                -- save interface to the environment
                if type(name) == "string" then rawset(fenv, name, IF) end

                -- Set the environment to interface's environment
                setfenv(stack, interfaceEnv)

                return interfaceEnv
            end
        end
    end

    ------------------------------------
    --- End the interface's definition and restore the environment
    ------------------------------------
    function endinterface(env, name, stack)
        stack = stack or 2
        if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

        local info = _NSInfo[env[OWNER_FIELD]]

        if info.Name == name or info.Owner == name then
            _KeyWord4IFEnv:ClearKeyword()
            setmetatable(env, _MetaIFEnv)
            setfenv(stack, env[BASE_ENV_FIELD])
            RefreshCache(info.Owner)
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, info.Owner, AttributeTargets.Interface)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
            end
            return env[BASE_ENV_FIELD]
        else
            error(("%s is not closed."):format(info.Name), stack)
        end
    end

    function ParseDefinition(self, definition)
        local info = _NSInfo[self[OWNER_FIELD]]
        if type(definition) == "table" then
            local ok, msg = pcall(ParseTableDefinition, info, definition)
            if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 3) end
        else
            if type(definition) == "string" then
                local errorMsg
                definition, errorMsg = loadstring("return function(_ENV) " .. definition .. " end")
                if definition then
                    definition = definition()
                else
                    error(errorMsg, 3)
                end
            end

            if type(definition) == "function" then
                setfenv(definition, self)
                return definition(self)
            end
        end
    end

    function BuildAnonymousClass(info)
        local cls = class {}
        local cInfo = _NSInfo[cls]
        SaveExtend(_NSInfo[cls], info.Owner)
        RefreshCache(cls)
        cInfo.OriginIF = info.Owner
        info.AnonymousClass = cls
        return cls
    end

    function Interface2Obj(info, init)
        if  type(init) == "string" then
            local ok, ret = pcall(Lambda, init)
            if not ok then error(ret:match("%d+:%s*(.-)$") or ret, 3) end
            init = ret
        end

        if type(init) == "function" then
            if not info.IsOneReqMethod then error(("%s is not a one required method interface."):format(tostring(info.Owner)), 3) end
            init = { [info.IsOneReqMethod] = init }
        end

        return (info.AnonymousClass or BuildAnonymousClass(info))(init)
    end

    _KeyWord4IFEnv.extend = extend_IF
    _KeyWord4IFEnv.import = import_Def
    _KeyWord4IFEnv.event = event_Def
    _KeyWord4IFEnv.property = property_Def
    _KeyWord4IFEnv.endinterface = endinterface
    _KeyWord4IFEnv.require = require_IF

    _KeyWord4IFEnv.doc = document
end

------------------------------------------------------
----------------------- Class ------------------------
------------------------------------------------------
do
    _KeyWord4ClsEnv = _KeywordAccessor()

    _KeyMeta = {
        __add = "__add",            -- a + b
        __sub = "__sub",            -- a - b
        __mul = "__mul",            -- a * b
        __div = "__div",            -- a / b
        __mod = "__mod",            -- a % b
        __pow = "__pow",            -- a ^ b
        __unm = "__unm",            -- - a
        __concat = "__concat",      -- a..b
        __len = "__len",            -- #a
        __eq = "__eq",              -- a == b
        __lt = "__lt",              -- a < b
        __le = "__le",              -- a <= b
        __index = "___index",       -- return a[b]
        __newindex = "___newindex", -- a[b] = v
        __call = "__call",          -- a()
        __gc = "__gc",              -- dispose a
        __tostring = "__tostring",  -- tostring(a)
        __idiv = "__idiv",          -- // floor division
        __band = "__band",          -- & bitwise and
        __bor = "__bor",            -- | bitwise or
        __bxor = "__bxor",          -- ~ bitwise exclusive or
        __bnot = "__bnot",          -- ~ bitwise unary not
        __shl = "__shl",            -- << bitwise left shift
        __shr = "__shr",            -- >> bitwise right shift
        -- Ploop only meta-methods
        __exist = "__exist",        -- return object if existed
        __new = "__new",            -- create the object table by itself(so not provided by the system)
    }

    --------------------------------------------------
    -- Init & Dispose System
    --------------------------------------------------
    do
        function InitObjectWithInterface(info, obj)
            if not info.Cache4Interface then return end
            for _, IF in ipairs(info.Cache4Interface) do
                info = _NSInfo[IF]
                if info.Initializer then info.Initializer(obj) end
            end
        end

        ------------------------------------
        --- Dispose this object
        ------------------------------------
        function DisposeObject(self)
            local objCls = getmetatable(self)
            local info, disfunc

            info = objCls and _NSInfo[objCls]

            if not info then return end

            local cache = info.Cache4Interface
            if cache then
                for i = #(cache), 1, -1 do
                    disfunc = _NSInfo[cache[i]][DISPOSE_METHOD]

                    if disfunc then pcall(disfunc, self) end
                end
            end

            -- Call Class Dispose
            while objCls do
                disfunc = _NSInfo[objCls][DISPOSE_METHOD]

                if disfunc then pcall(disfunc, self) end

                objCls = _NSInfo[objCls].SuperClass
            end

            -- No dispose to a unique object
            if info.UniqueObject then return end

            -- Clear the table
            wipe(self)
            rawset(self, "Disposed", true)
        end
    end

    -- metatable for class's env
    _MetaClsEnv = { __metatable = true }
    _MetaClsDefEnv = {}
    do
        local function __index(self, info, key)
            if key == "Super" then
                info = _NSInfo[info.SuperClass]
                if info then
                    return info.ClassAlias or BuildClassAlias(info)
                else
                    error("The class has no super class.", 3)
                end
            end

            if key == "This" then return info.ClassAlias or BuildClassAlias(info) end

            local value

            -- Check namespace
            if info.NameSpace then
                if key == _NSInfo[info.NameSpace].Name then
                    return info.NameSpace
                else
                    value = info.NameSpace[key]
                    if value ~= nil then return value end
                end
            end

            -- Check imports
            if rawget(self, IMPORT_ENV_FIELD) then
                for _, ns in ipairs(self[IMPORT_ENV_FIELD]) do
                    if key == _NSInfo[ns].Name then
                        return ns
                    else
                        value = ns[key]
                        if value ~= nil then return value end
                    end
                end
            end

            -- Check base namespace
            value = GetNameSpace(PROTYPE_NAMESPACE, key)
            if value then return value end

            -- Check method, so definition environment can use existed method
            -- created by another definition environment for the same class
            value = info.Method and info.Method[key]
            if value then return value end

            -- Check event
            value = info.Event and info.Event[key]
            if value then return value.Userdata end

            -- Check meta-methods
            if _KeyMeta[key] then
                value = info.MetaTable[_KeyMeta[key]]
                if type(value) == "table" and getmetatable(value) == nil then
                    if value ~= rawget(self, INDEX_TABLE_FIELD) then
                        value = CloneObj(value, true)
                    end
                end
                return value
            end

            -- Check Base
            return self[BASE_ENV_FIELD][key]
        end

        _MetaClsEnv.__index = function(self, key)
            local info = _NSInfo[self[OWNER_FIELD]]
            local value

            -- Check owner
            if key == info.Name then return info.Owner end

            -- Check keywords
            value = _KeyWord4ClsEnv:GetKeyword(self, key)
            if value then return value end

            -- Check Static Property
            value = info.Property and info.Property[key]
            if value and value.IsStatic then return info.Owner[key] end

            -- Check others
            value = __index(self, info, key)
            if value ~= nil then rawset(self, key, value) return value end
        end

        _MetaClsDefEnv.__index = function(self, key)
            local info = _NSInfo[self[OWNER_FIELD]]
            local value

            -- Check owner
            if key == info.Name then return info.Owner end

            -- Check keywords
            value = _KeyWord4ClsEnv:GetKeyword(self, key)
            if value then return value end

            -- Check Static Property
            value = info.Property and info.Property[key]
            if value and value.IsStatic then return info.Owner[key] end

            -- Check others
            return __index(self, info, key)
        end

        _MetaClsDefEnv.__newindex = function(self, key, value)
            local info = _NSInfo[self[OWNER_FIELD]]

            if _KeyWord4ClsEnv:GetKeyword(self, key) then error(("'%s' is a keyword."):format(key), 2) end

            if key == info.Name or key == DISPOSE_METHOD or _KeyMeta[key] or (type(key) == "string" and type(value) == "function") then
                if key == "__index" and type(value) == "table" then
                    rawset(self, INDEX_TABLE_FIELD, value)
                end

                local ok, msg = pcall(SaveFeature, info, key, value)
                if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                return
            end

            -- Check Static Property
            if info.Property and info.Property[key] and info.Property[key].IsStatic then
                info.Owner[key] = value
                return
            end

            rawset(self, key, value)
        end

        _MetaClsDefEnv.__call = function(self, definition)
            ParseDefinition(self, definition)

            local owner = self[OWNER_FIELD]

            setfenv(2, self[BASE_ENV_FIELD])
            _KeyWord4ClsEnv:ClearKeyword()
            pcall(setmetatable, self, _MetaClsEnv)
            RefreshCache(owner)
            local info = _NSInfo[owner]
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, owner, AttributeTargets.Class)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end
            end

            -- Validate the interface
            ValidateClass(info, 3)

            return owner
        end
    end

    function Class_Index(self, key)
        local info = _NSInfo[getmetatable(self)]
        local Cache = info.Cache

        local oper = Cache[key]
        if oper then
            if type(oper) == "function" then
                -- Method
                if info.AutoCache then
                    rawset(self, key, oper)
                    return oper
                else
                    return oper
                end
            elseif getmetatable(oper) then
                -- Event
                local handler = rawget(oper, self)
                if not handler then handler = EventHandler(oper, self) end
                return handler
            else
                -- Property
                local value
                local default = oper.Default

                -- Get Getter
                local operTar = oper.Get or Cache[oper.GetMethod]

                -- Get Value
                if operTar then
                    if default == nil and not oper.GetClone then return operTar(self) end
                    value = operTar(self)
                else
                    operTar = oper.Field

                    if operTar then
                        if oper.SetWeak then
                            value = rawget(self, "__PLoop_WeakFields")
                            if type(value) == "table" then
                                value = value[operTar]
                            else
                                value = nil
                            end
                        else
                            value = rawget(self, operTar)
                        end
                    elseif default == nil then
                        error(("%s can't be read."):format(key),2)
                    end
                end

                if value == nil then
                    operTar = oper.DefaultFunc
                    if operTar then
                        value = operTar(self)
                        if value ~= nil then
                            if oper.Set == false then
                                operTar = oper.Field

                                -- Check container
                                local container = self

                                if oper.SetWeak then
                                    container = rawget(self, "__PLoop_WeakFields")
                                    if type(container) ~= "table" then
                                        container = setmetatable({}, WEAK_VALUE)
                                        rawset(self, "__PLoop_WeakFields", container)
                                    end
                                end

                                -- Set the value
                                rawset(container, operTar, value)
                            else
                                self[key] = value
                            end
                        end
                    else
                        value = default
                    end
                end
                if oper.GetClone then value = CloneObj(value, oper.GetDeepClone) end

                return value
            end
        end

        -- Custom index metametods
        oper = info.MetaTable.___index
        if oper then
            if type(oper) == "function" then
                return oper(self, key)
            elseif type(oper) == "table" then
                return oper[key]
            end
        end
    end

    function Class_NewIndex(self, key, value)
        local info = _NSInfo[getmetatable(self)]
        local Cache = info.Cache
        local oper = Cache[key]

        -- Object Method
        if info.EnableObjMethodAttr and type(value) == "function" and HasPreparedAttribute() then
            local ok, ret = pcall(ConsumePreparedAttributes, value, AttributeTargets.ObjectMethod, self, key)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end
            value = ret or value
        end

        if type(oper) == "table" then
            if getmetatable(oper) then
                -- Event
                local handler = rawget(oper, self)

                if not handler then
                    if value == nil then return end -- No need to create the handler
                    handler = EventHandler(oper, self)
                end

                if value == nil or type(value) == "function" then
                    handler.Handler = value
                    return
                elseif type(value) == "table" then
                    return handler:Copy(value)
                else
                    error("Can't set this value to the event handler.", 2)
                end
            else
                -- Property
                if oper.Set == false then error(("%s can't be set."):format(key), 2) end
                if oper.Type then value = Validate4Type(oper.Type, value, key, key, 3) end
                if oper.SetClone then value = CloneObj(value, oper.SetDeepClone) end

                -- Get Setter
                local operTar = oper.Set or Cache[oper.SetMethod]

                -- Set Value
                if operTar then
                    return operTar(self, value)
                else
                    operTar = oper.Field

                    if operTar then
                        -- Check container
                        local container = self
                        local default = oper.Default

                        if oper.SetWeak then
                            container = rawget(self, "__PLoop_WeakFields")
                            if type(container) ~= "table" then
                                container = setmetatable({}, WEAK_VALUE)
                                rawset(self, "__PLoop_WeakFields", container)
                            end
                        end

                        -- Check new value
                        if value == nil then value = default end

                        -- Check old value
                        local old = rawget(container, operTar)
                        if old == nil then old = default end
                        if old == value then return end

                        -- Set the value
                        rawset(container, operTar, value)

                        -- Dispose old
                        if oper.SetRetain and old and old ~= default then
                            DisposeObject(old)
                            old = nil
                        end

                        -- Call handler
                        operTar = oper.Handler
                        if operTar then operTar(self, value, old, key) end

                        -- Fire event
                        operTar = oper.Event
                        if operTar then return operTar(self, value, old, key) end

                        return
                    else
                        error(("%s can't be set."):format(key), 2)
                    end
                end
            end
        end

        -- Custom newindex metametods
        oper = info.MetaTable.___newindex
        if oper then return oper(self, key, value) end

        if info.NoAutoSet then error("The object is readonly.", 2) end

        rawset(self, key, value)
    end

    _MetaIndexBuilder = {}

    FLAG_HAS_AUTOCACHE    = 2^3
    FLAG_HAS_INDEXFUNC    = 2^4
    FLAG_HAS_INDEXTBL     = 2^5
    FLAG_HAS_NEWINDEX     = 2^6
    FLAG_HAS_ENOBJATTR    = 2^7
    FLAG_HAS_NOAUTOSET    = 2^8

    function GenerateMetaIndex(info)
        local metaToken = info.FeatureToken or 0

        if info.AutoCache and ValidateFlags(FLAG_HAS_METHOD, metaToken) then
            metaToken = TurnOnFlags(FLAG_HAS_AUTOCACHE, metaToken)
        end

        if info.MetaTable.___index then
            if type(info.MetaTable.___index) == "function" then
                metaToken = TurnOnFlags(FLAG_HAS_INDEXFUNC, metaToken)
            else
                metaToken = TurnOnFlags(FLAG_HAS_INDEXTBL, metaToken)
            end
        end

        -- Check if no need to generate the __index meta-method
        if metaToken == 0 then return nil end
        if metaToken == FLAG_HAS_METHOD then return info.Cache end
        if metaToken == FLAG_HAS_INDEXFUNC or metaToken == FLAG_HAS_INDEXTBL then return info.MetaTable.___index end

        local upValues  = CACHE_TABLE()

        if ValidateFlags(FLAG_HAS_METHOD, metaToken) or ValidateFlags(FLAG_HAS_PROPERTY, metaToken) or ValidateFlags(FLAG_HAS_EVENT, metaToken) then
            tinsert(upValues, info.Cache)
        end

        if ValidateFlags(FLAG_HAS_INDEXFUNC, metaToken) or ValidateFlags(FLAG_HAS_INDEXTBL, metaToken) then
            tinsert(upValues, info.MetaTable.___index)
        end

        -- Building
        if not _MetaIndexBuilder[metaToken] then
            local gHeader = CACHE_TABLE()
            local gbody = CACHE_TABLE()

            tinsert(gbody, "") -- Remain for closure values
            tinsert(gbody, [[return function(self, key)]])

            if ValidateFlags(FLAG_HAS_METHOD, metaToken) or ValidateFlags(FLAG_HAS_PROPERTY, metaToken) or ValidateFlags(FLAG_HAS_EVENT, metaToken) then
                tinsert(gHeader, "Cache")

                tinsert(gbody, [[local oper = Cache[key] ]])
                tinsert(gbody, [[if oper then]])

                -- Method
                if ValidateFlags(FLAG_HAS_METHOD, metaToken) then
                    if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) or ValidateFlags(FLAG_HAS_EVENT, metaToken) then
                        tinsert(gbody, [[if type(oper) == "function" then]])
                    end
                    if ValidateFlags(FLAG_HAS_AUTOCACHE, metaToken) then
                        tinsert(gbody, [[    rawset(self, key, oper)]])
                    end
                        tinsert(gbody, [[    return oper]])
                    if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) or ValidateFlags(FLAG_HAS_EVENT, metaToken) then
                        tinsert(gbody, [[end]])
                    end
                end

                -- Event
                if ValidateFlags(FLAG_HAS_EVENT, metaToken) then
                    if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) then
                        tinsert(gbody, [[if getmetatable(oper) then]])
                    end
                        tinsert(gbody, [[    local handler = rawget(oper, self)]])
                        tinsert(gbody, [[    if not handler then handler = EventHandler(oper, self) end]])
                        tinsert(gbody, [[    return handler]])

                    if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) then
                        tinsert(gbody, [[end]])
                    end
                end

                -- Property
                if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) then
                    tinsert(gbody, [[return oper.RawGet(self)]])
                end

                tinsert(gbody, [[end]])
            end

            if ValidateFlags(FLAG_HAS_INDEXFUNC, metaToken) then
                tinsert(gHeader, "metaIndex")
                tinsert(gbody, [[return metaIndex(self, key)]])
            elseif ValidateFlags(FLAG_HAS_INDEXTBL, metaToken) then
                tinsert(gHeader, "metaIndex")
                tinsert(gbody, [[return metaIndex[key] ]])
            end

            tinsert(gbody, [[end]])

            if #gHeader > 0 then
                gbody[1] = "local " .. tblconcat(gHeader, ",") .. "=..."
            end
            _MetaIndexBuilder[metaToken] = loadInEnv(tblconcat(gbody, "\n"), "Class_Index_"..tostring(metaToken))
            CACHE_TABLE(gHeader)
            CACHE_TABLE(gbody)
        end

        local rs = _MetaIndexBuilder[metaToken](unpack(upValues))
        CACHE_TABLE(upValues)
        return rs
    end

    _MetaNewIndexBuilder = {}

    function GenerateMetaNewIndex(info)
        local metaToken = TurnOffFlags(FLAG_HAS_METHOD, info.FeatureToken or 0)

        if info.EnableObjMethodAttr then
            metaToken = TurnOnFlags(FLAG_HAS_ENOBJATTR, metaToken)
        end

        if info.MetaTable.___newindex then
            metaToken = TurnOnFlags(FLAG_HAS_NEWINDEX, metaToken)
        end

        if info.NoAutoSet then
            metaToken = TurnOnFlags(FLAG_HAS_NOAUTOSET, metaToken)
        end

        if metaToken == 0 then return nil end
        if metaToken == FLAG_HAS_NEWINDEX then return info.MetaTable.___newindex end

        local upValues = CACHE_TABLE()

        if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) or ValidateFlags(FLAG_HAS_EVENT, metaToken) then
            tinsert(upValues, info.Cache)
        end

        if ValidateFlags(FLAG_HAS_NEWINDEX, metaToken) then
            tinsert(upValues, info.MetaTable.___newindex)
        end

        -- Building
        if not _MetaNewIndexBuilder[metaToken] then
            local gHeader = CACHE_TABLE()
            local gbody   = CACHE_TABLE()

            tinsert(gbody, "") -- Remain for closure values
            tinsert(gbody, [[return function(self, key, value)]])

            if ValidateFlags(FLAG_HAS_ENOBJATTR, metaToken) then
                -- Object method
                tinsert(gbody, [[if type(value) == "function" and HasPreparedAttribute() then]])
                tinsert(gbody, [[    local ok, ret = pcall(ConsumePreparedAttributes, value, AttributeTargets.ObjectMethod, self, key)]])
                tinsert(gbody, [[    if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end]])
                tinsert(gbody, [[    value = ret or value]])
                tinsert(gbody, [[end]])
            end

            if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) or ValidateFlags(FLAG_HAS_EVENT, metaToken) then
                tinsert(gHeader, "Cache")
                tinsert(gbody, [[local oper = Cache[key] ]])

                tinsert(gbody, [[if type(oper) == "table" then]])

                -- Event
                if ValidateFlags(FLAG_HAS_EVENT, metaToken) then
                    if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) then
                        tinsert(gbody, [[if getmetatable(oper) then]])
                    end
                            tinsert(gbody, [[local handler = rawget(oper, self)]])
                            tinsert(gbody, [[if not handler then]])
                            tinsert(gbody, [[    if value == nil then return end]])
                            tinsert(gbody, [[    handler = EventHandler(oper, self)]])
                            tinsert(gbody, [[end]])
                            tinsert(gbody, [[if value == nil or type(value) == "function" then]])
                            tinsert(gbody, [[    handler.Handler = value]])
                            tinsert(gbody, [[    return]])
                            tinsert(gbody, [[elseif type(value) == "table" then]])
                            tinsert(gbody, [[    return handler:Copy(value)]])
                            tinsert(gbody, [[else]])
                            tinsert(gbody, [[    error("Can't set this value to the event handler.", 2)]])
                            tinsert(gbody, [[end]])

                    if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) then
                        tinsert(gbody, [[end]])
                    end
                end

                -- Property
                if ValidateFlags(FLAG_HAS_PROPERTY, metaToken) then
                    tinsert(gbody, [[return oper.RawSet(self, value)]])
                end

                tinsert(gbody, [[end]])
            end

            if ValidateFlags(FLAG_HAS_NEWINDEX, metaToken) then
                tinsert(gHeader, "metaNewIndex")
                tinsert(gbody, [[return metaNewIndex(self, key, value)]])
            elseif not ValidateFlags(FLAG_HAS_NOAUTOSET, metaToken) then
                tinsert(gbody, [[rawset(self, key, value)]])
            else
                tinsert(gbody, [[error("The object is readonly.", 2)]])
            end

            tinsert(gbody, [[end]])

            if #gHeader > 0 then
                gbody[1] = "local " .. tblconcat(gHeader, ",") .. "=..."
            end
            _MetaNewIndexBuilder[metaToken] = loadInEnv(tblconcat(gbody, "\n"), "Class_NewIndex_"..tostring(metaToken))
            CACHE_TABLE(gHeader)
            CACHE_TABLE(gbody)
        end

        local rs = _MetaNewIndexBuilder[metaToken](unpack(upValues))
        CACHE_TABLE(upValues)
        return rs
    end

    function GenerateMetaTable(info)
        local meta = info.MetaTable or {}
        info.MetaTable = meta

        meta.__metatable = info.Owner
        meta.__index = SAVE_MEMORY and Class_Index or GenerateMetaIndex(info)
        meta.__newindex = SAVE_MEMORY and Class_NewIndex or GenerateMetaNewIndex(info)
    end

    function ValidateClass(info, stack)
        if not info.ExtendInterface then return end
        for _, IF in ipairs(info.ExtendInterface) do
            local sinfo = _NSInfo[IF]

            if sinfo.FeatureModifier then
                if sinfo.Method then
                    for name, func in pairs(sinfo.Method) do
                        if ValidateFlags(MD_REQUIRE_FEATURE, sinfo.FeatureModifier[name]) and func == info.Cache[name] then
                            error(("The %s lack method declaration for [%s] %s."):format(tostring(info.Owner), tostring(IF), name), stack)
                        end
                    end
                end

                if sinfo.Property then
                    for name, prop in pairs(sinfo.Property) do
                        if ValidateFlags(MD_REQUIRE_FEATURE, sinfo.FeatureModifier[name]) then
                            local iprop = info.Cache[name]

                            if not (iprop and type(iprop) == "table" and getmetatable(iprop) == nil) then
                                error(("The %s lack property declaration for [%s] %s."):format(tostring(info.Owner), tostring(IF), name), stack)
                            elseif (prop.Type and iprop.Type ~= prop.Type) or (IsPropertyReadable(IF, name) and not IsPropertyReadable(info.Owner, name)) or (IsPropertyWritable(IF, name) and not IsPropertyWritable(info.Owner, name)) then
                                if not iprop.Type then
                                    iprop.Type = prop.Type
                                    if iprop.Default ~= nil then
                                        iprop.Default = GetValidatedValue(iprop.Type, iprop.Default)
                                    end
                                else
                                    error(("The %s has wrong type property for [%s] %s(%s)."):format(tostring(info.Owner), tostring(IF), name, tostring(prop.Type)), stack)
                                end
                                if iprop.Default == nil then iprop.Default = prop.Default end
                            end
                        end
                    end
                end
            end
        end
    end

    function LoadInitTable(obj, initTable)
        for name, value in pairs(initTable) do obj[name] = value end
    end

    -- Init the object with class's constructor
    function Class1Obj(info, obj, ...)
        local count = select('#', ...)
        local initTable = select(1, ...)
        local ctor = info.Constructor or info.Ctor

        if not ( count == 1 and type(initTable) == "table" and getmetatable(initTable) == nil ) then initTable = nil end

        if ctor == nil then
            local sinfo = info

            while sinfo and not sinfo.Constructor do sinfo = _NSInfo[sinfo.SuperClass] end

            ctor = sinfo and sinfo.Constructor or false
            info.Ctor = ctor
        end

        if ctor then return ctor(obj, ...) end

        -- No constructor
        if initTable then
            local ok, msg = pcall(LoadInitTable, obj, initTable)
            if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 4) end
        end
    end

    -- The cache for constructor parameters
    function Class2Obj(info, ...)
        if ValidateFlags(MD_ABSTRACT_CLASS, info.Modifier) then error("The class is abstract, can't be used to create objects.", 3) end

        -- Check if the class is unique and already created one object to be return
        if getmetatable(info.UniqueObject) then
            -- Init the obj with new arguments
            Class1Obj(info, info.UniqueObject, ...)

            InitObjectWithInterface(info, info.UniqueObject)

            return info.UniqueObject
        end

        -- Check if this class has __exist so no need to create again.
        local meta = info.MetaTable.__exist
        if meta then
            local ok, obj = pcall(meta, ...)
            if ok and getmetatable(obj) == info.Owner then return obj end
        end

        -- Create new object
        local obj

        -- Create new table as the object(for some special using, its provided by the class)
        meta = info.MetaTable.__new
        if meta then
            local ok, ret = pcall(meta, ...)
            if ok and type(ret) == "table" then
                ok, ret = pcall(setmetatable, ret, info.MetaTable)
                if ok then
                    obj = ret
                    Class1Obj(info, obj, ...)
                end
            end
        end

        -- Check for simple class
        if not obj and select('#', ...) == 1 then
            -- Save memory cost for simple class
            local init = ...
            if type(init) == "table" and getmetatable(init) == nil then
                if info.IsSimpleClass then
                    obj = setmetatable(init, info.MetaTable)
                elseif info.AsSimpleClass then
                    local noConflict = true
                    for name, set in pairs(info.Cache) do
                        if type(set) == "table" then
                            -- Property | Event
                            if init[name] ~= nil then noConflict = false break end
                        else
                            -- Method
                            if init[name] ~= nil and type(init[name]) ~= "function" then noConflict = false break end
                        end
                    end
                    if noConflict then
                        obj = setmetatable(init, info.MetaTable)
                        Class1Obj(info, obj)
                    end
                end
            end
        end

        -- Default creation
        if not obj then
            obj = setmetatable({}, info.MetaTable)
            Class1Obj(info, obj, ...)
        end

        InitObjectWithInterface(info, obj)

        if info.UniqueObject then info.UniqueObject = obj end

        return obj
    end

    ------------------------------------
    --- Create class in currect environment's namespace or default namespace
    ------------------------------------
    function class(...)
        local env, name, definition, stack = checkTypeParams(...)

        local fenv = env or getfenv(stack) or _G

        local ok, cls = pcall(GetDefineNS, fenv, name, TYPE_CLASS)
        if not ok then error(cls:match("%d+:%s*(.-)$") or cls, stack) end

        local info = _NSInfo[cls]

        if not info then
            error([[Usage: class "name"]], stack)
        elseif info.Type and info.Type ~= TYPE_CLASS then
            error(("%s is existed as %s, not class."):format(tostring(name), tostring(info.Type)), stack)
        end

        -- Check if the class is final
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The class is sealed, can't be re-defined.", stack) end

        if not info.Type then
            info.Type = TYPE_CLASS
            info.Cache = {}
            GenerateMetaTable(info)
        end

        if ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, info.Owner, AttributeTargets.Class)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
        end

        if type(definition) == "table" then
            local ok, msg = pcall(ParseTableDefinition, info, definition)
            if not ok then error(msg:match("%d+:%s*(.-)$") or msg, stack) end

            RefreshCache(cls)
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, cls, AttributeTargets.Class)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
            end
            ValidateClass(info, stack + 1)

            return cls
        else
            local classEnv = setmetatable({
                [OWNER_FIELD] = cls,
                [BASE_ENV_FIELD] = fenv,
            }, _MetaClsDefEnv)

            -- Set namespace
            SetNameSpace4Env(classEnv, cls)

            if definition then
                setfenv(definition, classEnv)
                definition(classEnv)

                _KeyWord4ClsEnv:ClearKeyword()
                pcall(setmetatable, classEnv, _MetaClsEnv)
                RefreshCache(cls)
                if ATTRIBUTE_INSTALLED then
                    local ok, ret = pcall(ApplyRestAttribute, cls, AttributeTargets.Class)
                    if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
                end

                -- Validate the interface
                ValidateClass(info, stack + 1)

                return cls
            else
                -- save class to the environment
                if type(name) == "string" then rawset(fenv, name, cls) end

                setfenv(stack, classEnv)

                return classEnv
            end
        end
    end

    ------------------------------------
    --- End the class's definition and restore the environment
    ------------------------------------
    function endclass(env, name, stack)
        stack = stack or 2
        if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

        local info = _NSInfo[env[OWNER_FIELD]]

        if info.Name == name or info.Owner == name then
            _KeyWord4ClsEnv:ClearKeyword()
            setmetatable(env, _MetaClsEnv)
            setfenv(stack, env[BASE_ENV_FIELD])
            RefreshCache(info.Owner)
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, info.Owner, AttributeTargets.Class)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
            end
        else
            error(("%s is not closed."):format(info.Name), stack)
        end

        -- Validate the interface
        ValidateClass(info, stack + 1)

        return env[BASE_ENV_FIELD]
    end

    _KeyWord4ClsEnv.inherit = inherit_Def
    _KeyWord4ClsEnv.extend = extend_Cls
    _KeyWord4ClsEnv.import = import_Def
    _KeyWord4ClsEnv.event = event_Def
    _KeyWord4ClsEnv.property = property_Def
    _KeyWord4ClsEnv.endclass = endclass

    _KeyWord4ClsEnv.doc = document
end

------------------------------------------------------
------------------------ Enum ------------------------
------------------------------------------------------
do
    function BuildEnum(info, set)
        if type(set) ~= "table" then
            error([[Usage: enum "enumName" {
                "enumValue1",
                "enumValue2",
            }]], 2)
        end

        local cache = CACHE_TABLE()

        for i, v in pairs(set) do
            if type(i) == "string" then
                cache[strupper(i)] = v
            elseif type(v) == "string" then
                cache[strupper(v)] = v
            end
        end

        local old = info.Enum
        info.Enum = cache
        if old then CACHE_TABLE(old) end

        info.MaxValue = nil

        if ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, info.Owner, AttributeTargets.Enum)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end
        end

        -- Cache
        cache = CACHE_TABLE()
        for k, v in pairs(info.Enum) do cache[v] = k end

        old = info.Cache
        info.Cache = cache
        if old then CACHE_TABLE(old) end

        -- Default
        if info.Default ~= nil then
            local default = info.Default

            if type(default) == "string" and info.Enum[strupper(default)] then
                info.Default = info.Enum[strupper(default)]
            elseif cache[default] == nil then
                info.Default = nil
            end
        end
    end

    function GetShortEnumInfo(cls)
        if _NSInfo[cls] then
            local str
            for n in pairs(_NSInfo[cls].Enum) do
                if str and #str > 30 then str = str .. " | ..." break end
                str = str and (str .. " | " .. n) or n
            end
            return str or ""
        end
        return ""
    end

    ------------------------------------
    --- create a enumeration
    ------------------------------------
    function enum(...)
        local env, name, definition, stack = checkTypeParams(...)

        local fenv = env or getfenv(stack) or _G

        local ok, enm = pcall(GetDefineNS, fenv, name, TYPE_ENUM)
        if not ok then error(enm:match("%d+:%s*(.-)$") or enm, stack) end

        local info = _NSInfo[enm]

        if not info then
            error([[Usage: enum "name" {}]], stack)
        elseif info.Type and info.Type ~= TYPE_ENUM then
            error(("%s is existed as %s, not enum."):format(tostring(name), tostring(info.Type)), stack)
        end

        -- Check if the enum is final
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The enum is sealed, can't be re-defined.", stack) end

        info.Type = TYPE_ENUM

        if type(definition) == "table" then
            BuildEnum(info, definition)

            return enm
        else
            -- save enum to the environment
            if type(name) == "string" then rawset(fenv, name, enm) end

            return function(set) return BuildEnum(info, set) end
        end
    end
end

------------------------------------------------------
----------------------- Struct -----------------------
------------------------------------------------------
do
    _KeyWord4StrtEnv = _KeywordAccessor()

    STRUCT_TYPE_MEMBER = "MEMBER"
    STRUCT_TYPE_ARRAY  = "ARRAY"
    STRUCT_TYPE_CUSTOM = "CUSTOM"

    -- metatable for struct's env
    _MetaStrtEnv = { __metatable = true }
    _MetaStrtDefEnv = {}
    do
        local function __index(self, info, key)
            local value

            -- Check namespace
            if info.NameSpace then
                if key == _NSInfo[info.NameSpace].Name then
                    return info.NameSpace
                else
                    value = info.NameSpace[key]
                    if value ~= nil then return value end
                end
            end

            -- Check imports
            if rawget(self, IMPORT_ENV_FIELD) then
                for _, ns in ipairs(self[IMPORT_ENV_FIELD]) do
                    if key == _NSInfo[ns].Name then
                        return ns
                    else
                        value = ns[key]
                        if value ~= nil then return value end
                    end
                end
            end

            -- Check base namespace
            value = GetNameSpace(PROTYPE_NAMESPACE, key)
            if value then return value end

            -- Check Method
            value = info.Method and info.Method[key]
            if value then return value end

            -- Check Base
            return self[BASE_ENV_FIELD][key]
        end

        _MetaStrtEnv.__index = function(self, key)
            local info = _NSInfo[self[OWNER_FIELD]]
            local value

            -- Check owner
            if key == info.Name then return info.Owner end

            -- Check keywords
            value = _KeyWord4StrtEnv:GetKeyword(self, key)
            if value then return value end

            value = __index(self, info, key)
            if value ~= nil then rawset(self, key, value) return value end
        end

        _MetaStrtDefEnv.__index = function(self, key)
            local info = _NSInfo[self[OWNER_FIELD]]
            local value

            -- Check owner
            if key == info.Name then return info.Owner end

            -- Check keywords
            value = _KeyWord4StrtEnv:GetKeyword(self, key)
            if value then return value end

            return __index(self, info, key)
        end

        _MetaStrtDefEnv.__newindex = function(self, key, value)
            local info = _NSInfo[self[OWNER_FIELD]]

            if _KeyWord4StrtEnv:GetKeyword(self, key) then return error(("'%s' is a keyword."):format(key)) end

            if (key == info.Name or key == STRUCT_INIT_METHOD) or ((tonumber(key) or type(key) == "string") and type(value) == "function") then
                local ok, msg = pcall(SaveFeature, info, key, value)
                if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                return
            end

            if (type(key) == "string" or tonumber(key)) and IsNameSpace(value) and _NSInfo[value].Type then
                local ok, msg = pcall(SaveStructMember, info, key, value)
                if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 2) end
                return
            end

            return rawset(self, key, value)
        end

        _MetaStrtDefEnv.__call = function(self, definition)
            ParseStructDefinition(self, definition)

            local owner = self[OWNER_FIELD]

            setfenv(2, self[BASE_ENV_FIELD])
            _KeyWord4StrtEnv:ClearKeyword()
            pcall(setmetatable, self, _MetaStrtEnv)
            RefreshStruct(owner)

            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, owner, AttributeTargets.Struct)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end
            end

            return owner
        end
    end

    -- Some struct object may ref to each others, that would crash the validation
    _ValidatedCache = setmetatable({}, { __index= function(self, k) local v = setmetatable({}, WEAK_ALL) rawset(self, k, v) return v end, __mode = "k" })

    function ValidateStruct(info, value, onlyValidate)
        local sType  = info.SubType
        local vCache = _ValidatedCache[running() or 0]

        if sType ~= STRUCT_TYPE_CUSTOM then
            if vCache[value] then return value end  -- No twice validation for one table

            if type(value) ~= "table" then wipe(vCache) return error(("%s must be a table, got %s."):format("%s", type(value))) end
            if getmetatable(value) ~= nil then wipe(vCache) return error(("%s must be a table without meta-table."):format("%s")) end

            if not vCache[1] then vCache[1] = value end
            vCache[value] = true

            if sType == STRUCT_TYPE_MEMBER then
                local flag
                if onlyValidate then
                    for _, mem in ipairs(info.Members) do
                        local name = mem.Name
                        local val = value[name]

                        if val == nil then
                            if mem.Default == nil and mem.Require then wipe(vCache) return error(("%s.%s can't be nil."):format("%s", name)) end
                        else
                            flag, val = pcall(Validate4Type, mem.Type, val, name, nil, nil, onlyValidate)
                            if not flag then wipe(vCache) return error(strtrim(val:match(":%d+:%s*(.-)$") or val)) end
                        end
                    end
                else
                    for _, mem in ipairs(info.Members) do
                        local name = mem.Name
                        local val = value[name]

                        if val == nil then
                            local default = mem.Default
                            if default ~= nil then
                                -- Deep clone to make sure no change on default value
                                val = CloneObj(default, true)
                            elseif mem.Require then
                                wipe(vCache)
                                return error(("%s.%s can't be nil."):format("%s", name))
                            end
                        else
                            flag, val = pcall(Validate4Type, mem.Type, val, name, nil, nil, onlyValidate)
                            if not flag then wipe(vCache) return error(strtrim(val:match(":%d+:%s*(.-)$") or val)) end
                        end

                        value[name] = val
                    end
                end
            elseif sType == STRUCT_TYPE_ARRAY then
                local ele = info.ArrayElement

                if onlyValidate then
                    for i, v in ipairs(value) do
                        local flag, ret = pcall(Validate4Type, ele, v, "Element", nil, nil, onlyValidate)
                        if not flag then wipe(vCache) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret):gsub("%%s[_%w]+", "%%s["..i.."]")) end
                    end
                else
                    for i, v in ipairs(value) do
                        local flag, ret = pcall(Validate4Type, ele, v, "Element", nil, nil, onlyValidate)
                        if not flag then wipe(vCache) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret):gsub("%%s[_%w]+", "%%s["..i.."]")) end
                        value[i] = ret
                    end
                end
            end
        end

        -- Call Validator
        local i = STRT_START_VALID

        while info[i] do
            local flag, ret = pcall(info[i], value)
            if not flag then wipe(vCache) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
            i = i + 1
        end

        if not onlyValidate then
            i = STRT_START_INIT

            while info[i] do
                local flag, ret = pcall(info[i], value)
                if not flag then wipe(vCache) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
                if sType == STRUCT_TYPE_CUSTOM and ret ~= nil then value = ret end
                i = i + 1
            end

            if info.Cache and type(value) == "table" then
                for k, v in pairs(info.Cache) do
                    if value[k] == nil then value[k] = v end
                end
            end
        end

        if sType ~= STRUCT_TYPE_CUSTOM and vCache[1] == value then wipe(vCache) end

        return value
    end

    FLAG_STRT_CUSTOM    = 2^0
    FLAG_STRT_MEMBER    = 2^1
    FLAG_STRT_ARRAY     = 2^2
    FLAG_STRT_SVALID    = 2^3
    FLAG_STRT_MVALID    = 2^4
    FLAG_STRT_SINIT     = 2^5
    FLAG_STRT_MINIT     = 2^6
    FLAG_STRT_METHOD    = 2^7

    _RawValidateBuilder = {}

    function GenerateRawValidate(info)
        local sToken    = 0
        local upValues  = CACHE_TABLE()

        if info.SubType == STRUCT_TYPE_CUSTOM then
            sToken = TurnOnFlags(FLAG_STRT_CUSTOM, sToken)
        elseif info.SubType == STRUCT_TYPE_MEMBER then
            sToken = TurnOnFlags(FLAG_STRT_MEMBER, sToken)
        else
            sToken = TurnOnFlags(FLAG_STRT_ARRAY, sToken)
        end

        if info[STRT_START_VALID] then
            if info[STRT_START_VALID + 1] then
                local i = STRT_START_VALID + 1
                while info[i + 1] do i = i + 1 end
                sToken = TurnOnFlags(FLAG_STRT_MVALID, sToken)
                tinsert(upValues, i)
            else
                sToken = TurnOnFlags(FLAG_STRT_SVALID, sToken)
            end
        end

        if info[STRT_START_INIT] then
            if info[STRT_START_INIT + 1] then
                local i = STRT_START_INIT + 1
                while info[i + 1] do i = i + 1 end
                sToken = TurnOnFlags(FLAG_STRT_MINIT, sToken)
                tinsert(upValues, i)
            else
                sToken = TurnOnFlags(FLAG_STRT_SINIT, sToken)
            end
        end

        if info.Cache then
            sToken = TurnOnFlags(FLAG_STRT_METHOD, sToken)
        end

        -- Building
        if not _RawValidateBuilder[sToken] then
            local gHeader = CACHE_TABLE()
            local gbody   = CACHE_TABLE()

            tinsert(gbody, "") -- Remain for closure values
            tinsert(gbody, [[return function(info, value, onlyValidate)]])

            if ValidateFlags(FLAG_STRT_MEMBER, sToken) or ValidateFlags(FLAG_STRT_ARRAY, sToken) then
                tinsert(gbody, [[
                    local vCache = _ValidatedCache[running() or 0]
                    if vCache[value] then return value end
                    if type(value) ~= "table" then wipe(vCache) return error(("%s must be a table, got %s."):format("%s", type(value))) end
                    if getmetatable(value) ~= nil then wipe(vCache) return error(("%s must be a table without meta-table."):format("%s")) end

                    if not vCache[1] then vCache[1] = value end
                    vCache[value] = true
                ]])
            end

            -- Validation for member and array
            if ValidateFlags(FLAG_STRT_MEMBER, sToken) then
                tinsert(gbody, [[
                    local flag
                    if onlyValidate then
                        for _, mem in ipairs(info.Members) do
                            local name = mem.Name
                            local val = value[name]

                            if val == nil then
                                if mem.Default == nil and mem.Require then wipe(vCache) return error(("%s.%s can't be nil."):format("%s", name)) end
                            else
                                flag, val = pcall(Validate4Type, mem.Type, val, name, nil, nil, onlyValidate)
                                if not flag then wipe(vCache) return error(strtrim(val:match(":%d+:%s*(.-)$") or val)) end
                            end
                        end
                    else
                        for _, mem in ipairs(info.Members) do
                            local name = mem.Name
                            local val = value[name]

                            if val == nil then
                                local default = mem.Default
                                if default ~= nil then
                                    -- Deep clone to make sure no change on default value
                                    val = CloneObj(default, true)
                                elseif mem.Require then
                                    wipe(vCache)
                                    return error(("%s.%s can't be nil."):format("%s", name))
                                end
                            else
                                flag, val = pcall(Validate4Type, mem.Type, val, name, nil, nil, onlyValidate)
                                if not flag then wipe(vCache) return error(strtrim(val:match(":%d+:%s*(.-)$") or val)) end
                            end

                            value[name] = val
                        end
                    end
                ]])
            elseif ValidateFlags(FLAG_STRT_ARRAY, sToken) then
                tinsert(gbody, [[
                    local ele = info.ArrayElement
                    if onlyValidate then
                        for i, v in ipairs(value) do
                            local flag, ret = pcall(Validate4Type, ele, v, "Element", nil, nil, onlyValidate)
                            if not flag then wipe(vCache) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret):gsub("%%s[_%w]+", "%%s["..i.."]")) end
                        end
                    else
                        for i, v in ipairs(value) do
                            local flag, ret = pcall(Validate4Type, ele, v, "Element", nil, nil, onlyValidate)
                            if not flag then wipe(vCache) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret):gsub("%%s[_%w]+", "%%s["..i.."]")) end
                            value[i] = ret
                        end
                    end
                ]])
            end

            -- Custom Validation
            if ValidateFlags(FLAG_STRT_SVALID, sToken) then
                tinsert(gbody, [[
                    local flag, ret = pcall(info[]]..STRT_START_VALID..[[], value)
                    if not flag then wipe(_ValidatedCache[running() or 0]) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
                ]])
            elseif ValidateFlags(FLAG_STRT_MVALID, sToken) then
                tinsert(gHeader, "nvalidator")
                tinsert(gbody, [[
                    for i = ]] .. STRT_START_VALID .. [[, nvalidator do
                        local flag, ret = pcall(info[i], value)
                        if not flag then wipe(_ValidatedCache[running() or 0]) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
                    end
                ]])
            end

            if ValidateFlags(FLAG_STRT_SINIT, sToken) or ValidateFlags(FLAG_STRT_MINIT, sToken) or ValidateFlags(FLAG_STRT_METHOD, sToken) then
                tinsert(gbody, [[if not onlyValidate then]])

                -- Custom Initializer
                if ValidateFlags(FLAG_STRT_SINIT, sToken) then
                    tinsert(gbody, [[
                        local flag, ret = pcall(info[]].. STRT_START_INIT ..[[], value)
                        if not flag then wipe(_ValidatedCache[running() or 0]) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
                    ]])
                    if ValidateFlags(FLAG_STRT_CUSTOM, sToken) then
                        tinsert(gbody, [[if ret ~= nil then value = ret end]])
                    end
                elseif ValidateFlags(FLAG_STRT_MINIT, sToken) then
                    tinsert(gHeader, "ninitializer")
                    tinsert(gbody, [[
                        for i = ]] .. STRT_START_INIT .. [[, ninitializer do
                            local flag, ret = pcall(info[i], value)
                            if not flag then wipe(_ValidatedCache[running() or 0]) return error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
                    ]])
                    if ValidateFlags(FLAG_STRT_CUSTOM, sToken) then
                        tinsert(gbody, [[if ret ~= nil then value = ret end]])
                    end
                    tinsert(gbody, [[end]])
                end

                if ValidateFlags(FLAG_STRT_METHOD, sToken) then
                    tinsert(gbody, [[
                        if type(value) == "table" then
                            for k, v in pairs(info.Cache) do
                                if value[k] == nil then value[k] = v end
                            end
                        end
                    ]])
                end

                tinsert(gbody, [[end]])
            end

            if ValidateFlags(FLAG_STRT_MEMBER, sToken) or ValidateFlags(FLAG_STRT_ARRAY, sToken) then
                tinsert(gbody, [[if vCache[1] == value then wipe(vCache) end]])
            end

            tinsert(gbody, [[return value]])
            tinsert(gbody, [[end]])

            if #gHeader > 0 then
                gbody[1] = "local " .. tblconcat(gHeader, ",") .. "=..."
            end
            _RawValidateBuilder[sToken] = loadInEnv(tblconcat(gbody, "\n"), "Struct_Validate_"..tostring(sToken))
            CACHE_TABLE(gHeader)
            CACHE_TABLE(gbody)
        end

        local rs = _RawValidateBuilder[sToken](unpack(upValues))
        CACHE_TABLE(upValues)
        return rs
    end

    function Struct2Obj(info, ...)
        local strt = info.Owner

        local count = select("#", ...)
        local initTable = select(1, ...)
        local initErrMsg

        if not ( count == 1 and type(initTable) == "table" and getmetatable(initTable) == nil ) then initTable = nil end

        if initTable then
            local ok, value = pcall(info.RawValidate, info, initTable)
            if ok then return value end
            initErrMsg = value
        end

        -- Default Constructor
        if info.SubType == STRUCT_TYPE_MEMBER then
            local ret = {}

            if info.Members then for i, n in ipairs(info.Members) do ret[n.Name] = select(i, ...) end end

            local ok, value = pcall(info.RawValidate, info, ret)
            if ok then return value end
            value = initErrMsg or value
            value = strtrim(value:match(":%d+:%s*(.-)$") or value)
            value = value:gsub("%%s%.", ""):gsub("%%s", "")

            local args = ""
            for i, n in ipairs(info.Members) do if i == 1 then args = n.Name else args = args..", "..n.Name end end
            error(("Usage : %s(%s) - %s"):format(tostring(strt), args, value), 3)
        elseif info.SubType == STRUCT_TYPE_ARRAY then
            local ret = {}

            for i = 1, select('#', ...) do ret[i] = select(i, ...) end

            local ok, value = pcall(info.RawValidate, info, ret)
            if ok then return value end

            value = initErrMsg or value
            value = strtrim(value:match(":%d+:%s*(.-)$") or value)
            value = value:gsub("%%s%.", ""):gsub("%%s", "")
            error(("Usage : %s(...) - %s"):format(tostring(strt), value), 3)
        else
            -- For custom struct
            local ok, value = pcall(info.RawValidate, info, (...))
            if ok then return value end
            error(strtrim(value:match(":%d+:%s*(.-)$") or value):gsub("%%s", "[".. info.Name .."]"), 3)
        end
    end

    ------------------------------------
    --- create a structure
    ------------------------------------
    function struct(...)
        local env, name, definition, stack = checkTypeParams(...)

        local fenv = env or getfenv(stack) or _G

        local ok, strt = pcall(GetDefineNS, fenv, name, TYPE_STRUCT)
        if not ok then error(strt:match("%d+:%s*(.-)$") or strt, stack) end

        local info = _NSInfo[strt]

        if not info then
            error([[Usage: struct "name"]], stack)
        elseif info.Type and info.Type ~= TYPE_STRUCT then
            error(("%s is existed as %s, not struct."):format(tostring(name), tostring(info.Type)), stack)
        end

        -- Check if the struct is final
        if ValidateFlags(MD_SEALED_FEATURE, info.Modifier) then error("The struct is sealed, can't be re-defined.", stack) end

        if not info.Type then
            info.Type = TYPE_STRUCT
            info.SubType = STRUCT_TYPE_MEMBER
        else
            -- Clear the defintions
            for i = #info, 0, -1 do info[i] = nil end
            info.BaseStruct = nil
        end
        info.RawValidate = ValidateStruct

        -- Clear Attribute
        if ATTRIBUTE_INSTALLED then
            local ok, ret = pcall(ConsumePreparedAttributes, info.Owner, AttributeTargets.Struct)
            if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
        end

        if type(definition) == "table" then
            local ok, msg = pcall(ParseTableDefinition, info, definition)
            if not ok then error(msg:match("%d+:%s*(.-)$") or msg, stack) end

            RefreshStruct(strt)
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, strt, AttributeTargets.Struct)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
            end

            return strt
        else
            local strtEnv = setmetatable({
                [OWNER_FIELD] = strt,
                [BASE_ENV_FIELD] = fenv,
            }, _MetaStrtDefEnv)

            -- Set namespace
            SetNameSpace4Env(strtEnv, strt)

            if definition then
                setfenv(definition, strtEnv)
                definition(strtEnv)

                _KeyWord4StrtEnv:ClearKeyword()
                pcall(setmetatable, strtEnv, _MetaStrtEnv)
                RefreshStruct(strt)
                if ATTRIBUTE_INSTALLED then
                    local ok, ret = pcall(ApplyRestAttribute, strt, AttributeTargets.Struct)
                    if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
                end

                return strt
            else
                -- save struct to the environment
                if type(name) == "string" then rawset(fenv, name, strt) end

                setfenv(stack, strtEnv)

                return strtEnv
            end
        end
    end

    ------------------------------------
    --- End the class's definition and restore the environment
    ------------------------------------
    function endstruct(env, name, stack)
        stack = stack or 2
        if ATTRIBUTE_INSTALLED then ClearPreparedAttributes() end

        local info = _NSInfo[env[OWNER_FIELD]]

        if info.Name == name or info.Owner == name then
            _KeyWord4StrtEnv:ClearKeyword()
            setmetatable(env, _MetaStrtEnv)
            setfenv(stack, env[BASE_ENV_FIELD])
            RefreshStruct(info.Owner)
            if ATTRIBUTE_INSTALLED then
                local ok, ret = pcall(ApplyRestAttribute, info.Owner, AttributeTargets.Struct)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), stack) end
            end
            return env[BASE_ENV_FIELD]
        else
            error(("%s is not closed."):format(info.Name), stack)
        end
    end

    function ParseStructDefinition(self, definition)
        local info = _NSInfo[self[OWNER_FIELD]]

        if type(definition) == "table" then
            local ok, msg = pcall(ParseTableDefinition, info, definition)
            if not ok then error(msg:match("%d+:%s*(.-)$") or msg, 3) end
        else
            if type(definition) == "string" then
                local errorMsg
                definition, errorMsg = loadstring("return function(_ENV) " .. definition .. " end")
                if definition then
                    definition = definition()
                else
                    error(errorMsg, 3)
                end
            end

            if type(definition) == "function" then
                setfenv(definition, self)
                return definition(self)
            end
        end
    end

    _KeyWord4StrtEnv.struct = struct
    _KeyWord4StrtEnv.import = import_Def
    _KeyWord4StrtEnv.endstruct = endstruct
    _KeyWord4StrtEnv.member = member_Def
end

------------------------------------------------------
------------ Definition Environment Update -----------
------------------------------------------------------
do
    _KeywordAccessor("interface", interface)
    _KeywordAccessor("class", class)
    _KeywordAccessor("enum", enum)
    _KeywordAccessor("struct", struct)
end

------------------------------------------------------
--------- System NameSpace (Basic Features) ----------
------------------------------------------------------
do
    namespace "System"

    ------------------------------------------------------
    -- Basic Structs
    ------------------------------------------------------
    struct "Boolean"    { false, [STRUCT_INIT_METHOD] = function (value) return value and true or false end }
    struct "BooleanNil" { [STRUCT_INIT_METHOD] = function (value) return value and true or false end }
    struct "RawBoolean" { false, function (value) if type(value) ~= "boolean" then error(("%s must be a boolean, got %s."):format("%s", type(value))) end end }
    struct "String"     { function (value) if type(value) ~= "string" then error(("%s must be a string, got %s."):format("%s", type(value))) end end }
    struct "Number"     { 0, function (value) if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end end }
    struct "NumberNil"  { function (value) if type(value) ~= "number" then error(("%s must be a number, got %s."):format("%s", type(value))) end end }
    struct "Function"   { function (value) if type(value) ~= "function" then error(("%s must be a function, got %s."):format("%s", type(value))) end end }
    struct "Table"      { function (value) if type(value) ~= "table" then error(("%s must be a table, got %s."):format("%s", type(value))) end end }
    struct "RawTable"   { function (value) assert(type(value) == "table" and getmetatable(value) == nil, "%s must be a table without metatable.") end }
    struct "Userdata"   { function (value) if type(value) ~= "userdata" then error(("%s must be a userdata, got %s."):format("%s", type(value))) end end }
    struct "Thread"     { function (value) if type(value) ~= "thread" then error(("%s must be a thread, got %s."):format("%s", type(value))) end end }
    struct "Any"        { }

    struct "Lambda" (function (_ENV)
        _LambdaCache = setmetatable({}, WEAK_VALUE)

        function Lambda(value)
            assert(type(value) == "string" and value:find("=>"), "%s must be a string like 'x,y=>x+y'")
            local func = _LambdaCache[value]
            if not func then
                local param, body = value:match("^(.-)=>(.+)$")
                local args
                if param then for arg in param:gmatch("[_%w]+") do args = (args and args .. "," or "") .. arg end end
                if args then
                    func = loadstring(("local %s = ... return %s"):format(args, body or ""), value)
                    if not func then
                        func = loadstring(("local %s = ... %s"):format(args, body or ""), value)
                    end
                else
                    func = loadstring("return " .. (body or ""), value)
                    if not func then
                        func = loadstring(body or "", value)
                    end
                end
                assert(func, "%s must be a string like 'x,y=>x+y'")
                _LambdaCache[value] = func
            end
        end

        function __init(value)
            return _LambdaCache[value]
        end
    end)

    struct "Callable" {
        function (value)
            if type(value) == "string" then return _NSInfo[Lambda]:RawValidate(value, true) end
            assert(Reflector.IsCallable(value), "%s isn't callable.")
        end,
        [STRUCT_INIT_METHOD] = function(value)
            if type(value) == "string" then return Lambda(value) end
            return value
        end,
    }

    struct "Guid" (function (_ENV)
        if math.randomseed and os.time then math.randomseed(os.time()) end

        local GUID_TEMPLTE = [[xx-x-x-x-xxx]]
        local GUID_FORMAT = "^" .. GUID_TEMPLTE:gsub("x", "%%x%%x%%x%%x"):gsub("%-", "%%-") .. "$"
        local random = math.random

        local function GenerateGUIDPart(v) return strformat("%04X", random(0xffff)) end

        function Guid(value)
            if value == nil then return end
            if type(value) ~= "string" or #value ~= 36 or not value:match(GUID_FORMAT) then
                error("%s require data with format like '" .. GUID_TEMPLTE:gsub("x", GenerateGUIDPart) .."'.")
            end
        end

        function __init(value)
            if value == nil then return (GUID_TEMPLTE:gsub("x", GenerateGUIDPart)) end
        end
    end)

    struct "Class"      { function (value) assert(Reflector.IsClass(value), "%s must be a class.") end }
    struct "Interface"  { function (value) assert(Reflector.IsInterface(value), "%s must be an interface.") end }
    struct "Struct"     { function (value) assert(Reflector.IsStruct(value), "%s must be a struct.") end }
    struct "Enum"       { function (value) assert(Reflector.IsEnum(value), "%s must be an enum.") end }
    struct "AnyType"    { function (value) local info = _NSInfo[value] assert(info and info.Type, "%s must be a type, such as enum, struct, class or interface.") end }
    struct "NameSpace"  { function (value) assert(_NSInfo[value], "%s must be a namespace") end, [STRUCT_INIT_METHOD] = function(value) return _NSInfo[value].Owner end }

    ------------------------------------------------------
    -- System.AttributeTargets
    ------------------------------------------------------
    enum "AttributeTargets" {
        All = 0,
        Class = 1,
        Constructor = 2,
        Enum = 4,
        Event = 8,
        Interface = 16,
        Method = 32,
        Property = 64,
        Struct = 128,
        Member = 256,
        NameSpace = 512,
        ObjectMethod = 1024,
    }

    enum "AttributePriorty" {
        Highest = 2,
        Higher = 1,
        Normal = 0,
        Lower = -1,
        Lowest = -2,
    }

    ------------------------------------------------------
    -- System.Reflector
    ------------------------------------------------------
    interface "Reflector" (function(_ENV)

        local iterForEmpty = function() end

        doc "Reflector" [[This interface contains many apis used to get the running object-oriented system's informations.]]

        doc "GetCurrentNameSpace" [[
            <desc>Get the namespace used by the environment</desc>
            <param name="env" type="table" optional="true">the environment, default the current environment</param>
            <param name="rawOnly" type="boolean" optional="true">skip metatable settings if true</param>
            <return type="namespace">the namespace of the environment</return>
        ]]
        function GetCurrentNameSpace(env, rawOnly)
            return GetNameSpace4Env(type(env) == "table" and env or getfenv(2) or _G, rawOnly)
        end

        doc "SetCurrentNameSpace" [[
            <desc>set the namespace used by the environment</desc>
            <param name="ns" type="namespace|string|nil">the namespace that set for the environment</param>
            <param name="env" type="table" optional="true">the environment, default the current environment</param>
        ]]
        function SetCurrentNameSpace(ns, env)
            return SetNameSpace4Env(type(env) == "table" and env or getfenv(2) or _G, ns)
        end

        doc "GetNameSpaceForName" [[
            <desc>Get the namespace by the name</desc>
            <param name="name" type="string">the namespace's name, split by "."</param>
            <return type="namespace">the namespace</return>
            <usage>ns = System.Reflector.GetNameSpaceForName("System")</usage>
        ]]
        function GetNameSpaceForName(name)
            return GetNameSpace(PROTYPE_NAMESPACE, name)
        end

        doc "GetSuperNameSpace" [[
            <desc>Get the upper namespace of the target</desc>
            <param name="name" type="namespace|string">the target namespace</param>
            <return>The target's namesapce</return>
            <usage>ns = System.Reflector.GetSuperNameSpace("System.Object")</usage>
        ]]
        function GetSuperNameSpace(ns)
            local info = _NSInfo[ns]
            return info and info.NameSpace
        end

        doc "GetNameSpaceType" [[
            <desc>Get the type of the namespace</desc>
            <param name="name" type="namespace|string">the namespace</param>
            <return type="string">The namespace's type like NameSpace|Class|Struct|Enum|Interface</return>
            <usage>type = System.Reflector.GetNameSpaceType("System.Object")</usage>
        ]]
        function GetNameSpaceType(ns)
            local info = _NSInfo[ns]
            return info and info.Type
        end

        doc "GetNameSpaceName" [[
            <desc>Get the name of the namespace</desc>
            <param name="namespace">the namespace to query</param>
            <return type="string">the namespace's name</return>
            <usage>System.Reflector.GetNameSpaceName(System.Object)</usage>
        ]]
        function GetNameSpaceName(ns)
            local info = _NSInfo[ns]
            return info and info.Name
        end

        doc "GetNameSpaceFullName" [[
            <desc>Get the full name of the namespace</desc>
            <param name="namespace">the namespace to query</param>
            <return type="string">the full path of the namespace</return>
            <usage>path = System.Reflector.GetNameSpaceFullName(System.Object)</usage>
        ]]
        GetNameSpaceFullName = tostring

        doc "BeginDefinition" [[
            <desc>Begin the definition of target namespace, stop cache refresh</desc>
            <param name="namespace|string">the namespace</param>
        ]]
        function BeginDefinition(ns)
            local info = _NSInfo[ns]
            assert(info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE or info.Type == TYPE_STRUCT), "System.Reflector.BeginDefinition(ns) - ns must be a class, interface or struct.")
            info.BeginDefinition = true
        end

        doc "EndDefinition" [[
            <desc>End the definition of target namespace, refresh the cache</desc>
            <param name="namespace|string">the namespace</param>
        ]]
        function EndDefinition(ns)
            local info = _NSInfo[ns]
            assert(info and (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE or info.Type == TYPE_STRUCT), "System.Reflector.EndDefinition(ns) - ns must be a class, interface or struct.")
            info.BeginDefinition = nil
            if info.Type == TYPE_STRUCT then
                return RefreshStruct(info.Owner)
            else
                return RefreshCache(info.Owner)
            end
        end

        doc "GetSuperClass" [[
            <desc>Get the superclass of the class</desc>
            <param name="class">the class object to query</param>
            <return type="class">the super class if existed</return>
            <usage>System.Reflector.GetSuperClass(System.Object)</usage>
        ]]
        function GetSuperClass(ns)
            local info = _NSInfo[ns]
            return info and info.SuperClass
        end

        doc "IsNameSpace" [[
            <desc>Check if the object is a NameSpace</desc>
            <param name="object">the object to query</param>
            <return type="boolean">true if the object is a NameSpace</return>
            <usage>System.Reflector.IsNameSpace(System.Object)</usage>
        ]]
        IsNameSpace = IsNameSpace

        doc "IsClass" [[
            <desc>Check if the namespace is a class</desc>
            <param name="object">the object to query</param>
            <return type="boolean">true if the object is a class</return>
            <usage>System.Reflector.IsClass(System.Object)</usage>
        ]]
        function IsClass(ns)
            local info = _NSInfo[ns]
            return info and info.Type == TYPE_CLASS or false
        end

        doc "IsStruct" [[
            <desc>Check if the namespace is a struct</desc>
            <param name="object">the object to query</param>
            <return type="boolean">true if the object is a struct</return>
            <usage>System.Reflector.IsStruct(System.Object)</usage>
        ]]
        function IsStruct(ns)
            local info = _NSInfo[ns]
            return info and info.Type == TYPE_STRUCT or false
        end

        doc "IsEnum" [[
            <desc>Check if the namespace is an enum</desc>
            <param name="object">the object to query</param>
            <return type="boolean">true if the object is a enum</return>
            <usage>System.Reflector.IsEnum(System.Object)</usage>
        ]]
        function IsEnum(ns)
            local info = _NSInfo[ns]
            return info and info.Type == TYPE_ENUM or false
        end

        doc "IsInterface" [[
            <desc>Check if the namespace is an interface</desc>
            <param name="object">the object to query</param>
            <return type="boolean">true if the object is an Interface</return>
            <usage>System.Reflector.IsInterface(System.IFSocket)</usage>
        ]]
        function IsInterface(ns)
            local info = _NSInfo[ns]
            return info and info.Type == TYPE_INTERFACE or false
        end

        doc "GetSubNamespace" [[
            <desc>Get the sub namespace of the namespace</desc>
            <param name="namespace">the object to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the sub-namespace iterator|the result table</return>
            <usage>for name, ns in System.Reflector.GetSubNamespace(System) do print(name) end</usage>
        ]]
        local _GetSubNamespaceCache, _GetSubNamespaceIter
        if not SAVE_MEMORY then
            _GetSubNamespaceCache = setmetatable({}, WEAK_ALL)
        else
            _GetSubNamespaceIter = function (ns, key) return next(_NSInfo[ns].SubNS, key) end
        end
        function GetSubNamespace(ns, result)
            local info = _NSInfo[ns]

            if info and info.SubNS then
                if type(result) == "table" then
                    for k, v in pairs(info.SubNS) do result[k] = v end
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetSubNamespaceIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetSubNamespaceCache[ns]
                        if not iter then
                            local subNS = info.SubNS
                            iter = function (ns, key) return next(subNS, key) end
                            _GetSubNamespaceCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetExtendInterfaces" [[
            <desc>Get the extend interfaces of the class|interface</desc>
            <param name="object">the object to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the extend interface iterator|the result table</return>
            <usage>for i, interface in System.Reflector.GetExtendInterfaces(System.Object) do print(interface) end</usage>
        ]]
        local _GetExtendInterfacesCache, _GetExtendInterfacesIter
        if not SAVE_MEMORY then
            _GetExtendInterfacesCache = setmetatable({}, WEAK_ALL)
        else
            _GetExtendInterfacesIter = function (ns, index)
                index = index + 1
                local IF = _NSInfo[ns].ExtendInterface[index]
                if IF then return index, IF end
            end
        end
        function GetExtendInterfaces(ns, result)
            local info = _NSInfo[ns]

            if info and info.ExtendInterface then
                if type(result) == "table" then
                    for _, IF in ipairs(info.ExtendInterface) do tinsert(result, IF) end
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetExtendInterfacesIter, info.Owner, 0
                    else
                        ns = info.Owner
                        local iter = _GetExtendInterfacesCache[ns]
                        if not iter then
                            local eIF = info.ExtendInterface
                            iter = function (ns, index)
                                index = index + 1
                                local IF = eIF[index]
                                if IF then return index, IF end
                            end
                            _GetExtendInterfacesCache[ns] = iter
                        end
                        return iter, ns, 0
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner, 0
            end
        end

        doc "GetAllExtendInterfaces" [[
            <desc>Get all the extend interfaces of the class|interface</desc>
            <param name="object">the object to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the all extend interface iterator|the result table</return>
            <usage>for _, IF in System.Reflector.GetAllExtendInterfaces(System.Object) do print(IF) end</usage>
        ]]
        local _GetAllExtendInterfacesCache, _GetAllExtendInterfacesIter
        if not SAVE_MEMORY then
            _GetAllExtendInterfacesCache = setmetatable({}, WEAK_ALL)
        else
            _GetAllExtendInterfacesIter = function (ns, index)
                index = index + 1
                local IF = _NSInfo[ns].Cache4Interface[index]
                if IF then return index, IF end
            end
        end
        function GetAllExtendInterfaces(ns, result)
            local info = _NSInfo[ns]

            if info and info.Cache4Interface then
                if type(result) == "table" then
                    for _, IF in ipairs(info.Cache4Interface) do tinsert(result, IF) end
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetAllExtendInterfacesIter, info.Owner, 0
                    else
                        ns = info.Owner
                        local iter = _GetAllExtendInterfacesCache[ns]
                        if not iter then
                            local eIF = info.Cache4Interface
                            iter = function (ns, index)
                                index = index + 1
                                local IF = eIF[index]
                                if IF then return index, IF end
                            end
                            _GetAllExtendInterfacesCache[ns] = iter
                        end
                        return iter, ns, 0
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner, 0
            end
        end

        doc "GetEvents" [[
            <desc>Get the events of the class|interface</desc>
            <param name="class|interface">the class or interface to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the event iterator|the result table</return>
            <usage>for name in System.Reflector.GetEvents(System.Object) do print(name) end</usage>
        ]]
        local _GetEventsCache, _GetEventsIter
        if not SAVE_MEMORY then
            _GetEventsCache = setmetatable({}, WEAK_ALL)
        else
            _GetEventsIter = function (ns, key)
                local evt = _NSInfo[ns].Event
                return evt and next(evt, key)
            end
        end
        function GetEvents(ns, result)
            local info = _NSInfo[ns]

            if info and info.Event then
                if type(result) == "table" then
                    for k in pairs(info.Event) do tinsert(result, k) end
                    sort(result)
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetEventsIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetEventsCache[ns]
                        if not iter then
                            local evts = info.Event
                            iter = function (ns, key) return (next(evts, key)) end
                            _GetEventsCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetAllEvents" [[
            <desc>Get all the events of the class</desc>
            <param name="class|interface">the class or interface to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the event iterator|the result table</return>
            <usage>for name in System.Reflector.GetAllEvents(System.Object) do print(name) end</usage>
        ]]
        local _GetAllEventsCache, _GetAllEventsIter
        if not SAVE_MEMORY then
            _GetAllEventsCache = setmetatable({}, WEAK_ALL)
        else
            _GetAllEventsIter = function (ns, key) for k, v in next, _NSInfo[ns].Cache, key do if getmetatable(v) then return k end end end
        end
        function GetAllEvents(ns, result)
            local info = _NSInfo[ns]

            if info and info.Cache then
                if type(result) == "table" then
                    for k, v in pairs(info.Cache) do if getmetatable(v) then tinsert(result, k) end end
                    sort(result)
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetAllEventsIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetAllEventsCache[ns]
                        if not iter then
                            local cache = info.Cache
                            iter = function (ns, key) for k, v in next, cache, key do if getmetatable(v) then return k end end end
                            _GetAllEventsCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetProperties" [[
            <desc>Get the properties of the class|interface</desc>
            <param name="object">the class or interface to query</param>|
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the property iterator|the result table</return>
            <usage>for name in System.Reflector.GetProperties(System.Object) do print(name) end</usage>
        ]]
        local _GetPropertiesCache, _GetPropertiesIter
        if not SAVE_MEMORY then
            _GetPropertiesCache = setmetatable({}, WEAK_ALL)
        else
            _GetPropertiesIter = function (ns, key)
                local prop = _NSInfo[ns].Property
                return prop and next(prop, key)
            end
        end
        function GetProperties(ns, result)
            local info = _NSInfo[ns]

            if info and info.Property then
                if type(result) == "table" then
                    for k in pairs(info.Property) do tinsert(result, k) end
                    sort(result)
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetPropertiesIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetPropertiesCache[ns]
                        if not iter then
                            local props = info.Property
                            iter = function (ns, key) return (next(props, key)) end
                            _GetPropertiesCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetAllProperties" [[
            <desc>Get all the properties of the class|interface</desc>
            <param name="object">the class or interface to query</param>|
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the property iterator|the result table</return>
            <usage>for name in System.Reflector.GetAllProperties(System.Object) do print(name) end</usage>
        ]]
        local _GetAllPropertiesCache, _GetAllPropertiesIter
        if not SAVE_MEMORY then
            _GetAllPropertiesCache = setmetatable({}, WEAK_ALL)
        else
            _GetAllPropertiesIter = function (ns, key)
                for k, v in next, _NSInfo[ns].Cache, key do if type(v) == "table" and not getmetatable(v) then return k end end
            end
        end
        function GetAllProperties(ns, result)
            local info = _NSInfo[ns]

            if info and info.Cache then
                if type(result) == "table" then
                    for k, v in pairs(info.Cache) do if type(v) == "table" and not getmetatable(v) then tinsert(result, k) end end
                    sort(result)
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetAllPropertiesIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetAllPropertiesCache[ns]
                        if not iter then
                            local cache = info.Cache
                            iter = function (ns, key)
                                for k, v in next, cache, key do if type(v) == "table" and not getmetatable(v) then return k end end
                            end
                            _GetAllPropertiesCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetMethods" [[
            <desc>Get the methods of the class|interface</desc>
            <param name="object">the class or interface to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the method iterator|the result table</return>
            <usage>for name in System.Reflector.GetMethods(System.Object) do print(name) end</usage>
        ]]
        local _GetMethodsCache, _GetMethodsIter
        if not SAVE_MEMORY then
            _GetMethodsCache = setmetatable({}, WEAK_ALL)
        else
            _GetMethodsIter = function (ns, key)
                local method = _NSInfo[ns].Method
                return method and next(method, key)
            end
        end
        function GetMethods(ns, result)
            local info = _NSInfo[ns]

            if info and info.Method then
                if type(result) == "table" then
                    for k in pairs(info.Method) do tinsert(result, k) end
                    sort(result)
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetMethodsIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetMethodsCache[ns]
                        if not iter then
                            local methods = info.Method
                            iter = function (ns, key) return (next(methods, key)) end
                            _GetMethodsCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetAllMethods" [[
            <desc>Get all the methods of the class|interface</desc>
            <param name="object">the class or interface to query</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the method iterator|the result table</return>
            <usage>for name in System.Reflector.GetAllMethods(System.Object) do print(name) end</usage>
        ]]
        local _GetAllMethodsCache, _GetAllMethodsIter
        if not SAVE_MEMORY then
            _GetAllMethodsCache = setmetatable({}, WEAK_ALL)
        else
            _GetAllMethodsIter = function (ns, key)
                local info = _NSInfo[ns]
                local methods = info.Cache or info.Method

                if methods then
                    for k, v in next, methods, key do if type(v) == "function" then return k end end
                end
            end
        end
        function GetAllMethods(ns, result)
            local info = _NSInfo[ns]

            if info and (info.Cache or info.Method) then
                if type(result) == "table" then
                    for k, v in pairs(info.Cache or info.Method) do if type(v) == "function" then tinsert(result, k) end end
                    sort(result)
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetAllMethodsIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetAllMethodsCache[ns]
                        if not iter then
                            local cache = info.Cache or info.Method
                            iter = function (ns, key)
                                for k, v in next, cache, key do if type(v) == "function" then return k end end
                            end
                            _GetAllMethodsCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "HasMetaMethod" [[
            <desc>Whether the class has the meta-method</desc>
            <param name="class">the query class</param>
            <param name="meta-method">the result table</param>
            <return type="boolean">true if the class has the meta-method</return>
            <usage>print(System.Reflector.HasMetaMethod(System.Object, "__call")</usage>
        ]]
        function HasMetaMethod(ns, name)
            local info = _NSInfo[ns]
            return info and info.MetaTable and info.MetaTable[_KeyMeta[name]] and true or false
        end

        doc "GetPropertyType" [[
            <desc>Get the property type of the property</desc>
            <param name="owner" type="class|interface">the property's owner</param>
            <param name="name" type="string">the property name</param>
            <return type="System.Type">the property type</return>
            <usage>System.Reflector.GetPropertyType(System.Object, "Name")</usage>
        ]]
        function GetPropertyType(ns, name)
            local info = _NSInfo[ns]

            if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
                local prop = info.Cache[name] or info.Property and info.Property[name]
                return type(prop) == "table" and getmetatable(prop) == nil and prop.Type or nil
            end
        end

        doc "HasProperty" [[
            <desc>whether the property is existed</desc>
            <param name="owner" type="class|interface">The owner of the property</param>
            <param name="name" type="string">The property's name</param>
            <return type="boolean">true if the class|interface has the property</return>
            <usage>System.Reflector.HasProperty(System.Object, "Name")</usage>
        ]]
        function HasProperty(ns, name)
            local info = _NSInfo[ns]

            if info and (info.Type == TYPE_INTERFACE or info.Type == TYPE_CLASS) then
                local prop = info.Cache[name] or info.Property and info.Property[name]
                if type(prop) == "table" and getmetatable(prop) == nil then return true end
            end
            return false
        end

        doc "IsPropertyReadable" [[
            <desc>whether the property is readable</desc>
            <param name="owner" type="class|interface">the property's owner</param>
            <param name="name" type="string">the property's name</param>
            <return type="boolean">true if the property is readable</return>
            <usage>System.Reflector.IsPropertyReadable(System.Object, "Name")</usage>
        ]]
        IsPropertyReadable = IsPropertyReadable

        doc "IsPropertyWritable" [[
            <desc>whether the property is writable</desc>
            <param name="owner" type="class|interface">the property's owner</param>
            <param name="name" type="string">the property's name</param>
            <return type="boolean">true if the property is writable</return>
            <usage>System.Reflector.IsPropertyWritable(System.Object, "Name")</usage>
        ]]
        IsPropertyWritable = IsPropertyWritable

        doc "GetEnums" [[
            <desc>Get the enumeration keys of the enum</desc>
            <param name="enum" type="enum">the enum tyep</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the enum key iterator|the result table</return>
            <usage>System.Reflector.GetEnums(System.AttributeTargets)</usage>
        ]]
        local _GetEnumsCache, _GetEnumsIter
        if not SAVE_MEMORY then
            _GetEnumsCache = setmetatable({}, WEAK_ALL)
        else
            _GetEnumsIter = function (ns, key) return next(_NSInfo[ns].Enum, key) end
        end
        function GetEnums(ns, result)
            local info = _NSInfo[ns]

            if info and info.Enum then
                if type(result) == "table" then
                    for k, v in pairs(info.Enum) do result[k] = v end
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetEnumsIter, info.Owner
                    else
                        ns = info.Owner
                        local iter = _GetEnumsCache[ns]
                        if not iter then
                            local enums = info.Enum
                            iter = function (ns, key) return next(enums, key) end
                            _GetEnumsCache[ns] = iter
                        end
                        return iter, ns
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "ValidateFlags" [[
            <desc>Whether the value is contains on the target value</desc>
            <param name="checkValue" type="number">like 1, 2, 4, 8, ...</param>
            <param name="targetValue" type="number">like 3 : (1 + 2)</param>
            <return type="boolean">true if the targetValue contains the checkValue</return>
        ]]
        ValidateFlags = ValidateFlags

        doc "HasEvent" [[
            <desc>Check if the class|interface has that event</desc>
            <param name="owner" type="class|interface">the event's owner</param>|interface
            <param name="event" type="string">the event's name</param>
            <return type="boolean">if the owner has the event</return>
            <usage>System.Reflector.HasEvent(Addon, "OnEvent")</usage>
        ]]
        function HasEvent(ns, evt)
            local info = _NSInfo[ns]
            return info and info.Cache and getmetatable(info.Cache[evt]) and true or false
        end

        doc "GetStructType" [[
            <desc>Get the type of the struct type</desc>
            <param name="struct" type="System.Struct">the struct</param>
            <return type="string">the type of the struct type</return>
        ]]
        function GetStructType(ns)
            local info = _NSInfo[ns]
            return info and info.Type == TYPE_STRUCT and info.SubType or nil
        end

        doc "GetStructArrayElement" [[
            <desc>Get the array element types of the struct</desc>
            <param name="struct" type="System.Struct">the struct type</param>
            <return type="System.Type">the array element's type</return>
        ]]
        function GetStructArrayElement(ns)
            local info = _NSInfo[ns]
            return info and info.Type == TYPE_STRUCT and info.SubType == STRUCT_TYPE_ARRAY and info.ArrayElement or nil
        end

        doc "HasStructMember" [[
            <desc>Whether the struct has the query member</desc>
            <param name="struct" type="System.Struct">the struct type</param>
            <param name="member" type="string">the query member</param>
            <return type="boolean">true if the struct has the member</return>
        ]]
        function HasStructMember(ns, member)
            local info = _NSInfo[ns]

            return info and info.Type == TYPE_STRUCT and info.SubType == STRUCT_TYPE_MEMBER
                and info.Members and info.Members[member] and true or false
        end

        doc "GetStructMembers" [[
            <desc>Get the parts of the struct type</desc>
            <param name="struct" type="System.Struct">the struct type</param>
            <param name="result" optional="true">the result table</param>
            <return name="iterator|result">the member iterator|the result table</return>
            <usage>for _, member in System.Reflector.GetStructMembers(Position) do print(member) end</usage>
        ]]
        local _GetStructMembersCache, _GetStructMembersIter
        if not SAVE_MEMORY then
            _GetStructMembersCache = setmetatable({}, WEAK_ALL)
        else
            _GetStructMembersIter = function (ns, key)
                local mem = _NSInfo[ns].Members[key]
                if mem then return key + 1, mem.Name end
            end
        end
        function GetStructMembers(ns, result)
            local info = _NSInfo[ns]

            if info and info.Members then
                if type(result) == "table" then
                    for _, member in ipairs(info.Members) do tinsert(result, member.Name) end
                    return result
                else
                    if SAVE_MEMORY then
                        return _GetStructMembersIter, info.Owner, 1
                    else
                        local members = info.Members
                        local iter = _GetStructMembersCache[members]
                        if not iter then
                            iter = function (ns, key)
                                local mem = members[key]
                                if mem then return key + 1, mem.Name end
                            end
                            _GetStructMembersCache[members] = iter
                        end
                        return iter, ns, 1
                    end
                end
            else
                return type(result) == "table" and result or iterForEmpty, info.Owner
            end
        end

        doc "GetStructMember" [[
            <desc>Get the member's type of the struct</desc>
            <param name="struct" type="System.Struct">the struct type</param>
            <param name="member" type="string">the member's name</param>
            <return type="System.Type">the member's type</return>
            <return type="System.Any">the member's default value</return>
            <return type="System.Boolean">whether the member is required</return>
            <usage>System.Reflector.GetStructMember(Position, "x")</usage>
        ]]
        function GetStructMember(ns, part)
            local info = _NSInfo[ns]

            if info and info.Type == TYPE_STRUCT then
                if info.SubType == STRUCT_TYPE_MEMBER and info.Members then
                    local mem = info.Members[part]
                    if mem then return mem.Type, mem.Default, mem.Require end
                elseif info.SubType == STRUCT_TYPE_ARRAY then
                    return info.ArrayElement
                end
            end
        end

        doc "IsSuperClass" [[
            <desc>Check if this class is inherited from the target class</desc>
            <param name="class" type="class">the child class</param>
            <param name="superclass" type="class">the super class</param>
            <return type="boolean">true if the class is inherited from the target class</return>
            <usage>System.Reflector.IsSuperClass(UIObject, Object)</usage>
        ]]
        function IsSuperClass(child, super)
            if type(child) == "string" then child = GetNameSpaceForName(child) end
            if type(super) == "string" then super = GetNameSpaceForName(super) end

            return IsClass(child) and IsClass(super) and IsChildClass(super, child)
        end

        doc "IsExtendedInterface" [[
            <desc>Check if the class|interface is extended from the interface</desc>
            <param name="object" type="interface|class">the class or interface</param>
            <param name="interface" type="interface">the target interface</param>
            <return type="boolean">true if the first arg is extend from the second</return>
            <usage>System.Reflector.IsExtendedInterface(UIObject, IFSocket)</usage>
        ]]
        function IsExtendedInterface(cls, IF)
            if type(cls) == "string" then cls = GetNameSpaceForName(cls) end
            if type(IF) == "string" then IF = GetNameSpaceForName(IF) end

            return IsExtend(IF, cls)
        end

        doc "GetObjectClass" [[
            <desc>Get the class type of the object</desc>
            <param name="object">the object</param>
            <return type="class">the object's class</return>
            <usage>System.Reflector.GetObjectClass(obj)</usage>
        ]]
        function GetObjectClass(object)
            local cls = getmetatable(object)
            local info = _NSInfo[cls]
            return info and info.Type == TYPE_CLASS and cls or nil
        end

        doc "ObjectIsClass" [[
            <desc>Check if this object is an instance of the class</desc>
            <param name="object">the object</param>
            <param name="class">the class</param>
            <return type="boolean">true if the object is an instance of the class or it's child class</return>
            <usage>System.Reflector.ObjectIsClass(obj, Object)</usage>
        ]]
        function ObjectIsClass(obj, ns)
            return IsChildClass(type(ns) == "string" and GetNameSpaceForName(ns) or ns, GetObjectClass(obj)) or false
        end

        doc "ObjectIsInterface" [[
            <desc>Check if this object is an instance of the interface</desc>
            <param name="object">the object</param>
            <param name="interface">the interface</param>
            <return type="boolean">true if the object's class is extended from the interface</return>
            <usage>System.Reflector.ObjectIsInterface(obj, IFSocket)</usage>
        ]]
        function ObjectIsInterface(obj, ns)
            return IsExtend(type(ns) == "string" and GetNameSpaceForName(ns) or ns, GetObjectClass(obj)) or false
        end

        doc "FireObjectEvent" [[
            <desc>Fire an object's event, to trigger the object's event handlers</desc>
            <param name="object">the object</param>
            <param name="event">the event name</param>
            <param name="...">the event's arguments</param>
        ]]
        function FireObjectEvent(obj, evt, ...)
            -- Don't do check, the cost must be reduced.
            local handler = rawget(_NSInfo[getmetatable(obj)].Cache[evt], obj)
            if handler then return handler(obj, ...) end
        end

        doc "BlockEvent" [[
            <desc>Block event for object</desc>
            <param name="object">the object</param>
            <param name="...">the event name list</param>
            <usage>System.Reflector.BlockEvent(obj, "OnClick", "OnEnter")</usage>
        ]]
        function BlockEvent(obj, ...)
            local cls = GetObjectClass(obj)
            local name

            if cls then
                for i = 1, select('#', ...) do
                    name = select(i, ...)

                    if HasEvent(cls, name) then obj[name].Blocked = true end
                end
            end
        end

        doc "IsEventBlocked" [[
            <desc>Whether the event is blocked for object</desc>
            <param name="object">the object</param>
            <param name="event">the event's name</param>
            <return type="boolean">true if the event is blocked</return>
            <usage>System.Reflector.IsEventBlocked(obj, "OnClick")</usage>
        ]]
        function IsEventBlocked(obj, sc)
            local cls = GetObjectClass(obj)
            local name

            if cls and HasEvent(cls, sc) then return obj[sc].Blocked end

            return false
        end

        doc "UnBlockEvent" [[
            <desc>Un-Block event for object</desc>
            <param name="object">the object</param>
            <param name="...">the event name list</param>
            <usage>System.Reflector.UnBlockEvent(obj, "OnClick", "OnEnter")</usage>
        ]]
        function UnBlockEvent(obj, ...)
            local cls = GetObjectClass(obj)
            local name

            if cls then
                for i = 1, select('#', ...) do
                    name = select(i, ...)

                    if HasEvent(cls, name) then obj[name].Blocked = false end
                end
            end
        end

        doc "Validate" [[
            <desc>Validating the value to the given type.</desc>
            <format>type, value, name[, prefix[, stacklevel] ]</format>
            <param name="Type">The test type</param>
            <param name="value">the test value</param>
            <param name="name">the parameter's name</param>
            <param name="prefix">the prefix string</param>
            <param name="stacklevel">the stack level, default 1</param>
            <return>the validated value</return>
            <usage>System.Reflector.Validate(System.String, "Test")</usage>
        ]]
        function Validate(oType, value, name, prefix, stacklevel)
            stacklevel = floor(type(stacklevel) == "number" and stacklevel > 1 and stacklevel or 1)

            if type(name) ~= "string" then name = "value" end
            if oType == nil then return value end

            assert(_NSInfo[oType] and _NSInfo[oType].Type, "Usage : System.Reflector.Validate(type, value[, name[, prefix[, stacklevel]]]) : oType - must be enum, struct, class or interface.")

            local ok

            ok, value = pcall(Validate4Type, oType, value)

            if not ok then
                value = strtrim(value:match(":%d+:%s*(.-)$") or value):gsub("%%s([_%w]+)", name .. ".%1"):gsub("%%s[_%w]*", name)

                if type(prefix) == "string" then
                    return error(prefix .. value, 1 + stacklevel)
                else
                    return error(value, 1 + stacklevel)
                end
            end

            return value
        end

        doc "GetValidatedValue" [[
            <desc>Get validated value for the type</desc>
            <param name="oType">The test type</param>
            <param name="value">the test value</param>
            <param name="onlyValidate" optional="true">Whether only validate the value</param>
            <return>the validated value, nil if the value can't pass the validation</return>
        ]]
        GetValidatedValue = GetValidatedValue

        doc "GetDocument" [[
            <desc>Get the document</desc>
            <param name="owner">the document's owner</param>
            <param name="name" optional="true">the query name, default the owner's name</param>
            <param name="targetType" optional="true" type="System.AttributeTargets">the query target type, can be auto-generated by the name</param>
            <return type="string">the document</return>
        ]]
        GetDocument = GetDocument

        doc "IsEqual" [[
            <desc>Whether the two objects are objects with same settings</desc>
            <param name="obj1">the object used to compare</param>
            <param name="obj2">the object used to compare to</param>
            <return type="boolean">true if the obj1 has same settings with the obj2</return>
        ]]
        IsEqual = IsEqual

        doc "Clone" [[
            <desc>Clone the object if possible</desc>
            <param name="obj">the object to be cloned</param>
            <param name="deep" optional="true" type="boolean">whether deep clone</param>
            <return type="object">the clone or the object itself</return>
        ]]
        Clone = CloneObj

        doc "GetDefaultValue" [[
            <desc>Get the default value of the target['s part]</desc>
            <param name="ns">the target(class, interface, struct)</param>
            <param name="part" optional="true">the target's part(property, member)</param>
            <return type="object">the default value if existed</return>
        ]]
        function GetDefaultValue(ns, part)
            local info = _NSInfo[ns]
            if info then
                if (info.Type == TYPE_CLASS or info.Type == TYPE_INTERFACE) and part then
                    part = info.Cache[part]
                    if type(part) == "table" and getmetatable(part) == nil and type(part.Default) ~= "function" then
                        return CloneObj(part.Default, true)
                    end
                elseif info.Type == TYPE_ENUM then
                    return info.Default
                elseif info.Type == TYPE_STRUCT then
                    if info.SubType == STRUCT_TYPE_CUSTOM and not part then
                        return CloneObj(info.Default, true)
                    elseif info.SubType == STRUCT_TYPE_MEMBER and part then
                        local mem = info.Members and info.Members[part]
                        if mem then return CloneObj(mem.Default, true) end
                    end
                end
            end
        end

        doc "IsCallable" [[
            <desc>Whether the object is callable(function or table with __call meta-method)</desc>
            <param name="obj">The object need to check</param>
            <return>boolean, true if the object is callable</return>
        ]]
        function IsCallable(obj)
            if type(obj) == "function" then return true end
            local cls = GetObjectClass(obj)
            local info = cls and rawget(_NSInfo, cls)

            return info and info.Type == TYPE_CLASS and info.MetaTable.__call and true or false
        end

        doc "LoadLuaFile" [[
            <desc>Load the lua file and return any features that may be created by the file</desc>
            <param name="path">the file's path</param>
            <return type="table">the hash table use feature types as key</return>
        ]]
        function LoadLuaFile(path)
            local f = assert(loadfile(path))

            if f then
                RecordNSFeatures()

                local ok, msg = pcall(f)

                local ret = GetNsFeatures()

                assert(ok, msg)

                return ret
            end
        end
    end)
end

------------------------------------------------------
-------------------- Event Classes -------------------
------------------------------------------------------
do
    namespace( nil )

    EVENT_MAP = setmetatable({}, WEAK_VALUE)
    PROTYPE_EVENT = newproxy(true)

    getmetatable(PROTYPE_EVENT).__call = function(self, owner, ...)
        local handler = rawget(EVENT_MAP[self], owner)
        if handler then return handler(owner, ...) end
    end

    getmetatable(PROTYPE_EVENT).__metatable = TYPE_EVENT

    class "Event" (function(_ENV)
        doc "Event" [[The object event definition]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function OnEventHandlerChanged(owner) end

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Userdata" [[The userdata represent for the event]]
        property "Userdata" {
            Default = function(self)
                local usrdt = newproxy(PROTYPE_EVENT)
                EVENT_MAP[usrdt] = self
                return usrdt
            end
        }

        doc "Name" [[The event's name]]
        property "Name" { Type = String, Default = "Anonymous" }

        doc "Delegate" [[The delegate for the event handler, used to wrap the event call]]
        property "Delegate" { Type = Function }

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        function Event(self, name)
            if type(name) == "string" then self.Name = name end
        end

        ------------------------------------------------------
        -- Meta-Method
        ------------------------------------------------------
        function __tostring(self) return ("%s( %q )"):format(tostring(Event), self.Name) end

        function __call(self, owner, ...)
            local handler = rawget(self, owner)
            if handler then return handler(owner, ...) end
        end
    end)

    class "EventHandler" (function(_ENV)
        doc "EventHandler" [[The object event handler]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function OnEventHandlerChanged(owner) end

        doc "IsEmpty" [[
            <desc>Check if the event handler is empty</desc>
            <return type="boolean">true if the event handler has no functions</return>
        ]]
        function IsEmpty(self) return #self == 0 and self[0] == nil end

        doc "Clear" [[Clear all handlers]]
        function Clear(self)
            if #self > 0 or self[0] then
                for i = 1, #self do self[tremove(self)] = nil end self[0] = nil
                return self:OnEventHandlerChanged()
            end
        end

        doc "Copy" [[
            <desc>Copy handlers from the source event handler</desc>
            <param name="src" type="System.EventHandler">the event handler source</param>
        ]]
        function Copy(self, src)
            if self ~= src and getmetatable(src) == EventHandler and self.Event == src.Event then
                for i = 1, #self do self[tremove(self)] = nil end self[0] = nil
                for i, f in ipairs(src) do self[i] = f if src[f] then self[f] = src[f] end end self[0] = src[0]

                return self:OnEventHandlerChanged()
            end
        end

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Owner" [[The owner of the event handler]]
        property "Owner" { Type = Table }

        doc "Event" [[The event's name]]
        property "Event" { Type = String }

        doc "Blocked" [[Whether the event handler is blocked]]
        property "Blocked" { Type = Boolean }

        doc "Handler" [[The customer's handler]]
        property "Handler" { Field = 0, Type = Function, Handler = function(self) return self:OnEventHandlerChanged() end }

        doc "Delegate" [[The delegate for the event handler, used to wrap the event call]]
        property "Delegate" { Type = Function }

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        function EventHandler(self, evt, owner)
            self.Event = evt.Name
            self.Owner = owner
            self.Delegate = evt.Delegate
            self.OnEventHandlerChanged = evt.OnEventHandlerChanged

            -- Register the owner
            evt[owner] = self
        end

        ------------------------------------------------------
        -- Meta-Method
        ------------------------------------------------------
        function __add(self, func)
            if type(func) ~= "function" then error("Usage: obj.OnXXXX = obj.OnXXXX + func", 2) end

            local objMethod

            -- Object Method
            if _NSInfo[getmetatable(self.Owner)].EnableObjMethodAttr and HasPreparedAttribute() then
                local ok, ret = pcall(ConsumePreparedAttributes, func, AttributeTargets.ObjectMethod, self.Owner, self.Event)
                if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret), 2) end
                objMethod = ret
            end

            for i, f in ipairs(self) do
                if f == func or self[f] == func then
                    self[i] = objMethod or func
                    if self[f] then self[f] = nil end
                    if objMethod then self[objMethod] = func end
                    return self
                end
            end

            tinsert(self, objMethod or func)
            if objMethod then self[objMethod] = func end

            self:OnEventHandlerChanged()

            return self
        end

        function __sub(self, func)
            if type(func) ~= "function" then error("Usage: obj.OnXXXX = obj.OnXXXX - func", 2) end

            for i, f in ipairs(self) do
                if f == func or self[f] == func then
                    tremove(self, i)
                    if self[f] then self[f] = nil end

                    self:OnEventHandlerChanged()
                    break
                end
            end

            return self
        end

        local function raiseEvent(self, owner, ...)
            local ret = false

            -- Call the stacked handlers
            for _, handler in ipairs(self) do
                ret = handler(owner, ...) or rawget(owner, "Disposed")

                -- Any handler return true means to stop all
                if ret then break end
            end

            -- Call the custom handler
            return not ret and self[0] and self[0](owner, ...)
        end

        function __call(self, obj, ...)
            if self.Blocked then return end

            local owner = self.Owner
            local delegte = self.Delegate

            if delegte then
                if owner == obj then
                    return delegte(raiseEvent, self, obj, ...)
                else
                    return delegte(raiseEvent, self, owner, obj, ...)
                end
            else
                if owner == obj then
                    return raiseEvent(self, obj, ...)
                else
                    return raiseEvent(self, owner, obj, ...)
                end
            end
        end
    end)
end

------------------------------------------------------
------------------ Attribute System ------------------
------------------------------------------------------
do
    namespace "System"

    ------------------------------------------------------
    -- Attribute Core
    ------------------------------------------------------
    do
        _PreparedAttributes = setmetatable({}, {
            __mode = "k",
            __call = function(self)
                local thread = running() or 0
                local val = self[thread] or {}
                self[thread] = val
                return val
            end,
        })

        _AttributeMap = setmetatable({}, WEAK_KEY)

        _ApplyRestAttribute = setmetatable({}, WEAK_KEY)

        -- Recycle the cache for dispose attributes
        _AttributeCache4Dispose = setmetatable({}, {
            __call = function(self, cache)
                if cache then
                    for attr in pairs(cache) do
                        if getmetatable(attr) then
                            DisposeObject(attr)
                        end
                    end
                    wipe(cache)
                    tinsert(self, cache)
                else
                    return tremove(self) or {}
                end
            end,
        })

        function DisposeAttributes(config)
            if type(config) ~= "table" then return end
            if getmetatable(config) then
                return DisposeObject(config)
            else
                for _, attr in pairs(config) do DisposeAttributes(attr) end
                return wipe(config)
            end
        end

        function GetSuperAttributes(target, targetType, owner, name)
            local info = _NSInfo[owner or target]

            if targetType == AttributeTargets.Class then
                return info.SuperClass and _AttributeMap[info.SuperClass]
            end

            if targetType == AttributeTargets.Event or
                targetType == AttributeTargets.Method or
                targetType == AttributeTargets.Property then

                local star = info.SuperClass and _NSInfo[info.SuperClass].Cache[name]

                if not star and info.ExtendInterface then
                    for _, IF in ipairs(info.ExtendInterface) do
                        star = _NSInfo[IF].Cache[name]
                        if star then break end
                    end
                end

                if star then
                    if targetType == AttributeTargets.Event and getmetatable(star) then return _AttributeMap[star] end
                    if targetType == AttributeTargets.Method and type(star) == "function" then return _AttributeMap[star] end
                    if targetType == AttributeTargets.Property and type(star) == "table" and not getmetatable(star) then return _AttributeMap[star] end
                end
            end
        end

        function SaveTargetAttributes(target, targetType, config)
            if targetType == AttributeTargets.Constructor or targetType == AttributeTargets.ObjectMethod then
                DisposeAttributes(config)
            else
                _AttributeMap[target] = config
            end
        end

        function GetAttributeUsage(target)
            local config = _AttributeMap[target]

            if not config then
                return
            elseif getmetatable(config) then
                return getmetatable(config) == __AttributeUsage__ and config or nil
            else
                for _, attr in ipairs(config) do if getmetatable(attr) == __AttributeUsage__ then return attr end end
            end
        end

        function ParseAttributeTarget(target, targetType, owner, name)
            if not owner or owner == target then
                return ("[%s]%s"):format(_NSInfo[owner].Type, tostring(owner))
            elseif _NSInfo[owner] then
                return ("[%s]%s [%s]%s"):format(_NSInfo[owner].Type, tostring(owner), AttributeTargets(targetType), name or "anonymous")
            elseif getmetatable(owner) and _NSInfo[getmetatable(owner)] then -- Mean owner is an object
                return ("[Object]%s [%s]%s"):format(tostring(getmetatable(owner)), AttributeTargets(targetType), name or "anonymous")
            end
        end

        function ValidateAttributeUsable(config, attr, skipMulti, chkOverride)
            local cls = getmetatable(config)
            if cls then
                if cls == getmetatable(attr) then
                    local usage = GetAttributeUsage(cls)
                    if chkOverride and usage and usage.Overridable then return true end
                    if IsEqual(config, attr) then return false end
                    if not skipMulti and (not usage or not usage.AllowMultiple) then return false end
                end
            else
                for _, v in ipairs(config) do if not ValidateAttributeUsable(v, attr, skipMulti, chkOverride) then return false end end
            end

            return true
        end

        function ApplyRestAttribute(target, targetType)
            local args = _ApplyRestAttribute[target]
            if args then
                _ApplyRestAttribute[target] = nil
                local start, config = args[1], args[2]
                CACHE_TABLE(args)
                return ApplyAttributes(target, targetType, nil, nil, start, config, true, true)
            end
        end

        function ApplyAttributes(target, targetType, owner, name, start, config, halt, atLast)
            -- Check config
            config = config or _AttributeMap[target]

            -- Clear
            SaveTargetAttributes(target, targetType, nil)

            -- Apply the attributes
            if config then
                local oldTarget = target
                local ok, ret, arg1, arg2, arg3, arg4
                local hasAfter = false
                local isMethod = targetType == AttributeTargets.Method or targetType == AttributeTargets.Constructor or targetType == AttributeTargets.ObjectMethod

                -- Some target can't be send to the attribute's ApplyAttribute directly
                if targetType == AttributeTargets.Event then
                    arg1 = target.Name
                    arg2 = targetType
                    arg3 = owner
                    arg4 = target.Name
                elseif isMethod then
                    arg1 = target
                    arg2 = targetType
                    arg3 = owner
                    arg4 = name
                elseif targetType == AttributeTargets.Property or targetType == AttributeTargets.Member then
                    arg1 = target.Predefined
                    arg2 = targetType
                    arg3 = owner
                    arg4 = name
                else
                    arg1 = target
                    arg2 = targetType
                end

                if getmetatable(config) then
                    local usage = GetAttributeUsage(getmetatable(config))
                    if not halt or atLast or (usage and usage.BeforeDefinition) then
                        -- ok, ret = pcall(config.ApplyAttribute, config, arg1, arg2, arg3, arg4)
                        ret = config.ApplyAttribute(config, arg1, arg2, arg3, arg4)

                        if usage and not usage.Inherited and usage.RunOnce then
                            DisposeObject(config)
                            config = nil
                        end

                        if isMethod then
                            -- The method may be wrapped in the apply operation
                            if ret and ret ~= target and type(ret) == "function" then
                                target = ret
                                arg1 = target
                            end
                        end
                    else
                        hasAfter = true
                    end
                else
                    start = start or 1

                    for i = #config, start, -1 do
                        local usage = GetAttributeUsage(getmetatable(config[i]))

                        if not halt or (not atLast and usage and usage.BeforeDefinition) or (atLast and (not usage or not usage.BeforeDefinition)) then
                            ret = config[i].ApplyAttribute(config[i], arg1, arg2, arg3, arg4)

                            if usage and not usage.Inherited and usage.RunOnce then
                                DisposeObject(tremove(config, i))
                            end

                            if isMethod then
                                -- The method may be wrapped in the apply operation
                                if ret and ret ~= target and type(ret) == "function" then
                                    target = ret
                                    arg1 = target
                                end
                            end
                        else
                            hasAfter = true
                        end
                    end

                    if #config == 0 or #config == 1 then config = config[1] or nil end
                end

                if halt and hasAfter then
                    local args = CACHE_TABLE()
                    args[1] = start
                    args[2] = config

                    _ApplyRestAttribute[target] = args
                end
            end

            SaveTargetAttributes(target, targetType, config)

            return target
        end

        function SendAttributeToPrepared(self)
            -- Send to prepared cache
            local prepared = _PreparedAttributes()
            for i, v in ipairs(prepared) do if v == self then return end end
            tinsert(prepared, self)
        end

        function RemoveAttributeToPrepared(self)-- Send to prepared cache
            local prepared = _PreparedAttributes()
            for i, v in ipairs(prepared) do if v == self then return tremove(prepared, i) end end
        end

        function ClearPreparedAttributes(noDispose)
            local prepared = _PreparedAttributes()
            if not noDispose then for _, attr in ipairs(prepared) do DisposeObject(attr) end end
            wipe(prepared)
        end

        function HasPreparedAttribute()
            local thread = running() or 0
            local val = _PreparedAttributes[thread]
            return val and #val > 0
        end

        function SortAttribute(self)
            local start, stop = 1, #self

            local swaped = true
            local j

            local compare = function(a, b)
                return a.Priorty < b.Priorty or (a.Priorty == b.Priorty and a.SubLevel < b.SubLevel)
            end

            while stop > start and swaped do
                swaped = false

                i = start
                j = stop

                while i < stop do
                    if compare(self[i+1], self[i]) then
                        self[i], self[i+1] = self[i+1], self[i]
                        swaped = true
                    end

                    if compare(self[j], self[j - 1]) then
                        self[j], self[j - 1] = self[j - 1], self[j]
                        swaped = true
                    end

                    j = j - 1
                    i = i + 1
                end

                -- Reduce the Check range
                start = start  + 1
                stop = stop - 1
            end
        end

        function ConsumePreparedAttributes(target, targetType, owner, name)
            owner = owner or target

            -- Consume the prepared Attributes
            local prepared = _PreparedAttributes()

            -- Filter with the usage
            if #prepared > 0 then
                local cls, usage
                local noUseAttr = _AttributeCache4Dispose()
                local usableAttr = _AttributeCache4Dispose()

                for i = 1, #prepared do
                    local attr = prepared[i]
                    cls = getmetatable(attr)
                    usage = GetAttributeUsage(cls)

                    if usage and usage.AttributeTarget > 0 and not ValidateFlags(targetType, usage.AttributeTarget) then
                        ClearPreparedAttributes()
                        error("Can't apply the " .. tostring(cls) .. " attribute to the " .. ParseAttributeTarget(target, targetType, owner, name))
                    elseif ValidateAttributeUsable(usableAttr, attr) then
                        usableAttr[attr] = true
                        tinsert(usableAttr, attr)
                    else
                        ClearPreparedAttributes()
                        error("Can't apply the " .. tostring(cls) .. " attribute for multi-times.")
                    end
                end

                for i = #prepared, 1, -1 do
                    local attr = prepared[i]
                    if not usableAttr[attr] then
                        noUseAttr[tremove(prepared, i)] = true
                    end
                end

                wipe(usableAttr)
                _AttributeCache4Dispose(usableAttr)
                _AttributeCache4Dispose(noUseAttr)
            end

            -- Check if already existed
            local pconfig = _AttributeMap[target]

            if pconfig then
                if #prepared > 0 then
                    local noUseAttr = _AttributeCache4Dispose()

                    -- remove equal attributes
                    for i = #prepared, 1, -1 do
                        if not ValidateAttributeUsable(pconfig, prepared[i], true, true) then
                            noUseAttr[tremove(prepared, i)] = true
                        end
                    end

                    _AttributeCache4Dispose(noUseAttr)

                    if prepared and #prepared > 0 then
                        -- Erase old no-multi attributes
                        if getmetatable(pconfig) then
                            if not ValidateAttributeUsable(prepared, pconfig) then
                                SaveTargetAttributes(target, targetType, nil)
                                DisposeObject(pconfig)
                            end
                        else
                            for i = #pconfig, 1, -1 do
                                if not ValidateAttributeUsable(prepared, pconfig[i]) then
                                    DisposeObject(tremove(pconfig, i))
                                end
                            end

                            if #pconfig == 0 then SaveTargetAttributes(target, targetType, nil) end
                        end
                    end
                end
            else
                local sconfig = GetSuperAttributes(target, targetType, owner, name)
                if sconfig then
                    -- get inheritable attributes from superTarget
                    local usage

                    if getmetatable(sconfig) then
                        usage = GetAttributeUsage(getmetatable(sconfig))

                        if not usage or usage.Inherited then
                            if ValidateAttributeUsable(prepared, sconfig) then sconfig:Clone() end
                        end
                    else
                        for _, attr in ipairs(sconfig) do
                            usage = GetAttributeUsage(getmetatable(attr))

                            if not usage or usage.Inherited then
                                if ValidateAttributeUsable(prepared, attr) then attr:Clone() end
                            end
                        end
                    end
                end
            end

            -- Save & apply the attributes for target
            if #prepared > 0 then
                local start = 1
                local config = nil

                if pconfig then
                    config = pconfig

                    if getmetatable(config) then config = { config } end

                    start = #config + 1

                    for _, attr in ipairs(prepared) do tinsert(config, attr) end

                else
                    if #prepared == 1 then
                        config = prepared[1]
                    else
                        config = { unpack(prepared) }
                    end
                end

                wipe(prepared)

                -- Sort the attribute by priorty and sublevel
                if not getmetatable(config) then SortAttribute(config) end

                if targetType == AttributeTargets.Interface or targetType == AttributeTargets.Struct or targetType == AttributeTargets.Class then
                    ApplyAttributes(target, targetType, owner, name, start, config, true)
                else
                    target = ApplyAttributes(target, targetType, owner, name, start, config) or target
                end
            end

            ClearPreparedAttributes()

            return target
        end

        function InheritAttributes(source, target, targetType)
            if source == target then return end

            local sconfig = _AttributeMap[source]

            -- Save & apply the attributes for target
            if sconfig then
                local config = _AttributeMap[target]
                local hasAttr = false

                -- Check existed attributes
                if getmetatable(sconfig) then
                    local usage = GetAttributeUsage(getmetatable(sconfig))
                    if (not usage or usage.Inherited) and (not config or ValidateAttributeUsable(config, sconfig)) then
                        sconfig:Clone()
                        hasAttr = true
                    end
                else
                    for i = 1, #sconfig do
                        local usage = GetAttributeUsage(getmetatable(sconfig[i]))
                        if (not usage or usage.Inherited) and (not config or ValidateAttributeUsable(config, sconfig[i])) then
                            sconfig[i]:Clone()
                            hasAttr = true
                        end
                    end
                end

                if hasAttr then
                    local ok, ret = pcall(ConsumePreparedAttributes, target, targetType)
                    if not ok then error(strtrim(ret:match(":%d+:%s*(.-)$") or ret)) end
                end
            end
        end
    end

    ------------------------------------------------------
    -- Attributes
    ------------------------------------------------------
    interface "IAttribute" (function (_ENV)
        doc "IAttribute" [[The IAttribute associates predefined system information or user-defined custom information with a target element.]]

        -- Class Method
        local function IsDefined(target, type)
            local config = _AttributeMap[target]

            if not config then
                return false
            elseif type == IAttribute then
                return true
            elseif getmetatable(config) then
                return getmetatable(config) == type
            else
                for _, attr in ipairs(config) do if getmetatable(attr) == type then return true end end
            end
            return false
        end

        doc "IsNameSpaceAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">the name space</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsNameSpaceAttributeDefined(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            return target and IsDefined(target, cls) or false
        end

        doc "IsClassAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsClassAttributeDefined(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            return Reflector.IsClass(target) and IsDefined(target, cls)
        end

        doc "IsEnumAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">enum</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsEnumAttributeDefined(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            return Reflector.IsEnum(target) and IsDefined(target, cls)
        end

        doc "IsInterfaceAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">interface</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsInterfaceAttributeDefined(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            return Reflector.IsInterface(target) and IsDefined(target, cls)
        end

        doc "IsStructAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">struct</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsStructAttributeDefined(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            return Reflector.IsStruct(target) and IsDefined(target, cls)
        end

        doc "IsEventAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class | interface</param>
            <param name="event">the event's name</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsEventAttributeDefined(cls, target, evt)
            local info = _NSInfo[target]
            evt = info and info.Cache and info.Cache[evt]
            return getmetatable(evt) and IsDefined(evt, cls) or false
        end

        doc "IsMethodAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class | interface | struct</param>
            <param name="method">the method's name</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsMethodAttributeDefined(cls, target, method)
            local info = _NSInfo[target]
            method = info and (info.Cache and info.Cache[method] or info.Method and info.Method[method])
            return type(method) == "function" and IsDefined(method, cls) or false
        end

        doc "IsPropertyAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class | interface</param>
            <param name="property">the property's name</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsPropertyAttributeDefined(cls, target, prop)
            local info = _NSInfo[target]
            prop = info and (info.Cache and info.Cache[prop] or info.Property and info.Property[prop])
            return type(prop) == "table" and getmetatable(prop) == nil and IsDefined(prop, cls) or false
        end

        doc "IsMemberAttributeDefined" [[
            <desc>Check whether the target contains such type attribute</desc>
            <param name="class">the attribute class type</param>
            <param name="target">struct</param>
            <param name="member">the member's name</param>
            <return type="boolean">true if the target contains attribute with the type</return>
        ]]
        function IsMemberAttributeDefined(cls, target, member)
            local info = _NSInfo[target]
            member = info and info.Members and info.Members[member]
            return member and IsDefined(member, cls) or false
        end

        local function GetCustomAttribute(target, type)
            local config = _AttributeMap[target]

            if not config then
                return
            elseif getmetatable(config) then
                return (type == IAttribute or getmetatable(config) == type) and config or nil
            elseif type == IAttribute then
                return unpack(config)
            else
                local cache = CACHE_TABLE()

                for _, attr in ipairs(config) do if getmetatable(attr) == type then tinsert(cache, attr) end end

                local count = #cache

                if count == 0 then
                    CACHE_TABLE(cache)
                    return
                elseif count == 1 then
                    local r1 = cache[1]
                    CACHE_TABLE(cache)
                    return r1
                elseif count == 2 then
                    local r1, r2 = cache[1], cache[2]
                    CACHE_TABLE(cache)
                    return r1, r2
                elseif count == 3 then
                    local r1, r2, r3 = cache[1], cache[2], cache[3]
                    CACHE_TABLE(cache)
                    return r1, r2, r3
                else
                    return unpack(cache)
                end
            end
        end

        doc "GetNameSpaceAttribute" [[
            <desc>Return the attributes of the given type for the NameSpace</desc>
            <param name="class">the attribute class type</param>
            <param name="target">NameSpace</param>
            <return>the attribute objects</return>
        ]]
        function GetNameSpaceAttribute(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            if target then return GetCustomAttribute(target, cls) end
        end

        doc "GetClassAttribute" [[
            <desc>Return the attributes of the given type for the class</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class</param>
            <return>the attribute objects</return>
        ]]
        function GetClassAttribute(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            if target and Reflector.IsClass(target) then return GetCustomAttribute(target, cls) end
        end

        doc "GetEnumAttribute" [[
            <desc>Return the attributes of the given type for the enum</desc>
            <param name="class">the attribute class type</param>
            <param name="target">enum</param>
            <return>the attribute objects</return>
        ]]
        function GetEnumAttribute(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            if target and Reflector.IsEnum(target) then return GetCustomAttribute(target, cls) end
        end

        doc "GetInterfaceAttribute" [[
            <desc>Return the attributes of the given type for the interface</desc>
            <param name="class">the attribute class type</param>
            <param name="target">interface</param>
            <return>the attribute objects</return>
        ]]
        function GetInterfaceAttribute(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            if target and Reflector.IsInterface(target) then return GetCustomAttribute(target, cls) end
        end

        doc "GetStructAttribute" [[
            <desc>Return the attributes of the given type for the struct</desc>
            <param name="class">the attribute class type</param>
            <param name="target">struct</param>
            <return>the attribute objects</return>
        ]]
        function GetStructAttribute(cls, target)
            if type(target) == "string" then target = GetNameSpace(PROTYPE_NAMESPACE, target) end
            if target and Reflector.IsStruct(target) then return GetCustomAttribute(target, cls) end
        end

        doc "GetEventAttribute" [[
            <desc>Return the attributes of the given type for the class|interface's event</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class|interface</param>
            <param name="event">the event's name</param>
            <return>the attribute objects</return>
        ]]
        function GetEventAttribute(cls, target, evt)
            local info = _NSInfo[target]
            evt = info and info.Cache and info.Cache[evt]
            if getmetatable(evt) then return GetCustomAttribute(evt, cls) end
        end

        doc "GetMethodAttribute" [[
            <desc>Return the attributes of the given type for the class|interface's method</desc>
            <format>class, target, method</format>
            <format>class, method</format>
            <param name="class">the attribute class type</param>
            <param name="target">class|interface</param>
            <param name="method">the method's name(with target) or the method itself(without target)</param>
            <return>the attribute objects</return>
        ]]
        function GetMethodAttribute(cls, target, method)
            local info = _NSInfo[target]
            method = info and (info.Cache and info.Cache[method] or info.Method and info.Method[method])
            if type(method) == "function" then return GetCustomAttribute(method, cls) end
        end

        doc "GetPropertyAttribute" [[
            <desc>Return the attributes of the given type for the class|interface's property</desc>
            <param name="class">the attribute class type</param>
            <param name="target">class|interface</param>
            <param name="prop">the property's name</param>
            <return>the attribute objects</return>
        ]]
        function GetPropertyAttribute(cls, target, prop)
            local info = _NSInfo[target]
            prop = info and (info.Cache and info.Cache[prop] or info.Property and info.Property[prop])
            if type(prop) == "table" and getmetatable(prop) == nil then return GetCustomAttribute(prop, cls) end
        end

        doc "GetMemberAttribute" [[
            <desc>Return the attributes of the given type for the struct's field</desc>
            <param name="class">the attribute class type</param>
            <param name="target">struct</param>
            <param name="member">the member's name</param>
            <return>the attribute objects</return>
        ]]
        function GetMemberAttribute(cls, target, member)
            local info = _NSInfo[target]
            member = info and info.Members and info.Members[member]
            if member then return GetCustomAttribute(member, cls) end
        end

        -- Object Method
        doc "ApplyAttribute" [[
            <desc>Apply the attribute to the target, overridable</desc>
            <param name="target">the attribute's target</param>
            <param name="targetType" type="System.AttributeTargets">the target's type</param>
            <param name="owner">the target's owner</param>
            <param name="name">the target's name</param>
            <return>the target, also can be modified</return>
        ]]
        function ApplyAttribute(self, target, targetType, owner, name) end

        doc [[Remove self from the prepared attributes]]
        RemoveSelf = RemoveAttributeToPrepared

        doc [[Creates a copy of the attribute.]]
        function Clone(self)
            -- Defualt behavior
            local cache = CACHE_TABLE()

            for name, prop in pairs(_NSInfo[getmetatable(self)].Cache) do
                if type(prop) == "table" and not getmetatable(prop) and (prop.Get or prop.GetMethod or prop.Field) and (prop.Set or prop.SetMethod or prop.Field) then
                    cache[name] = self[name]
                end
            end

            -- Clone
            local obj = getmetatable(self)(cache)

            CACHE_TABLE(cache)

            return obj
        end

        -- Property
        doc [[The priorty of the attribute]]
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Normal }

        doc [[The sublevel of the priorty]]
        property "SubLevel" { Type = Number, Default = 0}

        -- Initializer
        IAttribute = SendAttributeToPrepared
    end)

    -- Attribute system OnLine
    ATTRIBUTE_INSTALLED = true

    class "__Unique__" (function(_ENV)
        extend "IAttribute"

        doc "__Unique__" [[Mark the class will only create one unique object, and can't be disposed, also the class can't be inherited]]

        function ApplyAttribute(self, target, targetType)
            local info = _NSInfo[target]
            if info and info.Type == TYPE_CLASS then
                info.Modifier = TurnOnFlags(MD_FINAL_FEATURE, info.Modifier)
                info.UniqueObject = true
            end
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __Unique__ then return false end
            local info = _NSInfo[target]
            return info and info.UniqueObject and true or false
        end
    end)

    class "__Flags__" (function(_ENV)
        extend "IAttribute"

        doc "__Flags__" [[Indicates that an enumeration can be treated as a bit field; that is, a set of flags.]]

        function ApplyAttribute(self, target, targetType)
            local info = _NSInfo[target]
            if info and info.Type == TYPE_ENUM then
                info.Modifier = TurnOnFlags(MD_FLAGS_ENUM, info.Modifier)

                local enums = info.Enum

                local cache = {}
                local count = 0
                local firstZero = true

                -- Count and clear
                for k, v in pairs(enums) do
                    if v == 0 and firstZero then
                        -- Only one may keep zero
                        firstZero = false
                    else
                        cache[2^count] = true
                        count = count + 1

                        enums[k] = tonumber(v) or -1
                        if enums[k] == 0 then enums[k] = -1 end
                    end
                end

                info.MaxValue = 2^count - 1

                -- Scan the existed bit values
                for k, v in pairs(enums) do
                    if cache[v] == true then
                        cache[v] = k
                    elseif v ~= 0 then
                        enums[k] = -1
                    end
                end

                -- Apply the bit values
                local index = 0

                for k, v in pairs(enums) do
                    if v == -1 then
                        while cache[2^index] and cache[2^index] ~= true do
                            index = index + 1
                        end

                        if cache[2^index] == true then
                            cache[2^index] = k
                            enums[k] = 2^index

                            index = index + 1
                        else
                            error("There is something wrong")
                        end
                    end
                end
            end
        end

        function IsEnumAttributeDefined(cls, target)
            if cls ~= __Flags__ then return false end
            local info = _NSInfo[target]
            return info and info.Type == TYPE_ENUM and ValidateFlags(MD_FLAGS_ENUM, info.Modifier) or false
        end
    end)

    class "__AttributeUsage__" (function(_ENV)
        extend "IAttribute"

        doc "__AttributeUsage__" [[Specifies the usage of another attribute class.]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "AttributeTarget" [[The attribute target type, default AttributeTargets.All]]
        property "AttributeTarget" { Default = AttributeTargets.All, Type = AttributeTargets }

        doc "Inherited" [[Whether your attribute can be inherited by classes that are derived from the classes to which your attribute is applied.]]
        property "Inherited" { Type = Boolean }

        doc "AllowMultiple" [[whether multiple instances of your attribute can exist on an element. default false]]
        property "AllowMultiple" { Type = Boolean }

        doc "RunOnce" [[Whether the property only apply once, when the Inherited is false, and the RunOnce is true, the attribute will be removed after apply operation]]
        property "RunOnce" { Type = Boolean }

        doc "BeforeDefinition" [[Whether the ApplyAttribute method is running before the feature's definition, only works on class, interface and struct.]]
        property "BeforeDefinition" { Type = Boolean }

        doc "" [[Whether the attribute can be override, default false.]]
        property "Overridable" { Type = Boolean }
    end)

    class "__Sealed__" (function(_ENV)
        extend "IAttribute"

        doc "__Sealed__" [[Mark the feature to be sealed, and can't be re-defined again]]

        function ApplyAttribute(self, target, targetType)
            _NSInfo[target].Modifier = TurnOnFlags(MD_SEALED_FEATURE, _NSInfo[target].Modifier)
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __Sealed__ then return false end
            local info = _NSInfo[target]
            return info and ValidateFlags(MD_SEALED_FEATURE, info.Modifier) or false
        end

        IsEnumAttributeDefined = IsClassAttributeDefined
        IsInterfaceAttributeDefined = IsClassAttributeDefined
        IsStructAttributeDefined = IsClassAttributeDefined
    end)

    class "__Final__" (function(_ENV)
        extend "IAttribute"

        doc "__Final__" [[Mark the class|interface can't be inherited, or method|property can't be overwrited by child-classes]]

        function ApplyAttribute(self, target, targetType, owner, name)
            local info = _NSInfo[owner or target]
            if targetType == AttributeTargets.Interface or targetType == AttributeTargets.Class then
                info.Modifier = TurnOnFlags(MD_FINAL_FEATURE, info.Modifier)
            elseif _NSInfo[owner].Type == TYPE_INTERFACE or _NSInfo[owner].Type == TYPE_CLASS then
                info.FeatureModifier = info.FeatureModifier or {}
                info.FeatureModifier[name] = TurnOnFlags(MD_FINAL_FEATURE, info.FeatureModifier[name])
            end
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __Final__ then return false end
            return IsFinalFeature(target)
        end

        IsInterfaceAttributeDefined = IsClassAttributeDefined

        function IsPropertyAttributeDefined(cls, target, name)
            if cls ~= __Final__ then return false end
            return IsFinalFeature(target, name)
        end

        IsMethodAttributeDefined = IsPropertyAttributeDefined
    end)

    -- Apply Attribute to the previous definitions
    do
        -- System.IAttribute
        __Sealed__:ApplyAttribute(IAttribute)

        -- System.AttributeTargets
        __Flags__:ApplyAttribute(AttributeTargets)
        __Sealed__:ApplyAttribute(AttributeTargets)

        -- System.__Unique__
        __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
        ConsumePreparedAttributes(__Unique__, AttributeTargets.Class)
        __Unique__:ApplyAttribute(__Unique__)
        __Sealed__:ApplyAttribute(__Unique__)

        -- System.__Flags__
        __AttributeUsage__{AttributeTarget = AttributeTargets.Enum, RunOnce = true}
        ConsumePreparedAttributes(__Flags__, AttributeTargets.Class)
        __Unique__:ApplyAttribute(__Flags__)
        __Sealed__:ApplyAttribute(__Flags__)

        -- System.__AttributeUsage__
        __AttributeUsage__{AttributeTarget = AttributeTargets.Class}
        ConsumePreparedAttributes(__AttributeUsage__, AttributeTargets.Class)
        __Sealed__:ApplyAttribute(__AttributeUsage__)
        __Final__:ApplyAttribute(__AttributeUsage__, AttributeTargets.Class)

        -- System.__Sealed__
        __AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct + AttributeTargets.Enum, RunOnce = true}
        ConsumePreparedAttributes(__Sealed__, AttributeTargets.Class)
        __Unique__:ApplyAttribute(__Sealed__)
        __Sealed__:ApplyAttribute(__Sealed__)

        -- System.__Final__
        __AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Method + AttributeTargets.Property, RunOnce = true, BeforeDefinition = true}
        ConsumePreparedAttributes(__Final__, AttributeTargets.Class)
        __Unique__:ApplyAttribute(__Final__)
        __Sealed__:ApplyAttribute(__Final__)
    end

    __AttributeUsage__{AttributeTarget = AttributeTargets.Property + AttributeTargets.Method, RunOnce = true }
    __Sealed__() __Unique__()
    class "__Static__" (function(_ENV)
        extend "IAttribute"
        doc "__Static__" [[Used to mark the features as static.]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            if targetType == AttributeTargets.Property then
                target.IsStatic = true
            elseif targetType == AttributeTargets.Method then
                local info = _NSInfo[owner]

                info.FeatureModifier = info.FeatureModifier or {}
                info.FeatureModifier[name] = TurnOnFlags(MD_STATIC_FEATURE, info.FeatureModifier[name])
            end
        end

        function IsPropertyAttributeDefined(cls, target, name)
            if cls ~= __Static__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            return type(info) == "table" and getmetatable(info) == nil and info.IsStatic or false
        end

        function IsMethodAttributeDefined(cls, target, name)
            if cls ~= __Static__ then return false end
            local info = _NSInfo[target]
            return info and info.FeatureModifier and ValidateFlags(MD_STATIC_FEATURE, info.FeatureModifier[name]) or false
        end
    end)

    __Sealed__()
    struct "Argument" (function(_ENV)
        Type = AnyType
        Nilable = Boolean
        Default = Any
        Name = String
        IsList = Boolean

        function __init(value)
            if value.Type and value.Default ~= nil then
                value.Default = GetValidatedValue(value.Type, value.Default)
            end

            -- Auto generate Default
            if value.Default == nil and value.Type and value.Nilable then
                local info = _NSInfo[value.Type]
                if info and (info.Type == TYPE_STRUCT or info.Type == TYPE_ENUM) then value.Default = info.Default end
            end
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Method + AttributeTargets.Constructor, RunOnce = true }
    __Sealed__()
    class "__Arguments__" (function(_ENV)
        extend "IAttribute"

        doc "__Arguments__" [[The overload argument definitions for the target method or constructor]]

        _Error_Header = [[Usage : __Arguments__{ arg1[, arg2[, ...] ] } : ]]
        _Error_NotArgument = [[arg%d must be System.Argument]]
        _Error_NotOptional = [[arg%d must also be optional]]
        _Error_NotList = [[arg%d can't be a list]]

        _OverLoad = setmetatable({}, WEAK_KEY)

        -- One args cache for one thread
        _ThreadArgs = setmetatable({}, {
            __mode = "k",
            __call = function(self)
                local thread = running() or 0
                local args = self[thread] or setmetatable({}, WEAK_VALUE)
                wipe(args)
                self[thread] = args
                return args
            end,
        })

        local function serializeData(data)
            local dtype = type(data)
            if dtype == "string" then
                return strformat("%q", data)
            elseif dtype == "number" or dtype == "boolean" then
                return tostring(data)
            elseif dtype == "table" and not rawget(_NSInfo, data) then
                local cache = CACHE_TABLE()

                tinsert(cache, "{")

                for k, v in pairs(data) do
                    dtype = type(k)
                    if dtype == "number" or dtype == "string" then
                        local vs = serializeData(v)

                        if vs then
                            if dtype == "number" then
                                tinsert(cache, strformat("[%s] = %s,", tostring(k), vs))
                            else
                                tinsert(cache, strformat("%s = %s,", k, vs))
                            end
                        end
                    end
                end

                tinsert(cache, "}")

                local ret = tblconcat(cache, " ")

                CACHE_TABLE(cache)

                return ret
            elseif rawget(_NSInfo, data) then
                return tostring(data)
            else
                -- Don't support any point values
                return nil
            end
        end

        local function serialize(data, ns)
            local info = _NSInfo[ns]
            if info then
                ns = info.Owner
                local dtype = type(data)

                if info.Type == TYPE_ENUM then
                    if info.MaxValue and dtype == "number" then
                        local ret = { ns(data) }

                        local result = ""

                        for i, str in ipairs(ret) do
                            if i > 1 then result = result .. " + " end
                            result = result .. (tostring(ns) .. "." .. str)
                        end

                        return result
                    else
                        local str = ns(data)

                        return str and (tostring(ns) .. "." .. str)
                    end
                elseif info.Type == TYPE_CLASS then
                    -- Class handle the serialize itself with __tostring
                    return tostring(data)
                elseif info.Type == TYPE_STRUCT then
                    if info.SubType == STRUCT_TYPE_MEMBER and dtype == "table" then
                        if not info.Members or #info.Members == 0 then
                            return tostring(ns) .. "( )"
                        else
                            local ret = tostring(ns) .. "( "

                            for i, m in ipairs(info.Members) do
                                local value = serializeData(data[m.Name], m.Type)

                                if i == 1 then
                                    ret = ret .. tostring(value)
                                else
                                    ret = ret .. ", " .. tostring(value)
                                end
                            end

                            ret = ret .. " )"

                            return ret
                        end
                    elseif info.SubType == STRUCT_TYPE_ARRAY and dtype == "table" then
                        local ret = tostring(ns) .. "( "

                        local sty = info.ArrayElement

                        for i, v in ipairs(data) do
                            v = serialize(v, sty)

                            if i == 1 then
                                ret = ret .. tostring(v)
                            else
                                ret = ret .. ", " .. tostring(v)
                            end
                        end

                        ret = ret .. " )"

                        return ret
                    elseif dtype == "table" and type(data.__tostring) == "function" then
                        return data:__tostring()
                    else
                        return serializeData(data)
                    end
                end
            else
                -- Serialize normal datas
                return serializeData(data)
            end
        end

        local function validateArgument(self, i)
            local ok, arg = pcall(Argument, self[i])
            if not ok then error(_Error_Header .. _Error_NotArgument:format(i)) end

            self[i] = arg

            -- Check ... args
            if arg.IsList then
                if i == #self then
                    if self.MinArgs then
                        error(_Error_Header .. _Error_NotList:format(i))
                    else
                        if arg.Nilable then
                            self.MinArgs = i - 1
                        else
                            -- Must have one parameter at least
                            self.MinArgs = i
                        end

                        -- Just big enough
                        self.MaxArgs = 9999

                        arg.Name = "..."
                    end
                    self.IsList = true
                else
                    error(_Error_Header .. _Error_NotList:format(i))
                end
            elseif arg.Nilable then
                if not self.MinArgs then self.MinArgs = i - 1 end
            elseif self.MinArgs then
                -- Only optional args can be defined after optional args
                error(_Error_Header .. _Error_NotOptional:format(i))
            end
        end

        local function buildUsage(overLoads, info)
            if info.Usage then return info.Usage end

            -- Check if this is a static method
            if overLoads.HasSelf == nil then
                overLoads.HasSelf = true
                if overLoads.TargetType == AttributeTargets.Method then
                    if Reflector.IsInterface(overLoads.Owner) and IsFinalFeature(overLoads.Owner) then overLoads.HasSelf = false end
                    if overLoads.Name == "__exist" or overLoads.Name == "__new" or __Static__:IsMethodAttributeDefined(overLoads.Owner, overLoads.Name) then overLoads.HasSelf = false end
                end
            end

            -- Generate usage message
            local usage = CACHE_TABLE()
            local name = overLoads.Name
            local owner = overLoads.Owner

            if overLoads.TargetType == AttributeTargets.Method then
                if not overLoads.HasSelf then
                    tinsert(usage, "Usage : " .. tostring(owner) .. "." .. name .. "( ")
                else
                    if overLoads.IsMeta and name:match("^___") then name = name:sub(2, -1) end
                    tinsert(usage, "Usage : " .. tostring(owner) .. ":" .. name .. "( ")
                end
            else
                tinsert(usage, "Usage : " .. tostring(owner) .. "( ")
            end

            for i = 1, #info do
                local arg = info[i]
                local str = ""

                if i > 1 then tinsert(usage, ", ") end

                -- [name As type = default]
                if arg.Name then
                    str = str .. arg.Name

                    if arg.Type then str = str .. " As " end
                end

                if arg.Type then str = str .. tostring(arg.Type) end

                if arg.Default ~= nil and i > info.MinArgs then
                    local default = serialize(arg.Default, arg.Type)

                    if default then str = str .. " = " .. default end
                end

                if arg.Nilable then str = "[" .. str .. "]" end

                tinsert(usage, str)
            end

            tinsert(usage, " )")

            info.Usage = tblconcat(usage, "")

            CACHE_TABLE(usage)

            return info.Usage
        end

        local function getSuperOverLoad(overLoads)
            if overLoads.TargetType == AttributeTargets.Constructor then
                -- Check super class's constructor
                local info = _NSInfo[_NSInfo[overLoads.Owner].SuperClass]

                while info and not info.Constructor do info = _NSInfo[info.SuperClass] end

                if info then
                    local func = info.Constructor
                    return _OverLoad[func] or func
                end
            elseif overLoads.IsMeta then
                -- Check super class's constructor
                local info = _NSInfo[_NSInfo[overLoads.Owner].SuperClass]
                if info then
                    local func = info.MetaTable[overLoads.Name]
                    return _OverLoad[func] or func
                end
            else
                local info = _NSInfo[overLoads.Owner]
                local name = overLoads.Name
                local func

                -- Check super class first
                if info.SuperClass then
                    func = _NSInfo[info.SuperClass].Cache[name]

                    if type(func) == "function" then return _OverLoad[func] or func end
                end

                -- Check extended interface
                if info.ExtendInterface then
                    for _, IF in ipairs(info.ExtendInterface) do
                        func = _NSInfo[IF].Cache[name]

                        if type(func) == "function" then return _OverLoad[func] or func end
                    end
                end
            end
        end

        local function getUsage(method, index)
            local overLoads = _OverLoad[method]

            if overLoads then
                index = (index or 0) + 1

                local info = overLoads[index]

                if info then return index, buildUsage(overLoads, info) end
            end
        end

        local function raiseError(overLoads)
            -- Check if this is a static method
            if overLoads.HasSelf == nil then
                overLoads.HasSelf = true
                if overLoads.TargetType == AttributeTargets.Method then
                    if Reflector.IsInterface(overLoads.Owner) and IsFinalFeature(overLoads.Owner) then overLoads.HasSelf = false end
                    if overLoads.Name == "__exist" or overLoads.Name == "__new" or __Static__:IsMethodAttributeDefined(overLoads.Owner, overLoads.Name) then overLoads.HasSelf = false end
                end
            end

            -- Generate the usage list
            local usage = CACHE_TABLE()

            local index = 1
            local info = overLoads[index]

            while info do
                local fUsage = buildUsage(overLoads, info)
                local params = fUsage:match("Usage : %w+.(.+)")

                if params and not usage[params] then
                    usage[params] = true
                    tinsert(usage, fUsage)
                end

                index = index + 1
                info = overLoads[index]

                if not info then
                    overLoads = getSuperOverLoad(overLoads)

                    if type(overLoads) == "table" then
                        index = 1
                        info = overLoads[index]
                    end
                end
            end

            local msg = tblconcat(usage, "\n")
            CACHE_TABLE(usage)

            error(msg, 4)
        end

        local function callOverLoadMethod( overLoads, ... )
            if overLoads.HasSelf == nil then
                overLoads.HasSelf = true
                if overLoads.TargetType == AttributeTargets.Method then
                    if Reflector.IsInterface(overLoads.Owner) and IsFinalFeature(overLoads.Owner) then overLoads.HasSelf = false end
                    if overLoads.Name == "__exist" or overLoads.Name == "__new" or __Static__:IsMethodAttributeDefined(overLoads.Owner, overLoads.Name) then overLoads.HasSelf = false end
                end
            end

            local base = overLoads.HasSelf and 1 or 0
            local object = overLoads.HasSelf and ... or nil
            local count = select('#', ...) - base

            local cache = _ThreadArgs()

            -- Cache first
            if count > 0 then
                if count == 1 then
                    cache[1] = select(1 + base, ...)
                elseif count == 2 then
                    cache[1], cache[2] = select(1 + base, ...)
                elseif count == 3 then
                    cache[1], cache[2], cache[3] = select(1 + base, ...)
                elseif count == 4 then
                    cache[1], cache[2], cache[3], cache[4] = select(1 + base, ...)
                else
                    for i = 1, count do cache[i] = select(i + base, ...) end
                end
            end

            local coverLoads = overLoads
            local index = 1
            local info = coverLoads[index]
            local zeroMethod

            while info do
                local argsCount = #info
                local matched = true
                local maxCnt = count

                if argsCount == 0 and not zeroMethod then
                    if count == 0 then return info.Method( ... ) end
                    zeroMethod = info
                end

                -- Check argument settings
                if count >= info.MinArgs and count <= info.MaxArgs then
                    -- Required
                    for i = 1, info.MinArgs do
                        local atype = info[i].Type
                        local value = cache[i]

                        -- Required argument can't be nil, Validate the value
                        if value == nil or (atype and GetValidatedValue(atype, value, true) == nil) then matched = false break end
                    end

                    -- Optional
                    if matched then
                        for i = info.MinArgs + 1, count >= argsCount and count or argsCount do
                            local atype = (info[i] or info[argsCount]).Type
                            local value = cache[i]

                            if value ~= nil and atype and GetValidatedValue(atype, value, true) == nil then matched = false break end
                        end
                    end

                    if matched then
                        -- Need update the arguments with settings.
                        -- Required
                        for i = 1, info.MinArgs do
                            cache[i] = GetValidatedValue(info[i].Type, cache[i])
                        end

                        -- Optional
                        if matched then
                            if info.IsList then
                                local arg = info[argsCount]
                                for i = info.MinArgs + 1, count do
                                    local value = cache[i]

                                    if value == nil then
                                        -- No check
                                        if arg.Default ~= nil then value = CloneObj(arg.Default, true) end
                                    elseif arg.Type then
                                        -- Validate the value
                                        value = GetValidatedValue(arg.Type, value)
                                    end

                                    cache[i] = value
                                end
                            else
                                for i = info.MinArgs + 1, argsCount do
                                    local arg = info[i]
                                    local value = cache[i]

                                    if value == nil then
                                        -- No check
                                        if arg.Default ~= nil then value = CloneObj(arg.Default, true) end
                                    elseif arg.Type then
                                        -- Validate the value
                                        value = GetValidatedValue(arg.Type, value)
                                    end

                                    cache[i] = value

                                    if i > maxCnt then maxCnt = i end
                                end
                            end
                        end

                        if base == 1 then
                            if maxCnt == 0 then
                                return info.Method( object )
                            elseif maxCnt == 1 then
                                return info.Method( object, cache[1] )
                            elseif maxCnt == 2 then
                                return info.Method( object, cache[1], cache[2] )
                            elseif maxCnt == 3 then
                                return info.Method( object, cache[1], cache[2], cache[3] )
                            --elseif maxCnt == 4 then
                            --    return info.Method( object, cache[1], cache[2], cache[3], cache[4] )
                            else
                                return info.Method( object, unpack(cache, 1, maxCnt) )
                            end
                        else
                            if maxCnt == 0 then
                                return info.Method()
                            elseif maxCnt == 1 then
                                return info.Method( cache[1] )
                            elseif maxCnt == 2 then
                                return info.Method( cache[1], cache[2] )
                            elseif maxCnt == 3 then
                                return info.Method( cache[1], cache[2], cache[3] )
                            --elseif maxCnt == 4 then
                            --    return info.Method( cache[1], cache[2], cache[3], cache[4] )
                            else
                                return info.Method( unpack(cache, 1, maxCnt) )
                            end
                        end
                    end
                end

                index = index + 1
                info = coverLoads[index]

                if not info then
                    coverLoads = getSuperOverLoad(coverLoads)

                    if type(coverLoads) == "function" then
                        return coverLoads( ... )
                    elseif coverLoads then
                        index = 1
                        info = coverLoads[index]
                    end
                end
            end

            if zeroMethod and count == 1 and overLoads.TargetType == AttributeTargets.Constructor then
                -- Check if the first arg is a init-table
                local data = cache[1]

                if type(data) == "table" and getmetatable(data) == nil then
                    zeroMethod.Method( object )

                    for k, v in pairs(data) do object[k] = v end

                    return
                end
            end

            -- No match
            raiseError(overLoads)
        end

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            local isMeta = false

            -- Self validation once
            for i = 1, #self do validateArgument(self, i) end

            if targetType == AttributeTargets.Constructor then
                name = Reflector.GetNameSpaceName(owner)
            elseif _KeyMeta[name] then
                -- Meta-methods
                isMeta = true
            end

            if not self.MinArgs then self.MinArgs = #self end
            if not self.MaxArgs then self.MaxArgs = #self end
            if not self.Method then self.Method = target end

            _OverLoad[owner] = _OverLoad[owner] or {}
            _OverLoad[owner][name] = _OverLoad[owner][name] or {
                TargetType = targetType,
                Owner = owner,
                Name = name,
            }

            local overLoads = _OverLoad[owner][name]
            if not overLoads[0] then
                overLoads[0] = function(...) return callOverLoadMethod(overLoads, ...) end
                if isMeta then overLoads.IsMeta = true end

                -- For quick access
                _OverLoad[ overLoads[0] ] = overLoads
            end

            -- Insert or replace
            for _, info in ipairs(overLoads) do
                if #self == #info and self.MinArgs == info.MinArgs then
                    local isEqual = true

                    for i = 1, #self do
                        if not IsEqual(self[i], info[i]) then
                            isEqual = false
                            break
                        end
                    end

                    if isEqual then
                        info.Method = self.Method
                        return overLoads[0]
                    end
                end
            end

            local overLoadInfo = {}
            for k, v in pairs(self) do overLoadInfo[k] = v end

            tinsert(overLoads, overLoadInfo)

            return overLoads[0]
        end

        doc "GetOverloadUsage" [[Return the usage of the target method]]
        __Static__() function GetOverloadUsage(ns, name)
            if type(ns) == "function" then return getUsage, ns end
            local info = _NSInfo[ns]
            if info and (info.Cache or info.Method) then
                local tar = info.Cache[name] or info.Method[name]
                if type(tar) == "function" then return getUsage, tar end
            end
        end

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        property "Priorty" { Type = AttributePriorty, Default = AttributePriorty.Lower }
        property "SubLevel" { Type = Number, Default = -9999}
    end)

    -- More usable attributes
    __AttributeUsage__{AttributeTarget = AttributeTargets.Event + AttributeTargets.Method + AttributeTargets.ObjectMethod, AllowMultiple = true, RunOnce = true}
    __Sealed__()
    class "__Delegate__" (function(_ENV)
        extend "IAttribute"
        doc "__Delegate__" [[Wrap the method/event call in a delegate function]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Delegate" [[The delegate function]]
        property "Delegate" { Type = Function }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            local delegate = self.Delegate
            if not delegate then return end

            if targetType == AttributeTargets.Method or targetType == AttributeTargets.ObjectMethod then
                if type(target) == "function" then
                    -- Wrap the target method
                    return function (...) return delegate(target, ...) end
                end
            elseif targetType == AttributeTargets.Event then
                _NSInfo[owner].Event[name].Delegate = delegate
            end

            self.Delegate = nil
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Delegate__(self)
            self.Delegate = nil
        end

        __Arguments__{ Function }
        function __Delegate__(self, value)
            self.Delegate = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
    __Sealed__() __Unique__()
    class "__AutoCache__" (function(_ENV)
        extend "IAttribute"
        doc "__AutoCache__" [[Mark the class so its objects will cache any methods they accessed, mark the method so the objects will cache the method when they are created, if using on an interface, all object methods defined in it would be marked with __AutoCache__ attribute .]]

        function ApplyAttribute(self, target, targetType, owner, name)
            _NSInfo[target].AutoCache = true
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __AutoCache__ then return false end
            local info = _NSInfo[target]
            return info and info.AutoCache or false
        end
    end)

    __Sealed__()
    enum "StructType" {
        "MEMBER",
        "ARRAY",
        "CUSTOM"
    }

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
    __Sealed__() __Unique__()
    class "__Abstract__" (function(_ENV)
        extend "IAttribute"
        doc "__Abstract__" [[Mark the class as abstract class, can't be used to create objects.]]

        function ApplyAttribute(self, target, targetType)
            _NSInfo[target].Modifier = TurnOnFlags(MD_ABSTRACT_CLASS, _NSInfo[target].Modifier)
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __Abstract__ then return false end
            local info = _NSInfo[target]
            return info and ValidateFlags(MD_ABSTRACT_CLASS, info.Modifier) or false
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
    __Sealed__() __Unique__()
    class "__InitTable__" (function(_ENV)
        extend "IAttribute"

        doc "__InitTable__" [[Used to mark the class can use init table like: obj = cls(name) { Age = 123 }]]

        __Arguments__{ RawTable }
        function InitWithTable(self, initTable)
            for name, value in pairs(initTable) do self[name] = value end

            return self
        end

        function ApplyAttribute(self, target, targetType)
            if _NSInfo[target] and _NSInfo[target].Type == TYPE_CLASS then
                return SaveMethod(_NSInfo[target], "__call", __InitTable__["InitWithTable"])
            end
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Interface + AttributeTargets.Method + AttributeTargets.Property + AttributeTargets.Member, RunOnce = true}
    __Sealed__()
    class "__Require__" (function(_ENV)
        extend "IAttribute"

        doc "__Require__" [[Whether the method or property is required to be override, or a member of a struct is required, or set the required class|interface for an interface.]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            if targetType == AttributeTargets.Interface then
                if self.Require then return SaveRequire(info, self.Require) end
            else
                local info = _NSInfo[owner]

                if info and type(name) == "string" then
                    if targetType == AttributeTargets.Member then
                        target.Require = true
                    else
                        info.FeatureModifier = info.FeatureModifier or {}
                        info.FeatureModifier[name] = TurnOnFlags(MD_REQUIRE_FEATURE, info.FeatureModifier[name])
                    end
                end
            end
        end

        function IsInterfaceAttributeDefined(cls, target)
            if cls ~= __Require__ then return false end
            local info = _NSInfo[target]
            return info and info.RequireClass and true or false
        end

        function GetInterfaceAttribute(cls, target)
            if cls ~= __Require__ then return false end
            local info = _NSInfo[target]
            return info and info.RequireClass
        end

        function IsMethodAttributeDefined(cls, target, name)
            if cls ~= __Require__ then return false end
            local info = _NSInfo[target]
            return info and info.FeatureModifier and ValidateFlags(MD_REQUIRE_FEATURE, info.FeatureModifier[name]) or false
        end

        IsPropertyAttributeDefined = IsMethodAttributeDefined

        function IsMemberAttributeDefined(cls, target, name)
            if cls ~= __Require__ then return false end
            local info = _NSInfo[target]
            info = info and info.Members and info.Members[name]
            return info and info.Require or false
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Require__(self)
            self.Require = nil
        end

        __Arguments__{ Class }
        function __Require__(self, value)
            local IFInfo = rawget(_NSInfo, value)
            if ValidateFlags(MD_FINAL_FEATURE, IFInfo.Modifier) then
                error(("%s is marked as final, can't be used with __Require__ ."):format(tostring(value)), 3)
            end
            self.Require = value
        end

        __Arguments__{ String }
        function __Require__(self, value)
            value = GetNameSpace(PROTYPE_NAMESPACE, value)

            local IFInfo = rawget(_NSInfo, value)

            if not IFInfo or IFInfo.Type ~= TYPE_CLASS then
                error("Usage: __Require__ (class) : class expected", 3)
            elseif ValidateFlags(MD_FINAL_FEATURE, IFInfo.Modifier) then
                error(("%s is marked as final, can't be used with __Require__ ."):format(tostring(value)), 3)
            end

            self.Require = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
    __Sealed__()
    class "__Synthesize__" (function(_ENV)
        extend "IAttribute"

        doc "__Synthesize__" [[Used to generate property accessors automatically]]

        enum "NameCases" {
            "Camel",    -- setName
            "Pascal",   -- SetName
        }

        ------------------------------------------------------
        -- Static Property
        ------------------------------------------------------
        doc "NameCase" [[The name case of the generate method, in one program, only need to be set once, default is Pascal case]]
        property "NameCase" { Type = NameCases, Default = NameCases.Pascal, IsStatic = true }

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Get" [[The get method name]]
        property "Get" { Type = String }

        doc "Set" [[The set method name]]
        property "Set" { Type = String }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            target.Synthesize = __Synthesize__.NameCase
            target.SynthesizeGet = self.Get
            target.SynthesizeSet = self.Set
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__ {}
        function __Synthesize__(self)
            self.Get = nil
            self.Set = nil
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
    __Sealed__()
    class "__Event__" (function(_ENV)
        extend "IAttribute"

        doc "__Event__" [[Used to bind an event to the property]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Event" [[The event that bind to the property]]
        property "Event" { Type = String }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            target.Event = self.Event
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Event__(self)
            self.Event = nil
        end

        __Arguments__{ Event }
        function __Event__(self, value)
            self.Event = value
        end

        __Arguments__{ String }
        function __Event__(self, value)
            self.Event = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
    __Sealed__()
    class "__Handler__" (function(_ENV)
        extend "IAttribute"

        doc "__Handler__" [[Used to bind an handler(method name or function) to the property]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Handler" [[The handler that bind to the property]]
        property "Handler" { Type = Function + String }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            target.Handler = self.Handler
            self.Handler = nil
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Handler__(self)
            self.Handler = nil
        end

        __Arguments__{ Function + String }
        function __Handler__(self, value)
            self.Handler = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Struct + AttributeTargets.Enum + AttributeTargets.Property + AttributeTargets.Member, RunOnce = true}
    __Sealed__()
    class "__Default__" (function(_ENV)
        extend "IAttribute"

        doc "__Default__" [[Used to set a default value for features like custom struct, enum, struct member, property]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Default" [[The default value]]
        property "Default" { Type = Any }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            if self.Default == nil then return end

            if targetType == AttributeTargets.Property or targetType == AttributeTargets.Member then
                target.Default = self.Default
            else
                _NSInfo[target].Default = self.Default
            end
        end

        function IsStructAttributeDefined(cls, target)
            if cls ~= __Default__ then return false end
            local info = _NSInfo[target]
            return info and info.Default ~= nil
        end

        function GetStructAttribute(cls, target)
            if cls ~= __Default__ then return false end
            local info = _NSInfo[target]
            return info and CloneObj(info.Default, true)
        end

        IsEnumAttributeDefined = IsStructAttributeDefined
        GetEnumAttribute = GetStructAttribute

        function IsPropertyAttributeDefined(cls, target, name)
            if cls ~= __Default__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            return info and type(info) == "table" and getmetatable(table) == nil and info.Default ~= nil
        end

        function GetPropertyAttribute(cls, target, name)
            if cls ~= __Default__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            return info and type(info) == "table" and getmetatable(table) == nil and CloneObj(info.Default, true) or nil
        end

        function IsMemberAttributeDefined(cls, target, name)
            if cls ~= __Require__ then return false end
            local info = _NSInfo[target]
            info = info and info.Members and info.Members[name]
            return info and info.Default ~= nil
        end

        function GetMemberAttribute(cls, target, name)
            if cls ~= __Require__ then return false end
            local info = _NSInfo[target]
            info = info and info.Members and info.Members[name]
            return info and CloneObj(info.Default, true)
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Default__(self)
            self.Default = nil
        end

        __Arguments__{ Any }
        function __Default__(self, value)
            self.Default = value
        end
    end)

    __Flags__() __Default__( "Assign" )
    enum "Setter" {
        Assign = 0, -- set directly
        "Clone",    -- Clone struct or object of ICloneable
        "DeepClone",-- Deep clone struct
        "Retain",   -- Dispose old object
        -- "Strong", this is default for lua
        "Weak",     -- Weak value
    }

    __Flags__() __Default__( "Origin" )
    enum "Getter" {
        Origin = 0,
        "Clone",
        "DeepClone",
    }

    __AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
    __Sealed__()
    class "__Setter__" (function(_ENV)
        extend "IAttribute"

        doc "__Setter__" [[Used to set the assign mode of the property]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Setter" [[The setter settings]]
        property "Setter" { Type = Setter }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            target.Setter = self.Setter
        end

        function IsPropertyAttributeDefined(cls, target, name)
            if cls ~= __Setter__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            return type(info) == "table" and getmetatable(info) == nil and (info.SetClone or info.SetRetain or info.SetWeak) or false
        end

        function GetPropertyAttribute(cls, target, name)
            if cls ~= __Setter__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            if type(info) == "table" and getmetatable(info) == nil then
                local setter = Setter.Assign
                if info.SetClone then setter = setter + Setter.Clone end
                if info.SetDeepClone then setter = setter + Setter.DeepClone end
                if info.SetRetain then setter = setter + Setter.Retain end
                if info.SetWeak then setter = setter + Setter.Weak end
                return setter
            end
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Setter__(self)
            self.Setter = nil
        end

        __Arguments__{ Setter }
        function __Setter__(self, value)
            self.Setter = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Property, RunOnce = true}
    __Sealed__()
    class "__Getter__" (function(_ENV)
        extend "IAttribute"

        doc "__Getter__" [[Used to set the get mode of the property]]

        ------------------------------------------------------
        doc "Getter" [[The getter settings]]
        property "Getter" { Type = Getter }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            target.Getter = self.Getter
        end

        function IsPropertyAttributeDefined(cls, target, name)
            if cls ~= __Setter__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            return type(info) == "table" and getmetatable(info) == nil and info.GetClone or false
        end

        function GetPropertyAttribute(cls, target, name)
            if cls ~= __Setter__ then return false end
            local info = _NSInfo[target]
            info = info and info.Cache and info.Cache[name]
            if type(info) == "table" and getmetatable(info) == nil then
                local getter = Getter.Origin
                if info.GetClone then getter = getter + Getter.Clone end
                if info.GetDeepClone then getter = getter + Getter.DeepClone end
                return getter
            end
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Getter__(self)
            self.Getter = nil
        end

        __Arguments__{ Getter }
        function __Getter__(self, value)
            self.Getter = value
        end
    end)

    __AttributeUsage__{RunOnce = true, BeforeDefinition = true}
    __Sealed__()
    class "__Doc__" (function(_ENV)
        extend "IAttribute"

        doc "__Doc__" [[Used to document the features like : class, struct, enum, interface, property, event and method]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            if type(self.Doc) == "string" and targetType and (owner or target) then
                SaveDocument(self.Doc, name, targetType, owner or target)
            end
            self.Doc = nil
        end

        function IsNameSpaceAttributeDefined(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.NameSpace) and true or false
        end

        function GetNameSpaceAttribute(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.NameSpace)
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Class) and true or false
        end

        function GetClassAttribute(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Class)
        end

        function IsInterfaceAttributeDefined(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Interface) and true or false
        end

        function GetInterfaceAttribute(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Interface)
        end

        function IsStructAttributeDefined(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Struct) and true or false
        end

        function GetStructAttribute(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Struct)
        end

        function IsEnumAttributeDefined(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Enum) and true or false
        end

        function GetEnumAttribute(cls, target)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Enum)
        end

        function IsEventAttributeDefined(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Event) and true or false
        end

        function GetEventAttribute(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Event)
        end

        function IsPropertyAttributeDefined(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Property) and true or false
        end

        function GetPropertyAttribute(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Property)
        end

        function IsMethodAttributeDefined(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Method) and true or false
        end

        function GetMethodAttribute(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Method)
        end

        function IsMemberAttributeDefined(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Member) and true or false
        end

        function GetMemberAttribute(cls, target, name)
            if cls ~= __Doc__ then return false end
            return GetDocument(target, nil, AttributeTargets.Member)
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        function __Doc__(self, data)
            self.Doc = data
        end

        ------------------------------------------------------
        -- Meta-method
        ------------------------------------------------------
        doc "__call" [[__Doc__ "Target" "Document"]]
        function __call(self, data)
            self:RemoveSelf()

            local owner = getfenv(2)[OWNER_FIELD]

            if type(self.Doc) == "string" and owner and IsNameSpace(owner) then SaveDocument(data, self.Doc, nil, owner) end

            self.Doc = nil
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface + AttributeTargets.Struct + AttributeTargets.Enum, RunOnce = true, BeforeDefinition = true}
    __Sealed__() __Unique__()
    class "__NameSpace__" (function(_ENV)
        extend "IAttribute"
        doc "__NameSpace__" [[Used to set the namespace directly.]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self) return PrepareNameSpace(nil) end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        function __NameSpace__(self, ns)
            if IsNameSpace(ns) then
                PrepareNameSpace(ns)
            elseif type(ns) == "string" then
                PrepareNameSpace(BuildNameSpace(PROTYPE_NAMESPACE, ns))
            elseif ns == nil or ns == false then
                PrepareNameSpace(false)
            else
                error([[Usage: __NameSpace__(name|nil|false)]], 2)
            end
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
    __Sealed__() __Unique__()
    class "__SimpleClass__" (function(_ENV)
        extend "IAttribute"
        doc "__SimpleClass__" [[
            Mark the class as a simple class, if the class is a real simple class, the init-table would be converted as the object.
            If the class is not a simple class, the system would check the init-table's key-value pairs:
                i.   The table don't have key equals the class's property name.
                ii.  The table don't have key equals the class's event name.
                iii. The table don't have key equals the class's method name, or the value is a function.
            If the init-table follow the three rules, it would be converted as the class's object directly.
        ]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target) _NSInfo[target].AsSimpleClass = true end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __SimpleClass__ then return false end
            local info = _NSInfo[target]
            return info and info.AsSimpleClass
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class + AttributeTargets.Interface, RunOnce = true, BeforeDefinition = true}
    __Sealed__() __Unique__()
    class "__AutoProperty__" (function(_ENV)
        extend "IAttribute"
        doc "__AutoProperty__" [[Mark the class|interface to bind property with method automatically.]]

        function ApplyAttribute(self, target, targetType)
            _NSInfo[target].Modifier = TurnOnFlags(MD_AUTO_PROPERTY, _NSInfo[target].Modifier)
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __AutoProperty__ then return false end
            local info = _NSInfo[target]
            return info and ValidateFlags(MD_AUTO_PROPERTY, info.Modifier) or false
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Struct, RunOnce = true, BeforeDefinition = true}
    __Sealed__()
    class "__Base__" (function(_ENV)
        extend "IAttribute"
        doc "__Base__" [[Give the struct a base struct type, so the value must match the base struct type before validate it.]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        doc "Base" [[The base struct]]
        property "Base" { Type = Struct }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType)
            if self.Base then
                local info = _NSInfo[target]
                local binfo= _NSInfo[self.Base]

                info.SubType = binfo.SubType

                if info.SubType == STRUCT_TYPE_MEMBER then
                    -- Copy the members
                    for i, mem in ipairs(binfo.Members) do
                        info[i] = CloneObj(mem)
                    end
                elseif info.SubType == STRUCT_TYPE_ARRAY then
                    info[0] = binfo.ArrayElement
                end

                info.BaseStruct = self.Base
            end
        end

        function IsStructAttributeDefined(cls, target)
            if cls ~= __Base__ then return false end
            local info = _NSInfo[target]
            return info and info.BaseStruct ~= nil
        end

        function GetStructAttribute(cls, target)
            if cls ~= __Base__ then return false end
            local info = _NSInfo[target]
            return info and info.BaseStruct
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __Base__(self)
            self.Base = nil
        end

        __Arguments__{ Struct }
        function __Base__(self, value)
            self.Base = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
    __Sealed__()
    class "__ObjMethodAttr__" (function(_ENV)
        extend "IAttribute"

        doc "__ObjMethodAttr__" [[
            The class's objects can use attribute to it's self-only methods, just like the methods defined in the class.

                __ObjMethodAttr__{ Inheritable = false }
                class "A" {}

                obj = A()

                -- Call method as thread
                __Delegate__(System.Threading.ThreadCall)
                function obj:DoTask()
                    coroutine.yield(123)
                end

                -- Register event as event handler
                __SystemEvent__ "PLOOP_NEW_CLASS"
                function obj:NewClass(cls)
                    print("New class", cls)
                end
        ]]

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        __Doc__[[Whether the class's child-classes are also object method attribute enabled.]]
        property "Inheritable" { Type = Boolean }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target)
            if self.Inheritable then
                SaveInheritEnableObjMethodAttr(target)
            else
                _NSInfo[target].EnableObjMethodAttr = true
            end
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __ObjMethodAttr__ then return false end
            local info = _NSInfo[target]
            if info then return info.EnableObjMethodAttr, info.InheritEnableObjMethodAttr end
            return false
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{}
        function __ObjMethodAttr__(self)
            self.Inheritable = false
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true}
    __Sealed__()
    class "__WeakObject__" (function(_ENV)
        extend "IAttribute"
        doc "__WeakObject__" [[Mark the class' object as weak tables.]]

        enum "Mode" { "k", "v", "kv" }

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            _NSInfo[target].MetaTable.__mode = self.Mode
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __WeakObject__ then return false end
            local info = _NSInfo[target]
            return info and info.MetaTable and info.MetaTable.__mode ~=  nil
        end

        function GetClassAttribute(cls, target)
            if cls ~= __WeakObject__ then return false end
            local info = _NSInfo[target]
            return info and info.MetaTable and info.MetaTable.__mode
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{ Mode }
        function __WeakObject__(self, value)
            self.Mode = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Event, RunOnce = true}
    __Sealed__()
    class "__EventChangeHandler__" (function(_ENV)
        extend "IAttribute"
        doc "__EventChangeHandler__" [[Assign a method to handle the event handler's changing.]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target, targetType, owner, name)
            _NSInfo[owner].Event[name].OnEventHandlerChanged = self.Handler
        end

        ------------------------------------------------------
        -- Dispose
        ------------------------------------------------------
        function Dispose(self)
            self.Handler = nil
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{ Function }
        function __EventChangeHandler__(self, value)
            self.Handler = value
        end
    end)

    __AttributeUsage__{AttributeTarget = AttributeTargets.Class, RunOnce = true, BeforeDefinition = true}
    __Sealed__() __Unique__()
    class "__NoAutoSet__" (function(_ENV)
        extend "IAttribute"

        doc "__NoAutoSet__" [[
            The class's object can only assign value to it's properties or event handlers.

                __NoAutoSet__()
                class "A" (function(_ENV)
                    event "OnNameChanged"
                    property "Name" { Type = String }
                end)

                obj = A()

                -- Okay
                obj.Name = "Ann"
                obj.OnNameChanged = print

                -- Error, it can't be set
                obj.Other = 123
        ]]

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        function ApplyAttribute(self, target)
            _NSInfo[target].NoAutoSet = true
        end

        function IsClassAttributeDefined(cls, target)
            if cls ~= __NoAutoSet__ then return false end
            local info = _NSInfo[target]
            return info and info.NoAutoSet or false
        end
    end)

    -- Final Job
    do
        -- Structs
        __Sealed__:ApplyAttribute(Boolean)
        __Sealed__:ApplyAttribute(BooleanNil)
        __Sealed__:ApplyAttribute(RawBoolean)
        __Sealed__:ApplyAttribute(String)
        __Sealed__:ApplyAttribute(Number)
        __Sealed__:ApplyAttribute(Function)
        __Sealed__:ApplyAttribute(Table)
        __Sealed__:ApplyAttribute(Userdata)
        __Sealed__:ApplyAttribute(Thread)
        __Sealed__:ApplyAttribute(Any)
        __Sealed__:ApplyAttribute(Callable)
        __Sealed__:ApplyAttribute(Class)
        __Sealed__:ApplyAttribute(Interface)
        __Sealed__:ApplyAttribute(Struct)
        __Sealed__:ApplyAttribute(Enum)
        __Sealed__:ApplyAttribute(AnyType)

        -- System.Reflector
        __Sealed__:ApplyAttribute(Reflector)
        __Final__:ApplyAttribute(Reflector, AttributeTargets.Interface)

        -- Event
        __Sealed__() __Final__() __WeakObject__"k"
        class (Event) {}

        -- EventHandler
        __Sealed__:ApplyAttribute(EventHandler)
        __Final__:ApplyAttribute(EventHandler, AttributeTargets.Class)
    end
end

------------------------------------------------------
------------------- System.Module --------------------
------------------------------------------------------
do
    ------------------------------------------------------
    -- System.ICloneable
    ------------------------------------------------------
    __Doc__ [[Supports cloning, which creates a new instance of a class with the same value as an existing instance.]]
    interface "ICloneable" (function(_ENV)
        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        __Require__()
        __Doc__[[Creates a new object that is a copy of the current instance.]]
        function Clone(self) end
    end)

    _ModuleKeyWord = _KeywordAccessor()

    _ModuleKeyWord.namespace = namespace
    _ModuleKeyWord.class = class
    _ModuleKeyWord.interface = interface
    _ModuleKeyWord.enum = enum
    _ModuleKeyWord.struct = struct

    __Sealed__() __ObjMethodAttr__{ Inheritable = true }
    __Doc__[[Used to create an hierarchical environment with class system settings, like : Module "Root.ModuleA" "v72"]]
    class "Module" (function(_ENV)
        _Module = {}
        _ModuleInfo = setmetatable({}, WEAK_KEY)

        _ModuleKeyWord.import = function(self, name)
            local ns = name

            if type(name) == "string" then
                ns = Reflector.GetNameSpaceForName(name)
                if not ns then error(("no namespace is found with name : %s"):format(name), 2) end
            end

            if not Reflector.IsNameSpace(ns) then error([[Usage: import "namespaceA.namespaceB"]], 2) end

            local info = _ModuleInfo[self]
            if not info then error("can't use import here.", 2) end

            info.Import = info.Import or {}

            for _, v in ipairs(info.Import) do if v == ns then return end end

            tinsert(info.Import, ns)
        end

        local function iter(self, key) return next(_ModuleInfo[self].Modules, key) end

        local function noiter() end

        local function compareVer(old, new)
            old = old and old:match("^.-(%d+[%d%.]*).-$")
            old = old and old:match("^(.-)[%.]*$")

            if not old or old == "" then return true end

            local ty = type(new)
            if ty == "number" then
                new = tostring(new)
            elseif ty == "string" then
                new = new:match("^.-(%d+[%d%.]*).-$")
                new = new and new:match("^(.-)[%.]*$")
            else
                new = nil
            end

            if not new or new == "" then return false end

            local f1 = old:gmatch("%d+")
            local f2 = new:gmatch("%d+")

            local v1 = f1 and f1()
            local v2 = f2 and f2()

            local pass = false

            while true do
                v1 = tonumber(v1)
                v2 = tonumber(v2)

                if not v1 then
                    if v2 then pass = true end
                    break
                elseif not v2 then
                    break
                elseif v1 < v2 then
                    pass = true
                    break
                elseif v1 > v2 then
                    break
                end

                v1 = f1()
                v2 = f2()
            end

            return pass
        end

        ------------------------------------------------------
        -- Event
        ------------------------------------------------------
        __Doc__[[Fired when the module is disposed]]
        event "OnDispose"

        ------------------------------------------------------
        -- Method
        ------------------------------------------------------
        __Doc__[[
            <desc>Return true if the version is greater than the current version of the module</desc>
            <param name="version"></param>
            <return name="boolean">true if the version is a validated version</return>
        ]]
        function ValidateVersion(self, version)
            local info = _ModuleInfo[self]

            if not info then error("The module is disposed", 2) end

            return compareVer(info.Version, version)
        end

        __Doc__[[
            <desc>Get the child-module with the name</desc>
            <param name="name">string, the child-module's name</param>
            <return name="System"></return>.Module the child-module
        ]]
        function GetModule(self, name)
            if type(name) ~= "string" or strtrim(name) == "" then return end

            local mdl = self

            for sub in name:gmatch("[_%w]+") do
                mdl =  _ModuleInfo[mdl] and _ModuleInfo[mdl].Modules and _ModuleInfo[mdl].Modules[sub]

                if not mdl then return end
            end

            if mdl == self then return end

            return mdl
        end

        __Doc__[[
            <desc>Get all child-modules of the module</desc>
            <param optional='true' name='result'>the result table</param>
            <return name="iterator|result">the method iterator|the result table</return>
        ]]
        function GetModules(self, lst)
            if _ModuleInfo[self] and _ModuleInfo[self].Modules then
                if type(lst) == "table" then
                    for name, mdl in pairs(_ModuleInfo[self].Modules) do
                        lst[name] = mdl
                    end
                else
                    return iter, self
                end
            elseif type(lst) ~= "table" then
                return noiter
            end
            return lst
        end

        __Doc__[[Clear global defined functions for a new version, since the object method attributes can't be applied if those function existed]]
        function ClearGlobalMethods(self)
            for k, v in pairs(self) do
                if type(v) == "function" then
                    self[k] = nil
                end
            end
        end

        ------------------------------------------------------
        -- Property
        ------------------------------------------------------
        __Doc__[[The module itself]]
        property "_M" { Get = function(self) return self end }

        __Doc__[[The module's name]]
        property "_Name" { Get = function(self) return _ModuleInfo[self].Name end }

        __Doc__[[The module's parent module]]
        property "_Parent" { Get = function(self) return _ModuleInfo[self].Parent end }

        __Doc__[[The module's version]]
        property "_Version" { Get = function(self) return _ModuleInfo[self].Version end }

        ------------------------------------------------------
        -- Dispose
        ------------------------------------------------------
        function Dispose(self)
            local info = _ModuleInfo[self]

            if info then
                -- Clear child modules
                if info.Modules then
                    for name, mdl in pairs(info.Modules) do mdl:Dispose() end

                    wipe(info.Modules)

                    info.Modules = nil
                end

                -- Fire the event
                OnDispose(self)

                -- Clear from parent
                if info.Name then
                    if info.Parent then
                        if _ModuleInfo[info.Parent] and _ModuleInfo[info.Parent].Modules then
                            _ModuleInfo[info.Parent].Modules[info.Name] = nil
                        end
                    else
                        _Module[info.Name] = nil
                    end
                end

                -- Remove info
                _ModuleInfo[self] = nil
            end
        end

        ------------------------------------------------------
        -- Constructor
        ------------------------------------------------------
        __Arguments__{ String, Argument(Module, true) }
        function Module(self, name, parent)
            local prevName

            -- Check and create parent modules
            for sub in name:gmatch("[_%w]+") do
                if not prevName then
                    prevName = sub
                else
                    parent = getmetatable(self)(prevName, parent)
                    prevName = sub
                end
            end

            -- Save the module's information
            if prevName then
                if parent then
                    _ModuleInfo[parent].Modules = _ModuleInfo[parent].Modules or {}
                    _ModuleInfo[parent].Modules[prevName] = self
                else
                    _Module[prevName] = self
                end
            else
                parent = nil
            end

            _ModuleInfo[self] = {
                Owner = self,
                Name = prevName,
                Parent = parent,
            }
        end

        ------------------------------------------------------
        -- metamethod
        ------------------------------------------------------
        __Arguments__{ String, Argument(Module, true) }
        function __exist(name, parent)
            local mdl = parent

            for sub in name:gmatch("[_%w]+") do
                if not mdl then
                    mdl = _Module[sub]
                elseif _ModuleInfo[mdl] and _ModuleInfo[mdl].Modules then
                    mdl = _ModuleInfo[mdl].Modules[sub]
                else
                    mdl = nil
                end

                if not mdl then return end
            end

            if mdl == parent then return end

            return mdl
        end

        function __index(self, key)
            -- Check keywords
            local value = _ModuleKeyWord:GetKeyword(self, key)
            if value then return value end

            -- Check self's namespace
            local ns = Reflector.GetCurrentNameSpace(self, true)
            local parent = _ModuleInfo[self].Parent

            while not ns and parent do
                ns = Reflector.GetCurrentNameSpace(parent, true)
                parent = _ModuleInfo[parent].Parent
            end

            if ns and Reflector.GetNameSpaceName(ns) then
                if key == Reflector.GetNameSpaceName(ns) then
                    rawset(self, key, ns)
                    return rawget(self, key)
                elseif ns[key] then
                    rawset(self, key, ns[key])
                    return rawget(self, key)
                end
            end

            local info = _ModuleInfo[self]

            -- Check imports
            if info.Import then
                for _, ns in ipairs(info.Import) do
                    if key == Reflector.GetNameSpaceName(ns) then
                        rawset(self, key, ns)
                        return rawget(self, key)
                    elseif ns[key] then
                        rawset(self, key, ns[key])
                        return rawget(self, key)
                    end
                end
            end

            -- Check base namespace
            if Reflector.GetNameSpaceForName(key) then
                rawset(self, key, Reflector.GetNameSpaceForName(key))
                return rawget(self, key)
            end

            if info.Parent then
                value = info.Parent[key]
                if value ~= nil then rawset(self, key, value) end
                return value
            else
                if key ~= "_G" and type(key) == "string" and key:find("^_") then return end
                value = _G[key]
                if value ~= nil then rawset(self, key, value) end
                return value
            end
        end

        function __newindex(self, key, value)
            if _ModuleKeyWord:GetKeyword(self, key) then error(("The %s is a keyword."):format(key)) end
            rawset(self, key, value)
        end

        function __call(self, version, stack)
            stack = stack or 2
            local info = _ModuleInfo[self]

            if not info then error("The module is disposed", stack) end

            if type(version) == "function" then
                ClearPreparedAttributes()
                if not FAKE_SETFENV then setfenv(version, self) return version() end
                return version(self)
            end

            -- Check version
            if not compareVer(info.Version, version) then
                error("Not valid version or there is an equal or bigger version existed", stack)
            end

            version = version and tostring(version)
            version = version and strtrim(version)
            if version == "" then version = nil end

            info.Version = version

            if not FAKE_SETFENV then setfenv(stack, self) end

            ClearPreparedAttributes()

            return self
        end
    end)
end

------------------------------------------------------
------------------ Global Settings -------------------
------------------------------------------------------
do
    ------------------------------------------------------
    -- Clear useless keywords
    ------------------------------------------------------
    _KeyWord4IFEnv.doc = nil
    _KeyWord4ClsEnv.doc = nil

    if FAKE_SETFENV then setfenv() end

    -- Keep the root so can't be disposed
    System = Reflector.GetNameSpaceForName("System")

    function Install_OOP(env)
        env.interface = interface
        env.class = class
        env.struct = struct
        env.enum = enum

        env.namespace = env.namespace or namespace
        env.import = env.import or function(env, name)
            local ns = Reflector.GetNameSpaceForName(name or env)
            if not ns then error("No such namespace.", 2) end
            env = type(env) == "table" and env or getfenv(2) or _G

            name = _NSInfo[ns].Name
            if env[name] == nil then env[name] = ns end
            for subNs, sub in Reflector.GetSubNamespace(ns) do
                if _NSInfo[sub].Type and env[subNs] == nil then env[subNs] = sub end
            end
        end
        env.Module = env.Module or Module
        env.System = env.System or System
    end

    -- Install to the global environment
    --Install_OOP(_G)
    Install_OOP = nil
    _G.Module = Module
    collectgarbage()
end
