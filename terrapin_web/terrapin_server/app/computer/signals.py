
from blinker import signal

NewCheckinReceived = signal('A new checkin has been received')

NewDeviceSeen = signal('A new device has been seen for the first time')
