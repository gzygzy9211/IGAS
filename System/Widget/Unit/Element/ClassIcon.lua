﻿-- Author      : Kurapica
-- Create Date : 2012/06/25
-- Change Log  :

-- Check Version
local version = 2
if not IGAS:NewAddon("IGAS.Widget.Unit.ClassIcon", version) then
	return
end

class "ClassIcon"
	inherit "Texture"
	extend "IFUnitElement"

	doc [======[
		@name ClassIcon
		@type property
		@desc The unit's class icon
	]======]

	CLASS_ICON_TCOORDS = CopyTable(_G.CLASS_ICON_TCOORDS)

	------------------------------------------------------
	-- Script
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	doc [======[
		@name Refresh
		@type method
		@desc Refresh the unit's class icon
		@return nil
	]======]
	function Refresh(self)
		local cls = self.Unit and (select(2, UnitClassBase(self.Unit)))
		if cls then
			self.Alpha = 1
			self:SetTexCoord(unpack(CLASS_ICON_TCOORDS[cls]))
		else
			self.Alpha = 0
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function ClassIcon(self)
		self.TexturePath = [[Interface\TargetingFrame\UI-Classes-Circles]]
		self.Height = 16
		self.Width = 16
	end
endclass "ClassIcon"