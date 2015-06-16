
var CheckinSource = {
	checkins    : {},
	is_connected: false,
	listen_url: 'ws://localhost:8100/checkin/stream/?',

	listen: function(world_id, computer_id) {
		var self = this;

		if (self.is_connected) {
			console.info('Already listening for changes')
			return
		}


		var url = self.listen_url + $.param([
			{name: 'world_id', value: world_id},
			{name: 'computer_id', value: computer_id}
		]);


		console.info('Starting CheckinSource Listener ...');
		console.info('Listening on:', url);

		var CheckinSocket = new WebSocket(url);

		CheckinSocket.onmessage = function(message) {
			message = JSON.parse(message.data); // Keep only the actual message data
			// console.log('Checkin source revceived checkin: ', message);

			if(message['error']){
				console.error('Checkin Error: ', message['error']);
				return;
			}

			var event = new CustomEvent('CheckinSource:new',
				{ 'detail':  message['data']});
			document.dispatchEvent(event);
		};
	},
};
