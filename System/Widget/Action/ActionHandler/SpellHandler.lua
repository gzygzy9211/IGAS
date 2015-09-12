-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :
--               2014/11/16 Add support to trap launcher, works like stance spell

-- Check Version
local version = 3
if not IGAS:NewAddon("IGAS.Widget.Action.SpellHandler", version) then
	return
end

import "System.Widget.Action.ActionRefreshMode"

_StanceMapTemplate = "_StanceMap[%d] = %d\n"
_MacroMapTemplate = "_MacroMap[%d]=%q\n"
_FakeStanceMapTemplate = "_FakeStanceMap[%d]=%q\n"

_StanceOnTexturePath = [[Interface\Icons\Spell_Nature_WispSplode]]

_StanceMap = {}
_Profession = {}

_MacroMap = {
	[1499] = true,	-- Freezing Trap
	[13809] = true,	-- Ice Trap
	[13813] = true,	-- Explosive Trap
}

_FakeStanceMap = {
	[77769] = true,	-- Trap Launcher
}

-- Event handler
function OnEnable(self)
	self:RegisterEvent("LEARNED_SPELL_IN_TAB")
	self:RegisterEvent("SPELLS_CHANGED")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("SPELL_UPDATE_USABLE")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_AURA")

	OnEnable = nil
	UpdateStanceMap()
	UpdateMacroMap()
	UpdateFakeStanceMap()
end

function LEARNED_SPELL_IN_TAB(self)
	RefreshTooltip()

	return UpdateProfession()
end

function SPELLS_CHANGED(self)
	return UpdateProfession()
end

function SKILL_LINES_CHANGED(self)
	return UpdateProfession()
end

function PLAYER_GUILD_UPDATE(self)
	return UpdateProfession()
end

function PLAYER_SPECIALIZATION_CHANGED(self, unit)
	if unit == "player" then
		return UpdateProfession()
	end
end

function UPDATE_SHAPESHIFT_FORM(self)
	return handler:Refresh()
end

function UPDATE_SHAPESHIFT_FORMS(self)
	UpdateStanceMap()

	return handler:Refresh()
end

function SPELL_UPDATE_COOLDOWN(self)
	return handler:Refresh(RefreshCooldown)
end

function SPELL_UPDATE_USABLE(self)
	return handler:Refresh(RefreshUsable)
end

function CURRENT_SPELL_CAST_CHANGED(self)
	return handler:Refresh(RefreshButtonState)
end

function PLAYER_ENTERING_WORLD(self)
	return handler:Refresh()
end

function UNIT_AURA(self, unit)
	if unit == "player" then
		for _, btn in handler() do
			local target = btn.ActionTarget

			if _StanceMap[target] or _FakeStanceMap[target] then handler:Refresh(btn) end
		end
	end
end

function UpdateStanceMap()
	local str = "for i in pairs(_StanceMap) do _StanceMap[i] = nil end\n"

	wipe(_StanceMap)

	for i = 1, GetNumShapeshiftForms() do
	    local name = select(2, GetShapeshiftFormInfo(i))
	    name = GetSpellLink(name)
	    name = tonumber(name and name:match("spell:(%d+)"))
	    if name then
			str = str.._StanceMapTemplate:format(name, i)
	    	_StanceMap[name] = i
	    end
	end

	if str ~= "" then
		Task.NoCombatCall(function ()
			handler:RunSnippet( str )

			for _, btn in handler() do
				if _StanceMap[btn.ActionTarget] then
					btn:SetAttribute("*type*", "macro")
					btn:SetAttribute("*macrotext*", "/click StanceButton".._StanceMap[btn.ActionTarget])
				end
			end
		end)
	end
end

function UpdateMacroMap()
	local str = ""
	for spell in pairs(_MacroMap) do
		local name = GetSpellInfo(spell)
		if name then
			_MacroMap[spell] = name
			str = str .. _MacroMapTemplate:format(spell, name)
		end
	end

	if str ~= "" then
		Task.NoCombatCall(function ()
			handler:RunSnippet( str )

			for _, btn in handler() do
				if _MacroMap[btn.ActionTarget] then
					btn:SetAttribute("*type*", "macro")
					btn:SetAttribute("*macrotext*", "/cast ".._MacroMap[btn.ActionTarget])
				end
			end
		end)
	end
end

function UpdateFakeStanceMap()
	local str = ""
	for spell in pairs(_FakeStanceMap) do
		local name = GetSpellInfo(spell)
		if name then
			_FakeStanceMap[spell] = name
			str = str .. _FakeStanceMapTemplate:format(spell, name)
		end
	end

	if str ~= "" then
		Task.NoCombatCall(function ()
			handler:RunSnippet( str )

			for _, btn in handler() do
				if _FakeStanceMap[btn.ActionTarget] then
					btn:SetAttribute("*type*", "macro")
					btn:SetAttribute("*macrotext*", "/cancelaura ".._FakeStanceMap[btn.ActionTarget].."\n/cast ".._FakeStanceMap[btn.ActionTarget])
				end
			end
		end)
	end
end

function UpdateProfession()
	local lst = {GetProfessions()}
	local offset, spell, name

	for i = 1, 6 do
	    if lst[i] then
	        offset = 1 + select(6, GetProfessionInfo(lst[i]))
	        spell = select(2, GetSpellBookItemInfo(offset, "spell"))
	        name = GetSpellBookItemName(offset, "spell")

	        if _Profession[name] ~= spell then
	        	_Profession[name] = spell
	        	Task.NoCombatCall(function ()
	        		for _, btn in handler() do
	        			if GetSpellInfo(btn.ActionTarget) == name then
	        				btn:SetAction("spell", spell)
	        			end
	        		end
	        	end)
	        end
	    end
	end
end

-- Spell action type handler
handler = ActionTypeHandler {
	Name = "spell",

	InitSnippet = [[
		_StanceMap = newtable()
		_MacroMap = newtable()
		_FakeStanceMap = newtable()
	]],

	UpdateSnippet = [[
		local target = ...

		if _StanceMap[target] then
			self:SetAttribute("*type*", "macro")
			self:SetAttribute("*macrotext*", "/click StanceButton".. _StanceMap[target])
		elseif _MacroMap[target] then
			self:SetAttribute("*type*", "macro")
			self:SetAttribute("*macrotext*", "/cast ".. _MacroMap[target])
		elseif _FakeStanceMap[target] then
			self:SetAttribute("*type*", "macro")
			self:SetAttribute("*macrotext*", "/cancelaura ".. _FakeStanceMap[target] .. "\n/cast ".. _FakeStanceMap[target])
		end
	]],

	ReceiveSnippet = [[
		local value, detail, extra = ...

		-- Spell id is stored in extra
		return extra
	]],

	ClearSnippet = [[
		self:SetAttribute("*type*", nil)
		self:SetAttribute("*macrotext*", nil)
	]],
}

-- Overwrite methods
function handler:PickupAction(target)
	return PickupSpell(target)
end

function handler:GetActionTexture()
	local target = self.ActionTarget

	if _StanceMap[target] then
		return (GetShapeshiftFormInfo(_StanceMap[target]))
	elseif _FakeStanceMap[target] and _FakeStanceMap[target] ~= true and UnitAura("player", _FakeStanceMap[target]) then
		return _StanceOnTexturePath
	else
		return GetSpellTexture(target)
	end
end

function handler:GetActionCharges()
	return GetSpellCharges(self.ActionTarget)
end

function handler:GetActionCount()
	return GetSpellCount(self.ActionTarget)
end

function handler:GetActionCooldown()
	local target = self.ActionTarget

	if _StanceMap[target] then
		if select(2, GetSpellCooldown(target)) > 2 then
			return GetSpellCooldown(target)
		end
	else
		return GetSpellCooldown(target)
	end
end

function handler:IsAttackAction()
	return IsAttackSpell(GetSpellInfo(self.ActionTarget))
end

function handler:IsActivedAction()
	local target = self.ActionTarget
	if _StanceMap[target] then
		return select(3, GetShapeshiftFormInfo(_StanceMap[target]))
	else
		return IsCurrentSpell(target)
	end
end

function handler:IsAutoRepeatAction()
	return IsAutoRepeatSpell(GetSpellInfo(self.ActionTarget))
end

function handler:IsUsableAction()
	local target = self.ActionTarget

	if _StanceMap[target] then
		return select(4, GetShapeshiftFormInfo(_StanceMap[target]))
	else
		return IsUsableSpell(target)
	end
end

function handler:IsConsumableAction()
	return IsConsumableSpell(self.ActionTarget)
end

function handler:IsInRange()
	return IsSpellInRange(GetSpellInfo(self.ActionTarget), self:GetAttribute("unit"))
end

function handler:SetTooltip(GameTooltip)
	GameTooltip:SetSpellByID(self.ActionTarget)
end

function handler:GetSpellId()
	return self.ActionTarget
end

-- Part-interface definition
interface "IFActionHandler"
	local old_SetAction = IFActionHandler.SetAction

	function SetAction(self, kind, target, ...)
		if kind == "spell" then
			-- Convert to spell id
			if tonumber(target) then
				target = tonumber(target)
			else
				target = GetSpellLink(target)
		   		target = tonumber(target and target:match("spell:(%d+)"))
			end

			if target and _Profession[GetSpellInfo(target)] then
				target = _Profession[GetSpellInfo(target)]
			end
		end

		return old_SetAction(self, kind, target, ...)
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'spell']]
	property "Spell" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "spell" and self:GetAttribute("spell") or nil
		end,
		Set = function(self, value)
			self:SetAction("spell", value)
		end,
		Type = StringNumber,
	}
endinterface "IFActionHandler"