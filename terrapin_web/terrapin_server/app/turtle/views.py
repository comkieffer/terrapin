import logging

from flask import Blueprint, request, render_template
from sqlalchemy import desc
from datetime import datetime, timedelta

from app     import db
from .models import TurtleCheckin

turtle = Blueprint('turtle', __name__)

def recentCheckinsSortedByComputerId():
	cutoff_time = datetime.now() - timedelta(minutes = 50)

	# For testing purposes get rid of the cutoff
	# recent_checkins = TurtleCheckin.query \
	# 		.filter(TurtleCheckin.created_at >= cutoff_time) \
	# 		.order_by(desc(TurtleCheckin.created_at))

	recent_checkins = TurtleCheckin.query \
		.order_by(desc(TurtleCheckin.created_at)) \
		.limit(50)

	turtle_ids = set([checkin.turtle_id for checkin in recent_checkins])
	turtle_ids = list(turtle_ids)

	turtle_checkins = []
	for turtle_id in turtle_ids:
		turtle_checkins.append(
			[checkin for checkin in recent_checkins if checkin.turtle_id == turtle_id]
		)

	return turtle_checkins

@turtle.route('/')
def index():
	"""
	The main index view
	"""

	turtle_checkins = recentCheckinsSortedByComputerId()
	return render_template('turtle/index.html',
		turtle_checkins = turtle_checkins
	)

@turtle.route('/dashboard')
def dashboard():
	recent_checkins = recentCheckinsSortedByComputerId()
	last_checkins = []

	for checkins in recent_checkins:
		last_checkins.append(checkins[0])

	return render_template('turtle/dash.html', computers = last_checkins)

@turtle.route('/turtle/<id>')
def view_turtle(id):
	return render_template('turtle/raw.html',
		checkins = TurtleCheckin.query \
			.filter(TurtleCheckin.turtle_id == id) \
			.order_by(desc(TurtleCheckin.created_at))
	)

@turtle.route('/raw')
def raw_data():
	return render_template('turtle/raw.html',
		autorefresh = True,
		checkins = TurtleCheckin.query.order_by(desc(TurtleCheckin.created_at))
	)



@turtle.route('/checkin', methods = ['POST'])
def checkin():
	"""
	Checkin the turtle.

	The data passed in the POST request will be saved to the database for
	safe-keeping

	The required post data is :

		turtle_id
		turtle_name (if set)
		current_fuel_level
	"""

	logger = logging.getLogger(__name__)
	logger.info('Received POST data from source : {}'.format(request.values))

	checkin = TurtleCheckin(request.values)

	db.session.add(checkin)
	db.session.commit()

	return 'OK'
