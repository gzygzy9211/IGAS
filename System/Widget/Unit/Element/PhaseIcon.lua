-- Author      : Kurapica
-- Create Date : 2012/06/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Unit.PhaseIcon", version) then
	return
end

class "PhaseIcon"
	inherit "Texture"
	extend "IFPhase"

	doc [======[
		@name PhaseIcon
		@type class
		@desc The phase indicator
	]======]

	------------------------------------------------------
	-- Event
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function Refresh(self)
		self.Visible = not UnitInPhase(self.Unit)
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function PhaseIcon(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.TexturePath = [[Interface\TargetingFrame\UI-PhasingIcon]]

		self.Height = 16
		self.Width = 16
	end
endclass "PhaseIcon"