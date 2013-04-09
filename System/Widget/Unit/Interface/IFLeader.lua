-- Author      : Kurapica
-- Create Date : 2012/07/12
-- Change Log  :

-- Check Version
local version = 2
if not IGAS:NewAddon("IGAS.Widget.Unit.IFLeader", version) then
	return
end

_All = "all"
_IFLeaderUnitList = _IFLeaderUnitList or UnitList(_Name)

function _IFLeaderUnitList:OnUnitListChanged()
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	self.OnUnitListChanged = nil
end

function _IFLeaderUnitList:ParseEvent(event)
	self:EachK(_All, "Refresh")
end

interface "IFLeader"
	extend "IFUnitElement"

	doc [======[
		@name IFLeader
		@type interface
		@desc IFLeader is used to handle the unit leader state's updating
		@overridable Visible property, boolean, used to receive the result that whether the leader indicator should be shown
	]======]

	------------------------------------------------------
	-- Script
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	doc [======[
		@name Refresh
		@type method
		@desc The default refresh method, overridable
		@return nil
	]======]
	function Refresh(self)
		local unit = self.Unit
		self.Visible = unit and (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit)
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Script Handler
	------------------------------------------------------

	------------------------------------------------------
	-- Dispose
	------------------------------------------------------
	function Dispose(self)
		_IFLeaderUnitList[self] = nil
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function IFLeader(self)
		_IFLeaderUnitList[self] = _All

		-- Default Texture
		if self:IsClass(Texture) then
			if not self.TexturePath and not self.Color then
				self.TexturePath = [[Interface\GroupFrame\UI-Group-LeaderIcon]]
			end
		end
	end
endinterface "IFLeader"