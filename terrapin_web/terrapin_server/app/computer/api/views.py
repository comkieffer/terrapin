import logging

from flask import Blueprint, jsonify, request
from sqlalchemy import desc, distinct

from app import db

from ..utils   import getComputers
from ..models  import ComputerCheckin
from ..signals import new_checkin_received

api = Blueprint('api', __name__)

@api.app_errorhandler(404)
def error_404(err):
	return jsonify({'error': 'URI Not Found'}), 404

@api.app_errorhandler(400)
def error_400(err):
	return jsonify({'error': err.get_description()}), 400


@api.route('/checkin', methods = ['POST'])
def checkin():
	"""
	Checkin the computer.

	The data passed in the POST request will be saved to the database for
	safe-keeping

	The required post data is :

		computer_id
		computer_name (if set)
		current_fuel_level
	"""

	checkin = ComputerCheckin(request.values)

	db.session.add(checkin)
	db.session.commit()
	new_checkin_received.send('checkin view', checkin = checkin)

	return 'OK'

@api.route('/world/<string:world_name>/computers')
def computers_in_world(world_name):
	return jsonify({ 'data': getComputers(world_name) })