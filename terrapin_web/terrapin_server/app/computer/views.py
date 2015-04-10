import logging

from flask import Blueprint, render_template
from sqlalchemy import desc
from datetime import datetime, timedelta

from app      import db
from .models  import ComputerCheckin
from .utils   import *

computer = Blueprint('computer', __name__)


@computer.route('/')
@computer.route('/index')
def index():
	# Deends on the injected variable _worlds 
	return render_template('computer/worlds.html')


@computer.route('/world/<string:world_name>')
def world_properties(world_name):
	return render_template('computer/world.html',
		world_name = world_name,
		computers = getComputers(world_name)
	)


@computer.route('/world/<string:world_name>/dashboard')
def dashboard(world_name):
	return render_template('computer/dash.html', computers = getComputers())


@computer.route('/world/<string:world_name>/computer/<computer_id>')
def view_computer(world_name, computer_id):
	return render_template('computer/computer.html',
		checkins = ComputerCheckin.query                        \
			.filter(ComputerCheckin.world_name == world_name)   \
			.filter(ComputerCheckin.computer_id == computer_id) \
			.order_by(desc(ComputerCheckin.created_at))
	)
