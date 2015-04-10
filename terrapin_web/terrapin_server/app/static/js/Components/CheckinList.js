
var CheckinList = React.createClass({
  getInitialState: function() {
    return { checkins: [] }
  },

  componentDidMount: function() {
    document.addEventListner('CheckinStore:new', function(event){ 
      self.setState({
        checkins: self.state.checkins.concat($.parseJSON(event.detail))
      });
  },});

  render: function() {
    var checkins = this.state.checkins.map(function(item) {
      return (
        <Checkin key={item.id} checkin={item} />
      );
    });

    return (
      <div className = "checkin-list">
        {checkins}
      </div>
    );
  }
});