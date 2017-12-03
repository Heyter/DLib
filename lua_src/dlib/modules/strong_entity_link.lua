
--
-- Copyright (C) 2017 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local STRONG_ENTITIES_REGISTRY = {}
local WRAPPED_FUNCTIONS = {}

local entMeta = FindMetaTable('Entity')
local isValid = entMeta.IsValid
local getTable = entMeta.GetTable
local ent__eq = entMeta.__eq
local entIndex = entMeta.EntIndex

entMeta.GetStrongEntity = function(self, ...)
    return self
end

entMeta.GetEntity = function(self, ...)
    local tab = self:GetTable()
    if not tab then return self end
    local oldVal = tab.GetEntity

    if oldVal then
        return oldVal(self, ...)
    end

    return self
end

local UniqueNoValue = 'STRONG_ENTITY_RESERVED_NO_VALUE'

local StrongLinkMetadata = {
    GetEntity = function(self)
        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        return self.__strong_entity_link
    end,

	GetStrongEntity = function(self)
        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        return self.__strong_entity_link
    end,

    GetTable = function(self)
        local upvalue = self
        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        local ourTable = self.__strong_entity_table

        return setmetatable({}, {
            __index = function(self, key)
                local value = ourTable[key]

                if value ~= nil then
                    return value
                else
                    if not isValid(upvalue.__strong_entity_link) then
                        upvalue.__strong_entity_link = Entity(upvalue.__strong_entity_link_id)
                    end

                    if isValid(upvalue.__strong_entity_link) then
                        return getTable(upvalue.__strong_entity_link)[key]
                    else
                        return nil
                    end
                end
            end,

            __newindex = function(self, key, value)
                if not isValid(upvalue.__strong_entity_link) then
                    upvalue.__strong_entity_link = Entity(upvalue.__strong_entity_link_id)
                end

                if not isValid(upvalue.__strong_entity_link) then
                    if value ~= nil then
                        ourTable[key] = value
                    else
                        ourTable[key] = UniqueNoValue
                    end
                else
                    getTable(upvalue.__strong_entity_link)[key] = value
                    ourTable[key] = value
                end
            end
        })
    end,

    EntIndex = function(self)
        return self.__strong_entity_link_id
    end
}

local metaData = {
    __index = function(self, key)
        if key == '__strong_entity_meta' then return debug.getmetatable(self) end
        if key == '__strong_entity_link' then return debug.getmetatable(self).__strong_entity_link end
        if key == '__strong_entity_link_id' then return debug.getmetatable(self).__strong_entity_link_id end
        if key == '__strong_entity_table' then return debug.getmetatable(self).__strong_entity_table end

        local value = rawget(self, key)

        if value ~= nil then
            return value
        end

		local self2 = self.__strong_entity_meta

        if not isValid(self2.__strong_entity_link) then
            self2.__strong_entity_link = Entity(self2.__strong_entity_link_id)
        end

        if StrongLinkMetadata[key] ~= nil then
            return StrongLinkMetadata[key]
        end

        if isValid(self2.__strong_entity_link) then
            local val = self2.__strong_entity_link[key]

            if type(val) == 'function' then
                if not self2.__strong_entity_funcs[val] then
                    self2.__strong_entity_funcs[val] = function(...)
                        local upvalueEntity = self2.__strong_entity_link
                        local args = {...}
                        local len = #args

                        for i = 1, len do
                            if args[i] == self then
                                args[i] = upvalueEntity
                            end
                        end

                        return val(unpack(args))
                    end
                end

                return self2.__strong_entity_funcs[val]
            end

            return val
        else
            local value = self2.__strong_entity_table[key]
            if value ~= UniqueNoValue then
                return value
            else
                return nil
            end
        end
    end,

    __newindex = function(self, key, value)
        local self2 = self.__strong_entity_meta

        if not isValid(self2.__strong_entity_link) then
            self2.__strong_entity_link = Entity(self2.__strong_entity_link_id)
        end

        if isValid(self2.__strong_entity_link) then
            getTable(self2.__strong_entity_link)[key] = value
            self2.__strong_entity_table[key] = value
        else
            if value ~= nil then
                self2.__strong_entity_table[key] = value
            else
                self2.__strong_entity_table[key] = UniqueNoValue
            end
        end
    end,

    __tostring = function(self)
        return tostring(self.__strong_entity_meta.__strong_entity_link)
    end,

    __eq = function(self, target)
        local ent = self.__strong_entity_meta.__strong_entity_link
        local tType = type(target)
        local validEnt = tType ~= 'number' and tType ~= 'string'
        return ent == target or validEnt and (ent == target.__strong_entity_link or target.EntIndex and target.EntIndex == self.__strong_entity_link_id)
    end
}

local function InitStrongEntity(entIndex)
    if type(entIndex) ~= 'number' then
        if IsValid(entIndex) then
            entIndex = entIndex:EntIndex()

			if entIndex < 0 then
				if SERVER then
					return NULL
				end
            end
        else
            entIndex = -1
        end
    end

    if STRONG_ENTITIES_REGISTRY[entIndex] then
        return STRONG_ENTITIES_REGISTRY[entIndex]
    end

    local newMeta = {
        __index = metaData.__index,
        __newindex = metaData.__newindex,
        __eq = metaData.__eq,
        __tostring = metaData.__tostring,
        __strong_entity_table = {},
        __strong_entity_funcs = {},
        __strong_entity = true,
        __strong_entity_link_id = entIndex,
        __strong_entity_link = Entity(entIndex),
    }

    local newObject = setmetatable({}, newMeta)

    STRONG_ENTITIES_REGISTRY[entIndex] = newObject
    return newObject
end

_G.StrongEntity = InitStrongEntity

if CLIENT then
    hook.Add('NetworkEntityCreated', 'StrongEntity', function(self)
        local id = self:EntIndex()

        if not STRONG_ENTITIES_REGISTRY[id] then return end
        local tab = self:GetTable()

        local strongEnt = STRONG_ENTITIES_REGISTRY[id]
        local strongTableMeta = debug.getmetatable(strongEnt)
		local strongTable = strongTableMeta.__strong_entity_table

        for key, value in pairs(strongTable) do
            if value ~= UniqueNoValue then
                tab[key] = value
            else
                tab[key] = nil
                strongTable[key] = nil
            end
        end

		strongTableMeta.__strong_entity_link = self
        hook.Call('StrongEntityLinkUpdates', nil, strongEnt, self)
    end)

    net.Receive('StrongEntity.Removed', function()
        local entIndex = net.ReadUInt(16)
        STRONG_ENTITIES_REGISTRY[entIndex] = nil
	end)

	hook.Add('EntityRemoved', 'StrongEntityClientside', function(ent)
		-- Clientside entity
		STRONG_ENTITIES_REGISTRY[ent] = nil
	end)
else
    util.AddNetworkString('StrongEntity.Removed')
    local avaliableEntities = {}

    local function checkEntities()
        local hash = {}

        for i, ent in pairs(ents.GetAll()) do
            hash[ent] = {ent, ent:EntIndex()}
        end

        for ent, data in pairs(avaliableEntities) do
            if not hash[ent] then
                local entIndex = data[2]
                net.Start('StrongEntity.Removed')
                net.WriteUInt(entIndex, 16)
                net.Broadcast()
                STRONG_ENTITIES_REGISTRY[entIndex] = nil
            end
        end

        avaliableEntities = hash
    end

    local function updateList()
        for i, ent in pairs(ents.GetAll()) do
            avaliableEntities[ent] = {ent, ent:EntIndex()}
        end
    end

    updateList()

    -- For some reason, some of entities are not being passed to this function
    -- Example - ragdolls with posed flexes
    hook.Add('EntityRemoved', 'StrongEntity', function(self)
        local entIndex = self:EntIndex()
        net.Start('StrongEntity.Removed')
        net.WriteUInt(entIndex, 16)
        net.Broadcast()
        STRONG_ENTITIES_REGISTRY[entIndex] = nil
        avaliableEntities[self] = nil
        timer.Create('StrongEntityDeletedCheck', 0, 1, checkEntities)
    end)

    hook.Add('OnEntityCreated', 'StrongEntity', function(self)
        timer.Create('StrongEntityCreatedCheck', 0, 1, updateList)
    end)
end

local net = DLib.netModule
local messageMeta = FindMetaTable('LNetworkMessage')

function messageMeta:WriteStrongEntity(ent)
	if type(ent) == 'number' then
        local isValidEntity = ent >= 0
        self:WriteBool(isValidEntity)

        if isValidEntity then
            self:WriteUInt(ent, 16)
        end
    else
        local isValidEntity = IsValid(ent) and ent:EntIndex() >= 1 or ent == Entity(0)
        self:WriteBool(isValidEntity)

        if isValidEntity then
            self:WriteUInt(ent:EntIndex(), 16)
        end
    end

	return self
end

function messageMeta:ReadStrongEntity()
	local isValidEntity = self:ReadBool()

	if isValidEntity then
		local val = self:ReadUInt(16)
		return InitStrongEntity(val)
	else
		return InitStrongEntity(-1)
	end
end

net.RegisterWrapper('StrongEntity')
