
from flask      import jsonify, request
from sqlalchemy import desc


from .views    import api
from ..queries import aggregatedComputerData
from ..models  import ComputerCheckin

# TODO: Secure the API views !!
# NOTE: THE API IS BROKEN AGAIN ....

@api.route('/world/<string:world_name>/computers')
def computers(world_name):
	raise RuntimeError('Do I need this ? The same data is alteady returned bu the /world/world_name call')


@api.route('/world/<string:world_name>/computer/<int:computer_id>')
def computer(world_name, computer_id):
	computer = computer_or_404(world_name, computer_id)
	computer.checkins = computer.checkins \
		.order_by(desc(ComputerCheckin.created_at)) \
		.limit(10) \
		.all()

	return jsonify({ 'data': computer })

# TODO: Fix pagination - Does it work ? Would we be better served by dumping it
#	all this code into a flask classy view ? Should we use a decorator ? Should
#	we try to create a generic pagiation facility for SQLAlchemy ?
@api.route('/world/<string:world_name>/computer/<int:computer_id>/checkins')
def checkins(world_name, computer_id):
	"""
	Fetch computer checkins.

	The interface allows for pagination using the the start and end query parameters. The maximum
	number of records that can be returned is determined by the MAX_RECORDS_PER_PAGE config option
	in settings.py.
	If the number of requested records is invalid then MAX_RECORDS_PER_PAGE records will be
	returned.

	LIMITATIONS:

	Since the retrieval is implemented using an offset if new checkins are added the counts will be
	false and results that have already been produced will be returned. A better option might be to
	specify the last known checkin id and calculating based on that.

	"""

	# Make sure the comuter exists
	computer_or_404(world_name, computer_id)

	computer_query = ComputerCheckin.query    \
		.filter_by(world_name = world_name)   \
		.filter_by(computer_id = computer_id) \

	if request.args['start']:
		if request.args['end']:
			num_records = request.args['end'] - request.args['start']
			max_records = current_app.config['MAX_RECORDS_PER_PAGE']

			if num_records > max_records:
				logger.info(
					'Query is requesting %d results but the maximum number of results a query can '
					'return at once is %s',
					num_records, max_records
				)

				num_records = max_records

		computer_query = computer_query    \
			.offset(request.args['start']) \
			.limit(num_records)

	return jsonify({
		'data': computer_query.all(),
		'next': url_for('computer.checkins'),
		'prev': url_for('computer.checkins')
	})


@api.route('/world/<string:world_name>/computer/<int:computer_id>/hist')
def fuel(world_name, computer_id):
	"""
	This view should not really exist. Unfortuantely sending all the checkins
	ever erformed by a computer to the client every time we want to display the
	fuel graph is not the best idea.
	"""

	return jsonify({
		'data': aggregatedComputerData	(computer_id, current_user)
	})
