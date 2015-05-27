
from flask import jsonify

from .views import api
from ..models import Computer, World

@api.route('/worlds')
def worlds():
	worlds = Computer.query            \
		.group_by(Computer.world_name) \
		.distinct(Computer.world_name) \
		.all()

	worlds = [World(checkin.world_name) for checkin in worlds]

	return jsonify({ 'data': worlds})

@api.route('/world/<string:world_name>')
def world(world_name):
	return jsonify({ 'data': World(world_name)})