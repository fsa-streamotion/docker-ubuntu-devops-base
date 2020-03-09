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
        os.mkdir('/tmp/.aws')

    def tearDown(self):
        for fil in ['/tmp/.aws/config.bak','/tmp/.aws/config']:
            if os.path.exists(fil):
                os.remove(fil)
        os.rmdir('/tmp/.aws')

    def test_write_config_file_simplest(self):
        myfile = '/tmp/.aws/config'
        write_config_file('foo')
        with open(myfile) as myfile:
            self.assertTrue('foo' in myfile.read())

    def test_write_config_no_use_local(self):
        os.environ['NO_USE_LOCAL'] = 'true'
        write_config_file('foo')
        self.assertFalse(os.path.exists('/tmp/.aws/config'))


def main():
    unittest.main()


if __name__ == '__main__':
    main()
