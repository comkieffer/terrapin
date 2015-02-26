
import tornado.web, tornado.wsgi
from tornado.ioloop import IOLoop

from app.create_app import create_app
from app.computer.websocket import CheckinHandler

wsgi_app = tornado.wsgi.WSGIContainer(
	create_app(
		'/vagrant/terrapin_server/config/dev.cfg',
		'/vagrant/terrapin_server/config/logging.yaml'
	)
)

application = tornado.web.Application([
	(r'/checkin/stream', CheckinHandler),
	(r'.*', tornado.web.FallbackHandler, { 'fallback': wsgi_app }),
])

if __name__ == '__main__':
	application.listen(8100, address = '0.0.0.0')
	IOLoop.instance().start()
