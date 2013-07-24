-- Author      : Kurapica
-- Create Date : 2012/11/07
-- Change Log  :

-- Check Version
local version = 3
if not IGAS:NewAddon("IGAS.Widget.Unit.UnitPanel", version) then
	return
end

class "UnitPanel"
	inherit "SecureFrame"
	extend "IFGroup"

	doc [======[
		@name UnitPanel
		@type class
		@desc The unit panel for party or raid members
	]======]

	MAX_RAID_MEMBERS = _G.MAX_RAID_MEMBERS
	NUM_RAID_GROUPS = _G.NUM_RAID_GROUPS
	MEMBERS_PER_RAID_GROUP = _G.MEMBERS_PER_RAID_GROUP

	------------------------------------------------------
	-- Event
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function UnitPanel(self)
		self.ElementType = UnitFrame	-- Default Element, need override

		self.RowCount = MEMBERS_PER_RAID_GROUP
		self.ColumnCount = NUM_RAID_GROUPS
		self.ElementWidth = 80
		self.ElementHeight = 32

		self.Orientation = Orientation.VERTICAL
		self.HSpacing = 2
		self.VSpacing = 2
		self.AutoSize = true

		self.MarginTop = 0
		self.MarginBottom = 0
		self.MarginLeft = 0
		self.MarginRight = 0

		-- Init for IFUnitGroup
		self.ShowRaid = true
		self.ShowParty = true
		self.ShowSolo = true
		self.ShowPlayer = true
    end
endclass "UnitPanel"