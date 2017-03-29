
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

export DNotify
export DNOTIFY_SIDE_LEFT
export DNOTIFY_SIDE_RIGHT
export DNOTIFY_POS_TOP
export DNOTIFY_POS_BOTTOM

DNotify = {}
DNotify.RegisteredThinks = {}
DNotify.NotificationsSlideLeft = {}
DNotify.NotificationsSlideRight = {}
DNotify.NotificationsCenterTop = {}
DNotify.NotificationsCenterBottom = {}

X_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '0', {FCVAR_ARCHIVE}, 'Shift at X of DNotify slide notifications')
Y_SHIFT_CVAR = CreateConVar('dnofity_y_shift', '45', {FCVAR_ARCHIVE}, 'Shift at Y of DNotify slide notifications')

DNOTIFY_SIDE_LEFT = 1
DNOTIFY_SIDE_RIGHT = 2
DNOTIFY_POS_TOP = 3
DNOTIFY_POS_BOTTOM = 4

DNotify.newLines = (str = '') -> string.Explode('\n', str)
DNotify.allowedOrign = (enum) ->
	enum == TEXT_ALIGN_LEFT or
	enum == TEXT_ALIGN_RIGHT or
	enum == TEXT_ALIGN_CENTER

HUDPaint = ->
	yShift = 0
	
	x = X_SHIFT_CVAR\GetInt()
	y = Y_SHIFT_CVAR\GetInt()
	
	for k, func in pairs DNotify.NotificationsSlideLeft
		if func\IsValid()
			status, currShift = pcall(func.Draw, func, x, y + yShift)
			if status
				yShift += currShift
			else
				print('[DNotify] ERROR ', currShift)
		else
			DNotify.NotificationsSlideLeft[k] = nil

	
	yShift = 0
	x = ScrW! - X_SHIFT_CVAR\GetInt()
	y = Y_SHIFT_CVAR\GetInt()
	
	for k, func in pairs DNotify.NotificationsSlideRight
		if func\IsValid()
			status, currShift = pcall(func.Draw, func, x, y + yShift)
			
			if status
				yShift += currShift
			else
				print('[DNotify] ERROR ', currShift)
		else
			DNotify.NotificationsSlideRight[k] = nil
	
	yShift = 0
	x = ScrW! / 2
	y = ScrH! * 0.26
	
	for k, func in pairs DNotify.NotificationsCenterTop
		if func\IsValid()
			status, currShift = pcall(func.Draw, func, x, y + yShift)
			
			if status
				yShift += currShift
			else
				print('[DNotify] ERROR ', currShift)
		else
			DNotify.NotificationsCenterTop[k] = nil
	
	y = ScrH! * 0.75
	
	for k, func in pairs DNotify.NotificationsCenterBottom
		if func\IsValid()
			status, currShift = pcall(func.Draw, func, x, y + yShift)
			
			if status
				yShift += currShift
			else
				print('[DNotify] ERROR ', currShift)
		else
			DNotify.NotificationsCenterBottom[k] = nil

Think = ->
	for k, func in pairs DNotify.RegisteredThinks
		if func\IsValid!
			func\Think!
		else
			DNotify.RegisteredThinks[k] = nil

hook.Add('HUDPaint', 'DNotify', HUDPaint)
hook.Add('Think', 'DNotify', Think)

include 'dnotify/font_obj.lua'
include 'dnotify/base_class.lua'
include 'dnotify/templates.lua'
include 'dnotify/animated_base.lua'
include 'dnotify/slide_class.lua'
include 'dnotify/centered_class.lua'

return nil
