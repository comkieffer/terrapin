
import logging
logger = logging.getLogger(__name__)

from flask            import request
from flask.ext.classy import FlaskView

from app import db
from app.auth.models import User

from ..utils   import validateCheckin
from ..models  import ComputerCheckin, MissingWorldError

class CheckinView(FlaskView):
	route_prefix = '/api'

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

		user = User.query.filter_by(
			api_token = request.values.get('api_token')
		).first()
		if not user:
			abort(403)

		try:
			checkin = ComputerCheckin(request.values)

			db.session.add(checkin)
			db.session.commit()
		except MissingWorldError as Ex:
			logger.error(Ex)

		logger.info(
			'Recevied checkin from %s for world "%s" by computer %s',
			user, request.values.get('world_name'), request.values.get('computer_id')
		)

		return 'OK'
