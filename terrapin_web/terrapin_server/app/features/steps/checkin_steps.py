
from behave          import *

from app             import db
from app.auth.models import User

@given('The API Token for "{username}" is "{new_api_token}"')
def set_api_toekn(context, username, new_api_token):
	user = User.query.filter_by(user_name = username).first()
	assert user

	user.api_token = new_api_token
	db.session.commit()


@when("{user} makes a valid checkin with the following values")
def make_valid_checkin(context, user):
	assert False


@then('The database should contain "{count}" {table}')
def count_table(context, count, table):
	tables = {
		'User'            : User,
		'World'           : World,
		'Computer'        : Computer,
		'ComputerCheckin' : ComputerCheckin,
	}

	assert table in tables
	assert tables[tables].query.count() == count
