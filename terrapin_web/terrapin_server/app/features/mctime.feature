
Feature: As the website owner,
	I wanto to make sure that the mcTime tempalte filter works.

	Scenario Outline: Test mcTime
		Given <Tick> is a positive integer
		 Then the conversion from <Tick> to minecraft time should be <Time>

	  Examples: Conversions
		| Tick	| Time 							|
		| 0		| 0 days 						|
		| 1000 	| 1 hour 						|
		| 2000 	| 2 hours 						|
		| 24000 | 1 day 						|
		| 25000 | 1 day, 1 hour 				|
		| 26000 | 1 day, 2 hours 				|
		| 48000 | 2 days 						|
		| 49000 | 2 days, 1 hour 				|
		| 50000 | 2 days, 2 hours 				|
		| 50100 | 2 days, 2 hours, 1 minute 	|
		| 50200 | 2 days, 2 hours, 2 minutes 	|
		| 50257 | 2 days, 2 hours, 2 minutes 	|
