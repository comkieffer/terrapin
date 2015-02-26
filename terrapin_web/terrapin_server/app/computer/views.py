import logging

from flask import Blueprint, request, render_template
from sqlalchemy import desc
from datetime import datetime, timedelta

from app      import db
from .models  import ComputerCheckin
from .signals import new_checkin_received

computer = Blueprint('computer', __name__)

def recentCheckinsSortedByComputerId():
	cutoff_time = datetime.now() - timedelta(minutes = 50)

	# For testing purposes get rid of the cutoff
	# recent_checkins = ComputerCheckin.query \
	# 		.filter(ComputerCheckin.created_at >= cutoff_time) \
	# 		.order_by(desc(TurtleCheckin.created_at))

	recent_checkins = ComputerCheckin.query \
		.order_by(desc(ComputerCheckin.created_at)) \
		.limit(50)

	computer_ids = set([checkin.computer_id for checkin in recent_checkins])
	computer_ids = list(computer_ids)

	computer_checkins = []
	for computer_id in computer_ids:
		computer_checkins.append(
			[checkin for checkin in recent_checkins if checkin.computer_id == computer_id]
		)

	return computer_checkins

@computer.route('/')
def index():
	"""
	The main index view
	"""

	computer_checkins = recentCheckinsSortedByComputerId()
	return render_template('computer/index.html',
		computer_checkins = computer_checkins
	)

@computer.route('/dashboard')
def dashboard():
	recent_checkins = recentCheckinsSortedByComputerId()
	last_checkins = []

	for checkins in recent_checkins:
		last_checkins.append(checkins[0])

	return render_template('computer/dash.html', computers = last_checkins)

@computer.route('/computer/<id>')
def view_computer(id):
	return render_template('computer/raw.html',
		checkins = ComputerCheckin.query \
			.filter(ComputerCheckin.computer_id == id) \
			.order_by(desc(ComputerCheckin.created_at))
	)

@computer.route('/raw')
def raw_data():
	return render_template('computer/raw.html',
		autorefresh = True,
		checkins = ComputerCheckin.query.order_by(desc(ComputerCheckin.created_at))
	)



@computer.route('/checkin', methods = ['POST'])
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
