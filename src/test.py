from rotating_file_handler import RotatingLogFileHandler
from tempfile import TemporaryDirectory
from os import listdir
from logging import getLogger, DEBUG, WARNING, Formatter


class DummyRecord:
    def __init__(self, message: str, levelno=DEBUG):
        self.message = message
        self.levelno = levelno


class DummyFormatter:
    @staticmethod
    def format(record):
        return record.message


def test_overrides_current_log_file_when_number_of_backup_files_is_set_to_zero():
    with TemporaryDirectory() as temp_dir:
        log_file_name = f"{temp_dir}/test.log"

        handler = RotatingLogFileHandler(log_file_name, 10, 0)
        handler.setFormatter(DummyFormatter())

        handler.emit(DummyRecord("msg1"))
        handler.emit(DummyRecord("msg2"))
        handler.emit(DummyRecord("msg3"))
        handler.close()

        assert listdir(temp_dir) == ["test.log"]
        assert open(log_file_name).read() == "msg3\n"


def test_rotates_correctly():
    with TemporaryDirectory() as temp_dir:
        log_file_name = f"{temp_dir}/test.log"

        handler = RotatingLogFileHandler(log_file_name, 20, 2)
        handler.setFormatter(DummyFormatter())

        for i in range(1, 20):
            handler.emit(DummyRecord(f"msg{i}"))
        handler.close()

        assert listdir(temp_dir) == ["test.log", "test.log.1", "test.log.2"]
        assert open(log_file_name).read() == "msg18\nmsg19\n"


def test_integration_with_logging_framework():
    with TemporaryDirectory() as temp_dir:
        log_file_name = f"{temp_dir}/test.log"

        handler = RotatingLogFileHandler(log_file_name, 20, 2)
        formatter = Formatter("%(message)s")
        handler.setFormatter(formatter)
        logger = getLogger("test_logger")
        logger.addHandler(handler)
        logger.setLevel(DEBUG)

        for i in range(1, 20):
            logger.info(f"msg{i}")

        handler.close()

        assert listdir(temp_dir) == ["test.log", "test.log.1", "test.log.2"]
        assert open(log_file_name).read() == "msg18\nmsg19\n"
