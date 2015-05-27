
from urllib.parse import urlparse


from behave import *
from flask  import url_for

from app             import db
from app.auth.models import User

@given('FlaskApp is setup')
def is_flaskapp_setup(context):
	""" Make sure that we have a context and a user """
	assert context.client


@given('"{username}" is a registered user')
def register(context, username):
	if not User.query.filter_by(user_name = username).first():
		new_user = User(username, username + '@example.com', 'password')
		db.session.add(new_user)
		db.session.commit()

	assert User.query.filter_by(user_name = username).first()


@given('"{username}" is not a registered user')
def is_not_registered(context, username):
	assert not User.query.filter_by(user_name = username).first()


@when('I log in with "{username}" and "{password}"')
def login(context, username, password):
	context.response = context.client.post(
		url_for('LoginView:post'), data = dict(
			csrf_token = 'disabled',
			user_name   = username,
			password    = password,
			remember_me = False,
		), follow_redirects = False
	)

	assert context.response


@when('I create an account for "{username}" with "{email}" and "{password}"')
def signup(context, username, email, password):
	context.response = context.client.post(
		url_for('LoginView:post'), data = dict(
			user_name        = username,
			password         = password,
			password_confirm = password,
			email            = email
		), follow_redirects = False
	)


@then('I should be redirected to "{view}"')
def is_correct_redirect(context, view):
	url_path = urlparse(context.response.location).path

	assert context.response.status_code == 302
	assert url_path == url_for(view)


@then('I should not be redirected')
def is_not_redirect(context):
	assert context.response.status_code == 200


@then('"{username}" should be a registered user')
def is_registered(context, username):
	assert User.query.filter_by(user_name = username).first()
