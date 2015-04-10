
(function() {

	var Computer = React.createClass({
		render: function() {
			var self = this;
			var checkin = self.props.checkin

			// console.log('@Computer.render: checkin =>', checkin)

			var fuel_progress_style = {
				width: checkin.fuel_level / 16000 + '%'
			}

			return (
				<div className = 'computer-detail col-sm-6'>
					<div className = 'panel panel-info'>
						<div className = 'panel-heading'>
							{checkin.computer_name} (Id: {checkin.computer_id})
						</div>

						<div className = 'panel-body'>
							<div className = 'row'>
								<div className = 'computer-icon col-sm-4'>
									<img
										className = "pull-left"
										src = "/static/img/adv-computer.png"
									/>
								</div>

								<div className = 'computer-details col-sm-8'>
									<h5>Current Task: {checkin.current_task}</h5>

									<h6>Fuel Level: {checkin.fuel_level} units</h6>
									<div className = 'progress'>
										<div
											className = 'progress-bar progress-bar-info'
											style = {fuel_progress_style}
										></div>
									</div>
									<h6>Position (Relative):
										(
											x = {checkin.pos_x},
											z = {checkin.pos_z},
											y = {checkin.pos_y}
										)
									</h6>
								</div>
							</div>
						</div>

						<table className = 'table-condensed'>
							<tr>
								<td>Last Status</td>
								<td>{checkin.status}</td>
							</tr>
						</table>
					</div>
				</div>
			);
		}
	});

 	var Dashboard = React.createClass({
 		getInitialState: function() {
 			return { computers: [] };
 		},

 		componentDidMount: function() {
 			var self = this;

 			$.getJSON('/api/world/Testing/computers', function(data) {
 				// console.log('@componentDidMount: /api/computers =>', data['data'] )
 				self.setState({ computers: data['data'] });
 			});
 		},

 		render: function() {
 			// console.log('@render: state =>', this.state)
 			var computers = this.state.computers.map(function(computer) {
 				return <Computer key = {computer.id} checkin = {computer} />;
 			});

 			return (
 				<section className = 'dashboard'>
 					{computers}
 				</section>
 			);
 		}
	});

	React.render(
		<Dashboard />,
		document.getElementById("content")
	);
})();
