#!/usr/bin/env python

import time
from pms5003 import PMS5003, ReadTimeoutError
from bme280 import BME280
try:
    from smbus2 import SMBus
except ImportError:
    from smbus import SMBus

from pprint import pprint
import atexit
import datetime
import time
import json
import logging


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


class CachedWriter:

    _to_flush = []

    @classmethod
    def flush_all(cls):
        for writer in cls._to_flush:
            writer.flush()

    @property
    def first(self):
        return self.buffer[0]

    @property
    def last(self):
        if self.buffer:
            return self.buffer[-1]

    def __init__(self, path, flush_limit=100):
        self.path = path
        self.buffer = []
        self.flush_limit = flush_limit

        is_first_call = len(self.__class__._to_flush) == 0
        self.__class__._to_flush.append(self)
        if is_first_call:
            logger.info('registering atexit')
            atexit.register(self.__class__.flush_all)

    def append(self, data):
        self.buffer.append(data)
        if len(self.buffer) > self.flush_limit:
            self.flush()

    def flush(self):
        with open(self.path, 'a') as ofile:
            ofile.write('\n' + '\n'.join(
                json.dumps(rec) for rec in self.buffer))
            logger.info('flushed {} records to {}'.format(
                len(self.buffer),
                self.path,
            ))
            self.buffer = []


def parse_pms(text):
    out = {}
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        name, value = line.strip().split(':')
        out[name] = int(value)
    return out


# particulates.py
pms5003 = PMS5003()
print('pms loaded.')

# weather.py
bus = SMBus(1)
bme280 = BME280(i2c_dev=bus)
print('bme loaded.')


time.sleep(1.0)


if __name__ == '__main__':

    pms_buffer = CachedWriter('pms.jsonl')
    bme_buffer = CachedWriter('bme.jsonl')

    try:
        while True:
            try:
                pms_reading = pms5003.read()
                pms_data = parse_pms(str(pms_reading))
                pms_data['time'] = datetime.datetime.utcnow().isoformat()
                pms_data['epoch'] = time.time()
                pms_buffer.append(pms_data)
                if pms_buffer.last:
                    pprint(pms_buffer.last)
            except ReadTimeoutError:
                pms5003 = PMS5003()

            try:
                bme_buffer.append(dict(
                    time = datetime.datetime.utcnow().isoformat(),
                    epoch = time.time(),
                    temperature = bme280.get_temperature(),
                    pressure = bme280.get_pressure(),
                    humidity = bme280.get_humidity(),
                ))
                if bme_buffer.last:
                    pprint(bme_buffer.last)
            except ReadTimeoutError:
                pms5003 = PMS5003()

            time.sleep(30)
    except KeyboardInterrupt as e:
        pass
    finally:
        print('exiting...')

