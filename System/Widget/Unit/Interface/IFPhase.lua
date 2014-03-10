-- Author      : Kurapica
-- Create Date : 2012/07/12
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Unit.IFPhase", version) then
	return
end

_All = "all"
_IFPhaseUnitList = _IFPhaseUnitList or UnitList(_Name)

function _IFPhaseUnitList:OnUnitListChanged()
	self:RegisterEvent("UNIT_PHASE")

	self.OnUnitListChanged = nil
end

function _IFPhaseUnitList:ParseEvent(event)
	self:EachK(_All, "Refresh")
end

__Doc__[[
	<desc>IFPhase is used to check whether the unit is in the same phase with the player</desc>
	<overridable name="Visible" type="property" valuetype="boolean">used to receive the result that whether the unit is in the same phase with the player</overridable>
]]
interface "IFPhase"
	extend "IFUnitElement"

	------------------------------------------------------
	-- Event
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function Refresh(self)
		self.Visible = self.Unit and UnitInPhase(self.Unit)
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Event Handler
	------------------------------------------------------

	------------------------------------------------------
	-- Dispose
	------------------------------------------------------
	function Dispose(self)
		_IFPhaseUnitList[self] = nil
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function IFPhase(self)
		_IFPhaseUnitList[self] = _All

		-- Default Texture
		if self:IsClass(Texture) then
			if not self.TexturePath and not self.Color then
				self.TexturePath = [[Interface\TargetingFrame\UI-PhasingIcon]]
			end
		end
	end
endinterface "IFPhase"