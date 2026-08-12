@tool
extends ScriptCommand
class_name ScriptCmdWeather

@export var weather: WeatherEffect.WeatherID = WeatherEffect.WeatherID.WEATHER_NONE

func execute(context: ScriptExecutionContext) -> bool:
	if context.map is MapAttributes:
		(context.map as MapAttributes).weather = weather
	WeatherManager.set_weather(weather)
	return true
