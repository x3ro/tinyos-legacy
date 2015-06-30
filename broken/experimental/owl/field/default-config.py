from pickle import *
from config import Config

cf = open("field.config", "w+")
dump(Config(), cf)
