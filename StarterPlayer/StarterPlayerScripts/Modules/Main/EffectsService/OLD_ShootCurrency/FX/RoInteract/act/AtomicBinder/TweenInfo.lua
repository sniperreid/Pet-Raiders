return function(self, key, value, indentLevel)
	return self:SourceToBinder({
		Time = value.Time,
		EasingStyle = value.EasingStyle,
		EasingDirection = value.EasingDirection,
		RepeatCount = value.RepeatCount,
		Reverses = value.Reverses,
		DelayTime = value.DelayTime
	}, indentLevel + 1)
end