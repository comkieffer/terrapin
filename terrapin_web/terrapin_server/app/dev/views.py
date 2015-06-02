import logging

from flask import Blueprint, request, render_template

from app                  import db
from app.computer.models  import ComputerCheckin

from .url_map import url_map as gen_url_map


dev = Blueprint('dev', __name__)

@dev.route('/mk_checkins')
def mk_checkins():
	return render_template('dev/make_checkins.html')



@dev.route('/stream')
def checkinStream():
	return render_template('dev/stream.html')


@dev.route('/url_map')
def url_map():
	"""
	Inject a flattened url_map into the app that is then added to the page
	javascript so that they can use the endpoint names to generate urls.
	"""

	return render_template('/dev/url_map.html', urls = gen_url_map())
