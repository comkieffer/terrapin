# We declare the application-level globals here to make them accessible
# without hassle everywhere

# SQLAlchemy db wrapper
from flask.ext.sqlalchemy import SQLAlchemy
db = SQLAlchemy()

from flask.ext.login import LoginManager
login_manager = LoginManager()
