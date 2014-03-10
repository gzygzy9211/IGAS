-- Author      : Kurapica
-- Create Date : 2012/11/20
-- Change Log  :

-- Check Version
local version = 3
if not IGAS:NewAddon("IGAS.Widget.Unit.StatusText", version) then
	return
end

__Doc__[[The fontstring used to display status value]]
class "StatusText"
	inherit "FontString"

	abs = math.abs

	local function formatValue(self, value)
		if abs(value) >= 10^9 then
			return self.ValueFormat:format(value / 10^9) .. "b"
		elseif abs(value) >= 10^6 then
			return self.ValueFormat:format(value / 10^6) .. "m"
		elseif abs(value) >= 10^4 then
			return self.ValueFormat:format(value / 10^3) .. "k"
		else
			return tostring(value)
		end
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	__Doc__[[Refresh the status, overridable]]
	function RefreshStatus(self)
		if self.__Value then
			if self.__ShowPercent and self.__Max then
				if self.__Max > 0 then
					if self.__Value > self.__Max then
						self.Text = self.PercentFormat:format(100)
					else
						self.Text = self.PercentFormat:format(self.__Value * 100 / self.__Max)
					end
				else
					self.Text = self.PercentFormat:format(0)
				end
			elseif self.ShowLost and self.__Max then
				self.Text = formatValue(self, self.__Value - self.__Max)
			elseif self.ShowMax and self.__Max then
				self.Text = self.MaxFormat:format(formatValue(self, self.__Value), formatValue(self, self.__Max))
			else
				self.Text = formatValue(self, self.__Value)
			end

			if self.Text == "0" then
				self.Text = " "
			end
		else
			self.Text = " "
		end
	end

	__Doc__[[
		<desc>Sets the value of the fontstring</desc>
		<param name="value">number, the value</param>
		]]
	function SetValue(self, value)
		if type(value) == "number" and value >= 0 then
			self.__Value = value
			return self:RefreshStatus()
		end
	end

	__Doc__[[
		<desc>Gets the value of the fontstring</desc>
		<return type="number"></return>
	]]
	function GetValue(self)
		return self.__Value or 0
	end

	__Doc__[[
		<desc>Sets the minimum and maximum values for the fontstring</desc>
		<param name="min">number, lower boundary for the values</param>
		<param name="max">number, upper boundary for the values</param>
		]]
	function SetMinMaxValues(self, min, max)
		self.__Min, self.__Max = min, max
		return self:RefreshStatus()
	end

	__Doc__[[
		<desc>Gets the minimum and maximum values</desc>
		<return type="min">number, the lower boundary for the values</return>
		<return type="max">number, the upper boundary for the values</return>
	]]
	function GetMinMaxValues(self)
		return self.__Min, self.__Max
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The display value format, default "%.2f"]]
	property "ValueFormat" {
		Get = function(self)
			return self.__ValueFormat or "%.2f"
		end,
		Set = function(self, value)
			self.__ValueFormat = value
		end,
		Type = System.String + nil,
	}

	__Doc__[[The minimum and maximum values]]
	property "MinMaxValue" {
		Get = function(self)
			return MinMax(self:GetMinMaxValues())
		end,
		Set = function(self, value)
			self:SetMinMaxValues(value.min, value.max)
		end,
		Type = System.MinMax,
	}

	__Doc__[[The fontstring's value]]
	property "Value" {
		Get = function(self)
			return self:GetValue()
		end,
		Set = function(self, value)
			self:SetValue(value)
		end,
		Type = System.Number,
	}

	__Doc__[[Whether show lost value]]
	property "ShowLost" {
		Get = function(self)
			return self.__ShowLost
		end,
		Set = function(self, value)
			if self.__ShowLost ~= value then
				self.__ShowLost = value
				return self:RefreshStatus()
			end
		end,
		Type = System.Boolean,
	}

	__Doc__[[Whether show the max value]]
	property "ShowMax" {
		Get = function(self)
			return self.__ShowMax
		end,
		Set = function(self, value)
			if self.__ShowMax ~= value then
				self.__ShowMax = value
				return self:RefreshStatus()
			end
		end,
		Type = System.Boolean,
	}

	__Doc__[[The display format when ShowMax is true, default "%s / %s"]]
	property "MaxFormat" {
		Get = function(self)
			return self.__MaxFormat or "%s / %s"
		end,
		Set = function(self, value)
			self.__MaxFormat = value
		end,
		Type = System.String + nil,
	}

	__Doc__[[Whether show percent format]]
	property "ShowPercent" {
		Get = function(self)
			return self.__ShowPercent
		end,
		Set = function(self, value)
			if self.__ShowPercent ~= value then
				self.__ShowPercent = value
				return self:RefreshStatus()
			end
		end,
		Type = System.Boolean,
	}

	__Doc__[[The display format when ShowPercent is true, default "%d%%"]]
	property "PercentFormat" {
		Get = function(self)
			return self.__PercentFormat or "%d%%"
		end,
		Set = function(self, value)
			self.__PercentFormat = value
		end,
		Type = System.String + nil,
	}

	function StatusText(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.FontObject = IGAS.TextStatusBarText
	end
endclass "StatusText"

__Doc__[[The status text for health]]
class "HealthText"
	inherit "StatusText"
	extend "IFHealth"
endclass "HealthText"

__Doc__[[The status text for frequent health]]
class "HealthTextFrequent"
	inherit "StatusText"
	extend "IFHealthFrequent"
endclass "HealthTextFrequent"

__Doc__[[The status text for power]]
class "PowerText"
	inherit "StatusText"
	extend "IFPower"
endclass "PowerText"

__Doc__[[The status text for frequent power]]
class "PowerTextFrequent"
	inherit "StatusText"
	extend "IFPowerFrequent"
endclass "PowerTextFrequent"