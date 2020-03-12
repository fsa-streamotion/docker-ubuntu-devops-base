#!/usr/bin/env python3

import unittest
import yaml

# I have posted a question here:
# https://stackoverflow.com/a/43602645/3787051
#
# from importlib.util import spec_from_loader, module_from_spec
# from importlib.machinery import SourceFileLoader
# 
# spec = spec_from_loader('oktashell', SourceFileLoader('oktashell', 'add/okta/oktashell'))
# oktashell = module_from_spec(spec)

import os
os.symlink('add/okta/oktashell', 'oktashell.py')

# end hack.

import sys
sys.path.insert(0, '.')
from oktashell import *
os.remove('oktashell.py')

import bs4


class TestWriteConfigFile(unittest.TestCase):

    def setUp(self):
        os.environ['HOME'] = '/tmp'
        os.environ['AWS_PROFILE'] = 'streamotion-platform-nonprod'
        os.environ['FULL_MODE'] = 'true'
        os.mkdir('/tmp/.aws')

        content = "[default]\n"\
                "region = ap-southeast-2\n\n"\
                "[profile {}]\n"\
                "role_arn = {}\n"\
                .format('foo', 'bar')

        with open('/tmp/.aws/config', 'w') as fout:
            fout.write(content)

    def tearDown(self):
        for fil in ['/tmp/.aws/config.bak','/tmp/.aws/config']:
            if os.path.exists(fil):
                os.remove(fil)
        os.rmdir('/tmp/.aws')

    def test_write_config_file_simplest(self):
        myfile = '/tmp/.aws/config'
        write_config_file('baz')
        with open(myfile) as myfile:
            self.assertTrue('baz' in myfile.read())

    def test_full_mode_false(self):
        myfile = '/tmp/.aws/config'
        del os.environ['FULL_MODE']
        write_config_file('baz')
        with open(myfile) as myfile:
            self.assertFalse('baz' in myfile.read())


def main():
    unittest.main()


if __name__ == '__main__':
    main()
