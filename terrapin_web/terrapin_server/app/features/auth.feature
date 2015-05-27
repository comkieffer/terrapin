
Feature: As the website owner,
	I want to secure my website

	Scenario: Successful login
		Given FlaskApp is setup
		Given "Sally" is a registered user

		When I log in with "Sally" and "password"
		Then I should be redirected to "IndexView:index"

	Scenario: Wrong Password
		Given FlaskApp is setup
		Given "Sally" is a registered user

		When I log in with "Sally" and "worng_password"
		Then I should not be redirected

	Scenario: Wrong Username
		Given FlaskApp is setup
		Given "NotSally" is not a registered user

		When I log in with "NotSally" and "password"
		Then I should not be redirected

	Scenario: Successful Account Creation
		Given FlaskApp is setup
		Given "Sally" is a registered user
		Given "NotSally" is not a registered user

		When I create an account for "NotSally" with "sally@example.com" and "password"
		Then "NotSally" should be a registered user
		Then I should be redirected to "IndexView:index"

	Scenario: Cannot Create 2 Accounts with the same username
		Given FlaskApp is setup
		Given "Sally" is a registered user

		When I create an account for "Sally" with "sally@example.com" and "password"
		Then I should not be redirected

	Scenario: Cannot Create 2 Accounts with the same email
		Given FlaskApp is setup
		Given "Sally" is a registered user

		When I create an account for "Sally" with "sally@example.com" and "password"
		Then I should not be redirected
