-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.ActionHandler", version) then
	return
end

import "ActionRefreshMode"

-- Event handler
function OnEnable(self)
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterEvent("UPDATE_SUMMONPETS_ACTION")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")

	OnEnable = nil
end

function ACTIONBAR_SLOT_CHANGED(self, slot)
	if slot == 0 then
		return handler:Refresh()
	else
		for _, button in handler() do
			if slot == button.ActionTarget then
				handler:Refresh(button)
			end
		end
	end
end

function ACTIONBAR_UPDATE_STATE(self)
	handler:Refresh(RefreshButtonState)
end

function ACTIONBAR_UPDATE_USABLE(self)
	handler:Refresh(RefreshUsable)
end

function ACTIONBAR_UPDATE_COOLDOWN(self)
	handler:Refresh(RefreshCooldown)

	RefreshTooltip()
end

function UPDATE_SUMMONPETS_ACTION(self)
	for _, btn in handler() do
		if GetActionCount(btn.ActionTarget) == "summonpet" then
			button.Icon = GetActionTexture(btn.ActionTarget)
		end
	end
end

function UPDATE_SHAPESHIFT_FORM(self)
	return handler:Refresh()
end

function UPDATE_SHAPESHIFT_FORMS(self)
	return handler:Refresh()
end

-- Action type handler
handler = ActionTypeHandler {
	Name = "action",

	DragStyle = "Keep",

	ReceiveStyle = "Keep",

	InitSnippet = [[
		NUM_ACTIONBAR_BUTTONS = 12

		_MainPage = newtable()

		MainPage = newtable()

		UpdateMainActionBar = [=[
			local page = ...
			if page == "tempshapeshift" then
				if HasTempShapeshiftActionBar() then
					page = GetTempShapeshiftBarIndex()
				else
					page = 1
				end
			elseif page == "possess" then
				page = Manager:GetFrameRef("MainMenuBarArtFrame"):GetAttribute("actionpage")
				if page <= 10 then
					page = Manager:GetFrameRef("OverrideActionBar"):GetAttribute("actionpage")
				end
				if page <= 10 then
					page = 12
				end
			end
			MainPage[0] = page
			for btn in pairs(_MainPage) do
				btn:SetAttribute("actionpage", MainPage[0])
				Manager:RunFor(btn, UpdateAction, "action", btn:GetID() or 1)
			end
		]=]

	]],

	PickupSnippet = [[
		local target = ...

		if self:GetAttribute("actionpage") and self:GetID() > 0 then
			target = self:GetID() + (tonumber(self:GetAttribute("actionpage"))-1) * NUM_ACTIONBAR_BUTTONS
		end

		return "clear", "action", target
	]],

	UpdateSnippet = [[
	]],

	ReceiveSnippet = [[
	]],
}

do
	handler.Manager:SetFrameRef("MainMenuBarArtFrame", MainMenuBarArtFrame)
	handler.Manager:SetFrameRef("OverrideActionBar", OverrideActionBar)

	-- ActionBar swap register
	local state = {}

	-- special using
	tinsert(state, "[overridebar][possessbar]possess")

	-- action bar swap
	for i = 2, 6 do
		tinsert(state, ("[bar:%d]%d"):format(i, i))
	end

	-- stance
	local _, playerclass = UnitClass("player")

	if playerclass == "DRUID" then
		-- prowl first
		tinsert(state, "[bonusbar:1,stealth]8")
	elseif playerclass == "WARRIOR" then
		tinsert(state, "[stance:2]7")
		tinsert(state, "[stance:3]8")
	end

	-- bonusbar map
	for i = 1, 4 do
		tinsert(state, ("[bonusbar:%d]%d"):format(i, i+6))
	end

	-- Fix for temp shape shift bar
	tinsert(state, "[stance:1]tempshapeshift")

	tinsert(state, "1")

	state = table.concat(state, ";")

	local now = SecureCmdOptionParse(state)

	handler:RunSnippet(("MainPage[0] = %s"):format(now))

	handler.Manager:RegisterStateDriver("page", state)

	handler.Manager:SetAttribute("_onstate-page", [=[
		Manager:Run(UpdateMainActionBar, newstate)
	]=])
end

-- Overwrite methods
function handler:GetActionDetail()
	local target = ActionButton_CalculateAction(self)
	local desc

	if target then
		local type, id = GetActionInfo(action)

		if type and id then
			desc = ""..type.."_"..id
		end
	end

	return target, desc
end

function handler:PickupAction(target)
	return PickupAction(target)
end

function handler:HasAction()
	return HasAction(self.ActionTarget)
end

function handler:GetActionText()
	return GetActionText(self.ActionTarget)
end

function handler:GetActionTexture()
	return GetActionTexture(self.ActionTarget)
end

function handler:GetActionCharges()
	return GetActionCharges(self.ActionTarget)
end

function handler:GetActionCount()
	return GetActionCount(self.ActionTarget)
end

function handler:GetActionCooldown()
	return GetActionCooldown(self.ActionTarget)
end

function handler:IsAttackAction()
	return IsAttackAction(self.ActionTarget)
end

function handler:IsEquippedItem()
	return IsEquippedAction(self.ActionTarget)
end

function handler:IsActivedAction()
	return IsCurrentAction(self.ActionTarget)
end

function handler:IsAutoRepeatAction()
	return IsAutoRepeatAction(self.ActionTarget)
end

function handler:IsUsableAction()
	return IsUsableAction(self.ActionTarget)
end

function handler:IsConsumableAction()
	local target = self.ActionTarget
	return IsConsumableAction(target) or IsStackableAction(target) or (not IsItemAction(target) and GetActionCount(target) > 0)
end

function handler:IsInRange()
	return IsActionInRange(self.ActionTarget, self:GetAttribute("unit"))
end

function handler:SetTooltip(GameTooltip)
	GameTooltip:SetAction(self.ActionTarget)
end

function handler:GetSpellId()
	local type, id = GetActionInfo(self.ActionTarget)
	if type == "spell" then
		return id
	elseif type == "macro" then
		return (select(3, GetMacroSpell(id)))
	end
end
