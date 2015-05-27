
import tornado.web, tornado.wsgi, os
from tornado.ioloop import IOLoop

from app.appfactory import AppFactory
from app.computer.websocket import CheckinHandler

# Set up the environment.
os.environ['FLASK_CONFIG']   = 'app.settings.DevelopmentConfig'
os.environ['LOGGING_CONFIG'] = '/vagrant/terrapin_server/config/logging.yaml'

FlaskApp = AppFactory()()
wsgi_app = tornado.wsgi.WSGIContainer(FlaskApp)

application = tornado.web.Application([
	(r'/checkin/stream', CheckinHandler),
	(r'.*', tornado.web.FallbackHandler, { 'fallback': wsgi_app }),
], debug = True)

if __name__ == '__main__':
	application.listen(8100, address = '0.0.0.0')
	IOLoop.instance().start()
