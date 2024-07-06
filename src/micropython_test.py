import logging
from rotating_file_handler import RotatingLogFileHandler

handler = RotatingLogFileHandler("test.log", 20, 2)
handler.setFormatter(logging.Formatter("%(message)s"))
handler.setLevel(logging.DEBUG)
record = logging.LogRecord()

for i in range(1, 20):
    record.set("test_logger", logging.DEBUG, "msg1")
    handler.emit(record)
