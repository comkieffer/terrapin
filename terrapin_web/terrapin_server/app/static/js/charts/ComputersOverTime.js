
/*
 *	Display the evolution over time of the number of computers in the world.
 */


var ComputersOverTimeChart = {
	endpoint: '/api/world/<world_name>/';

	render: function() {
		var self = this;

		self.data = self.getData();
	}

	getData: function() {
		var data = $.getJSON(endpoint).then(make_chart);
		// Handle error.

		return data;
	}

	wrangleData: function(data) {
		var wrangled_data = [];

		return wrangled_data;
	}

	renderChart: function() {

		return;
	}
};

