
from collections import namedtuple

from flask       import request, render_template_string

from .models     import Computer, ComputerCheckin

# Unused ... I shoudl do some error checking ...
class InvalidWorldName(Exception):
	pass


def validateCheckin(data):
	"""
	Validate the data received for a checkin. Here we check that the required fields are set and
	that the fields have the correct types.


	We need to do this werkzeug mangles the KeyError exception produced by the MultiMap when we
	access a missing key. The KeyError is transformed into a RequestError but the RequestError
	exception class a default, non overidable error message. This means that it is hard to identify
	which keys are causing the error.

	:param:MultiMap:data: The form object from request.form
	"""
	Field = namedtuple('Field', ['name', 'type', 'required'])

	fields = [
		Field('api_token'        , str   , True),
		Field('world_name'       , str   , True),
		Field('world_ticks'      , int   , True),
		Field('computer_id'      , int   , True),
		Field('computer_name'    , str   , True),
		Field('type'             , str   , True),
		Field('task'             , str   , True),
		Field('status'           , str   , True),

		Field('abs_pos_x'        , float , False),
		Field('abs_pos_y'        , float , False),
		Field('abs_pos_z'        , float , False),
		Field('rel_pos_x'        , float , False),
		Field('rel_pos_y'        , float , False),
		Field('rel_pos_z'        , float , False),
		Field('fuel'             , int   , False),
		Field('total_blocks_dug' , int   , False),
		Field('total_moves'      , int   , False),
	]

	for field in fields:
		if field.required and not data.get(field.name):
			raise KeyError(field.name)

		# TODO: This will return false almost always. We need to check whether the type can be converted !
		# if not isinstance(data[field.name], field.type):
		# 	raise TypeError(
		# 		'Expected {} for {}. Type was {}'.format(
		# 			field.type, field.name, type(data[field.name])
		# 		))


def makeCheckinConfig(world_name, user = None):
	checkin_cfg_tpl = (
		"return  {                               \n"
		"	['World Name'] = '{{ world_name }}', \n"
		"	['Server URL'] = '{{ server_url }}', \n"
		"	['API Token']  = '{{ api_token }}',  \n"
		"}                                       \n"
	)

	user = user if user else current_user

	return render_template_string(checkin_cfg_tpl,
		world_name = world_name, server_url = request.host,
		api_token = user.api_token
	)
