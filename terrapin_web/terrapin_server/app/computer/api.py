import logging

from flask import Blueprint, jsonify
from sqlalchemy import desc

from .models import ComputerCheckin

api = Blueprint('api', __name__)

def recentCheckinsSortedByComputerId():
	recent_checkins = ComputerCheckin.query \
		.order_by(desc(ComputerCheckin.created_at)) \
		.limit(50)

	# Make a list contining the unique turtle ids
	turtle_ids = set([checkin.turtle_id for checkin in recent_checkins])
	turtle_ids = list(turtle_ids)

	# sort the checkins by turtle id
	turtle_checkins = []
	for turtle_id in turtle_ids:
		turtle_checkins.append(
			[checkin for checkin in recent_checkins if checkin.turtle_id == turtle_id]
		)

	return turtle_checkins

@api.route('/computer/all')
def all_computers():
	checkins = recentCheckinsSortedByComputerId()

	computers = []
	for checkins in checkins:
		computers.append(checkins[0])

	return jsonify({'data': [computer.__json__() for computer in computers]})
