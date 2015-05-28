
from flask            import request
from flask.ext.classy import FlaskView

from app import db

from ..utils   import validateCheckin
from ..models  import ComputerCheckin
from ..signals import NewCheckinReceived

class CheckinView(FlaskView):

	def post(self):
		"""
		Checkin the computer.

		The data passed in the POST request will be saved to the database for
		safe-keeping

		The required post data is :

			computer_id
			computer_name (if set)
			current_fuel_level
		"""

		# We should probably add some exception handling here ...
		validateCheckin(request.values)

		if not isValidateAPIToken():
			raise(Errror403) - Unauthorized

		checkin = ComputerCheckin(request.values)

		db.session.add(checkin)
		db.session.commit()
		NewCheckinReceived.send('checkin view', checkin = checkin)

		return 'OK'
