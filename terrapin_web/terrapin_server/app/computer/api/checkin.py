
import logging
logger = logging.getLogger(__name__)

from flask            import request, make_response, jsonify
from flask.ext.classy import FlaskView

from app import db
from app.auth.models import User

from ..utils   import validateCheckin, CheckinValidationError
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
		user = User.query.filter_by(
			api_token = request.values.get('api_token')
		).first()
		if not user:
			return make_response(jsonify({'error': 'Invalid API Token'})), 403

		try:
			checkin_values = request.values.to_dict()
			logger.info('Got checkin: %s', str(checkin_values))

			try:
				validateCheckin(checkin_values)
			except CheckinValidationError as ex:
				return make_response(jsonify({ 'error': str(ex) })), 400

			checkin = ComputerCheckin(checkin_values)
			db.session.add(checkin)
			db.session.commit()
		except MissingWorldError as Ex:
			logger.error(Ex)

		logger.info(
			'Recevied checkin from %s for world "%s" by computer %s',
			user, request.values.get('world_name'), request.values.get('computer_id')
		)

		return 'OK'
