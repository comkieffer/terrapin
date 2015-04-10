
var CheckinStore = {
	checkins    : {},
	is_connected: false,

	listen: function() {}
		var self = this;

		if (self.is_connected) {
			console.info('Already listening for changes')
			return
		}

		console.info('Starting CheckinStore Listner ...');
		console.info('Listening on: ws://localhost:8100/checkin/stream');

		var CheckinSocket = new WebSocket('ws://localhost:8100/checkin/stream');

		CheckinSocket.onmessage = function(message) {
			console.info('CheckinStore:listen - New Message');

			var event = new CustomEvent('CheckinStore:new', { 'detail':  message});
			elem.dispatchEvent(event);
		};
	},	
};
