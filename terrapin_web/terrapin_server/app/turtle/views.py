import logging

from flask import Blueprint, request, render_template
from sqlalchemy import desc
from datetime import datetime, timedelta

from app     import db
from .models import TurtleCheckin

turtle = Blueprint('turtle', __name__)

@turtle.route('/')
def index():
	"""
	The main index view
	"""
	cutoff_time = datetime.now() - timedelta(minutes = 5)
	return render_template('turtle/index.html',
		recent_checkins = TurtleCheckin.query \
			.filter(TurtleCheckin.created_at >= cutoff_time) \
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
