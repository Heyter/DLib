
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

HUDCommons.ShiftX = 0
HUDCommons.ShiftY = 0
HUDCommons.LastAngle = Angle(0, 0, 0)

HUDCommons.XPositions = HUDCommons.XPositions or {}
HUDCommons.YPositions = HUDCommons.YPositions or {}
HUDCommons.XPositions_modified = HUDCommons.XPositions_modified or {}
HUDCommons.YPositions_modified = HUDCommons.YPositions_modified or {}
HUDCommons.XPositions_original = HUDCommons.XPositions_original or {}
HUDCommons.YPositions_original = HUDCommons.YPositions_original or {}
HUDCommons.Positions_funcs = HUDCommons.Positions_funcs or {}

HUDCommons.Multipler = 1

function HUDCommons.DefinePosition(name, x, y, shouldShift)
	if shouldShift ~= nil then
		if type(shouldShift) ~= 'function' then
			local l = shouldShift
			shouldShift = function() return l end
		end
	else
		shouldShift = function() return true end
	end

	if x < 1 then
		x = ScrW() * x
	end

	if y < 1 then
		y = ScrH() * y
	end

	HUDCommons.XPositions_original[name] = x
	HUDCommons.YPositions_original[name] = y

	HUDCommons.XPositions_modified[name] = x
	HUDCommons.YPositions_modified[name] = y

	if not table.HasValue(HUDCommons.XPositions, name) then
		table.insert(HUDCommons.XPositions, name)
	end

	if not table.HasValue(HUDCommons.YPositions, name) then
		table.insert(HUDCommons.YPositions, name)
	end

	HUDCommons.Positions_funcs[name] = shouldShift

	return function()
		if shouldShift() then
			return HUDCommons.XPositions_modified[name], HUDCommons.YPositions_modified[name]
		else
			return HUDCommons.XPositions_original[name], HUDCommons.YPositions_original[name]
		end
	end
end

HUDCommons.CreatePosition = HUDCommons.DefinePosition

function HUDCommons.GetPos(elem)
	if not HUDCommons.Positions_funcs[elem] or HUDCommons.Positions_funcs[elem]() then
		return HUDCommons.XPositions_modified[elem] or 0, HUDCommons.YPositions_modified[elem] or 0
	else
		return HUDCommons.XPositions_original[elem] or 0, HUDCommons.YPositions_original[elem] or 0
	end
end

HUDCommons.GetPosition = HUDCommons.GetPos

local function UpdatePositions()
	for k, v in pairs(HUDCommons.XPositions) do
		HUDCommons.XPositions_modified[v] = HUDCommons.XPositions_original[v] + HUDCommons.ShiftX
	end

	for k, v in pairs(HUDCommons.YPositions) do
		HUDCommons.YPositions_modified[v] = HUDCommons.YPositions_original[v] + HUDCommons.ShiftY
	end
end

local function UpdateShift()
	local ply = HUDCommons.SelectPlayer()
	local ang = ply:EyeAngles()

	local changePitch = math.AngleDifference(ang.p, HUDCommons.LastAngle.p)
	local changeYaw = math.AngleDifference(ang.y, HUDCommons.LastAngle.y)

	HUDCommons.LastAngle = LerpAngle(FrameTime() * 33, HUDCommons.LastAngle, ang)

	HUDCommons.ShiftX = math.Clamp(HUDCommons.ShiftX + changeYaw * 1.8, -30, 30)
	HUDCommons.ShiftY = math.Clamp(HUDCommons.ShiftY - changePitch * 1.8, -20, 20)

	HUDCommons.ShiftX = HUDCommons.ShiftX - HUDCommons.ShiftX * FrameTime() * 22
	HUDCommons.ShiftY = HUDCommons.ShiftY - HUDCommons.ShiftY * FrameTime() * 22
end

local function Think()
	UpdateShift()
	UpdatePositions()
end

hook.Add('Think', 'HUDCommons.PositionShift', Think)
