
from behave import *
from app.template_filters import tick2mctime

@given('{tick} is a positive integer')
def is_positive_in(context, tick):
	tick = int(tick) # Make sure that we can convert tick to int.
	assert tick >= 0

@then("the conversion from {tick} to minecraft time should be {mctime}")
def test_tick2mctime(context, tick, mctime):
	assert tick2mctime(int(tick)) == mctime
