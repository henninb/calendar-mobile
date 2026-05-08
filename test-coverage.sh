#!/bin/sh

flutter test --coverage
lcov --summary coverage/lcov.info

exit 0
