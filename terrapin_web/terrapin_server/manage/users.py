
from faker            import Faker
from flask.ext.script import Manager, prompt_bool

from app              import db
from app.auth.models  import User


user_manager = Manager(usage='Create and delete users')

# Add help= ? params
@user_manager.option('-p', '--password', dest='password', required=False)
def make_admin(password = 'password'):
	admin = User('Admin', 'admin@example.com', password)

	db.session.add(admin)
	db.session.commit()

	if password is 'password':
		print(
			'\n====\nThis admin account is using the default password. Do not use it '
			'in production before changing the password\n====\n'
		)

	print('Admin user created')


@user_manager.command
def make_users():
	fake = Faker()
	fake.seed(40786)

	make_admin() # Create the admin user

	for _ in range(1, 10):
		profile = fake.profile(fields=['username', 'mail'])
		print('Creating a profile for {} ...'.format(profile['username']))

		user = User(profile['username'], profile['mail'], 'password')
		db.session.add(user)

	print()
	db.session.commit()
