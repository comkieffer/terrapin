
Feature: As the service owner,
	I want to allow my users to send checkin messages

	Scenario: Successful Checkin
		Given FlaskApp is setup
		Given "Sally" is a registered user

		When "Sally" makes a checkin with the following values:

		Then ???

	Scenario: Invalid API Token
		Given FlaskApp is setup
		Given "Sally" is a registered user

		When "Sally" makes a checkin with the following values:

		Then ??
