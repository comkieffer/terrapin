
var CheckinList = React.createClass({
  getInitialState: function() {
    return { checkins: [] }
  },

  componentDidMount: function() {
    var self = this;

    document.addEventListener('CheckinSource:new', function(event){ 
      checkin = event.detail.data;
      checkin_data = $.parseJSON(checkin);

      // Filter the checkins.
      // The final !world_name makes the filter only aply if world_name is set
      var world_name = self.props.world_name;
      if ((world_name && checkin_data.world_name == world_name) || !world_name) {
        self.setState({
          checkins: self.state.checkins.concat(checkin_data)
        });
      }
    });
  },

  render: function() {
    var checkins = this.state.checkins.map(function(item) {
      return (
        <Checkin key={item.id} checkin={item} />
      );
    });

    return (
      <div className = "checkin-list" world_name = {document.globals.world_name}>
        {checkins}
      </div>
    );
  }
});