
(function() {

	var checkins_list = $('#generated-checkins');
	if (!checkins_list) 
		console.error('Unable to locate container for generated checkins');

	var worlds = ['Dev World 1', 'Dev World 2', 'Dev Wolrd 3'];
	var computers = [
		[1, 'Test Computer 01', 'Advanced Computer'],
		[2, 'Test Computer 02', 'Computer'],
		[3, 'Test Turtle 01',   'Advanced Turtle'],
		[4, 'Test Turtle 02',   'Turtle']
	];


	function checkin() {
		var this_world = worlds[Math.floor(Math.random() * worlds.length)];
		var this_computer = computers[Math.floor(Math.random() * computers.length)];
			

		var checkin_data = {
			world_name: this_world,
			world_ticks: (new Date).getTime(),

			computer_id: this_computer[0],
			computer_name: this_computer[1],
			computer_type: this_computer[2],

			type: 'checkin',
			task: 'Testing Checkins',
			status: 'This is a fake checkin message'
		}

		console.info('Sending new checkin ...', JSON.stringify(checkin_data, null, '\t'));

		$.post('/checkin', checkin_data);
		checkins_list.append('<tr><td>' + JSON.stringify(checkin_data, null, '\t') + '</td></tr>');
	};

	console.info('Setting checkin interval to 5s ...');
	window.setInterval(checkin, 5000);
})();