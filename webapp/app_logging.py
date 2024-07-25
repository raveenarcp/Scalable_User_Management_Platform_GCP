import os
import logging
from logging.handlers import WatchedFileHandler
from pythonjsonlogger import jsonlogger
from dotenv import load_dotenv
from logging import Formatter
import datetime
import pytz 


load_dotenv()
class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super(CustomJsonFormatter, self).add_fields(log_record, record, message_dict)
        log_record['asctime'] = self.format_timestamp(record.created)
        log_record['levelname'] = record.levelname
        log_record['threadName'] = record.threadName
        log_record['thread'] = record.thread
        log_record['process'] = record.process
        log_record['processName'] = record.processName
        log_record['module'] = record.module
        log_record['funcName'] = record.funcName
        log_record['pathname'] = record.pathname
        log_record['lineno'] = record.lineno
        log_record['filename'] = record.filename

    def format_timestamp(self, created):
        tz = pytz.timezone('UTC')  
        timestamp = datetime.datetime.fromtimestamp(created, tz=tz)
        return timestamp.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]



app_log_file = os.getenv("APP_LOG_FILE",'/opt/webapp/app_log_file.log')
app_file_handler = WatchedFileHandler(app_log_file)
formatter = CustomJsonFormatter(fmt='%(asctime)s - %(name)s - %(levelname)s - %(message)s %(threadName)s %(thread)s %(process)s %(processName)s %(module)s %(funcName)s %(pathname)s %(lineno)s %(filename)s')
app_file_handler.setFormatter(formatter)
app_log = logging.getLogger()
app_log.setLevel(logging.DEBUG)  
app_log.addHandler(app_file_handler)