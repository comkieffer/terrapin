
from .utils import getWorldsInfo

def inject_worlds_list():
	return { '_worlds': getWorldsInfo() }